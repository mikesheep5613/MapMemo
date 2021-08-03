//
//  MapVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import KRProgressHUD


class MapVC: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    var data : [PostModel] = []
    var publicData : [PostModel] = []
    var privateData : [PostModel] = []
    var db : Firestore!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var switchDataSourceControl: UISegmentedControl!
    @IBOutlet var typeFilterBtn: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        mapView.delegate = self
        moveAndZoomMap()
        
        // load data from Firebase
        db = Firestore.firestore()
        
        //Default Setting show data from all of people
        monitorData()
        

    }
    
    
    //MARK: - privateData & publicData Segment
    @IBAction func switchDataSourceControlPressed(_ sender: UISegmentedControl) {
        switch switchDataSourceControl.selectedSegmentIndex {
        case 0: // privateData
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.placePin(self.data)
        case 1: // publicData
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.placePin(self.data)
        default:
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.placePin(self.data)
        }

    }
    
    //MARK: - typeFilter
    @IBAction func typeFilterBarBtnPressed(_ sender: Any) {
        for filterBtn in typeFilterBtn{
            filterBtn.isHidden = !filterBtn.isHidden
        }
    }
    
    func mapViewFilter(_ type : String){
        
        var dataSource : [PostModel]
        if switchDataSourceControl.selectedSegmentIndex == 0 {
            dataSource = self.privateData
        }else{
            dataSource = self.publicData
        }

        for annotation in dataSource {
            if annotation.type != type {
                self.mapView.removeAnnotation(annotation)
            } else {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func typeFilterBtnPressed(_ sender: UIButton) {
        
        for filterBtn in typeFilterBtn{
            filterBtn.isHidden = !filterBtn.isHidden
        }
        switch sender.tag {
        case 0:
            mapViewFilter("mountain")
        case 1:
            mapViewFilter("waterfall")
        case 2:
            mapViewFilter("hotspring")
        case 3:
            mapViewFilter("camping")
        case 4:
            mapViewFilter("snorkeling")
        case 5:
            mapViewFilter("other")
        case 6:
            self.placePin(self.data)

        default:
            break
        }
    }
    

    
    // Retrieve data from Firebase
    func monitorData() {
        
        // Start Loading
        KRProgressHUD.show()
        
        self.db.collection("posts").addSnapshotListener { qSnapshot, error in
            if let e = error {
                print("error snapshot listener \(e)")
                return
            }
            guard let documentsChange = qSnapshot?.documentChanges else {return}
           
            for change in documentsChange {
                
                if change.type == .added{
                    //建立資料
                    let post = PostModel(document: change.document)
                    
                    //Reload image
                    guard let imageURLs = post.imageURL else {return}
                    post.imageArray = []
                    for imageURL in imageURLs {
                        if let loadImageURL = URL(string: imageURL){
                            NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                DispatchQueue.main.async {
                                    guard let image = image else {
                                        assertionFailure("unwrapping image error")
                                        return
                                    }
                                    // 把全部圖片刪掉重新load
                                    post.imageArray?.append(image)
                                    print("Successfully fetch image.")
                                    //如果圖片陣列讀滿到url陣列數量，更新畫面
                                    if post.imageArray?.count == post.imageURL?.count{
                                        // Insert pin based on data from Post Array
                                        self.data.insert(post, at: 0)
                                        //Reload map
                                        self.placePin(self.data)
                                    }

                                }
                            }
                        }
                        
                    }
                    
                }else if change.type == .modified{
                    //透過documentId找到self.data相對應的Note
                    let docID = change.document.data()["postID"] as? String
                    if let post = self.data.filter({ post in post.postID == docID }).first{
                        //更新資料
                        post.authorID = change.document.data()["authorID"] as? String
                        
                        post.title = change.document.data()["title"] as? String
                        post.text = change.document.data()["text"] as? String
                        post.type = change.document.data()["type"] as? String
                        post.imageURL = change.document.data()["imageURL"] as? Array<String>
                        post.latitude = change.document.data()["latitude"] as? Double
                        post.longitude = change.document.data()["longitude"] as? Double
                        post.isPublic = change.document.data()["isPublic"] as? Bool
                        if let tempDate = change.document.data()["date"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                            post.date = dateFormatter.date(from: tempDate)
                        }

                        //Reload image
                        post.imageArray = []
                        guard let imageURLs = post.imageURL else {return}
                        for imageURL in imageURLs {
                            if let loadImageURL = URL(string: imageURL){
                                NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                    DispatchQueue.main.async {
                                        guard let image = image else {
                                            assertionFailure("unwrapping image error")
                                            return
                                        }
                                        // 把全部圖片刪掉重新load
                                        post.imageArray?.append(image)
                                        print("Successfully fetch image.")
                                        //如果圖片陣列讀滿到url陣列數量，更新畫面
                                        if post.imageArray?.count == post.imageURL?.count{
                                            //Reload map
                                            self.mapView.removeAnnotations(self.mapView.annotations)
                                            self.placePin(self.data)
                                        }

                                        
                                    }
                                }
                            }
                            
                        }
                    }
                    
                }else if change.type == .removed {
                    //透過documentId找到self.data相對應的Note
                    let docID = change.document.data()["postID"] as? String
                    if let post = self.data.filter({ post in post.postID == docID }).first{
                        //Reload Table
                        if let index = self.data.firstIndex(of: post){
                            self.data.remove(at: index)
                            
                            //Reload map
                            self.mapView.removeAnnotations(self.mapView.annotations)
                            self.placePin(self.data)                        }
                    }
                }
            }
            // update public & private data array
            self.seperatePrivateAndPublic()

        }
        
        // Loading Finished
        KRProgressHUD.dismiss()

    }
    
    func seperatePrivateAndPublic() {
        var publicArray : [PostModel] = []
        var privateArray : [PostModel] = []
        guard let userID = Auth.auth().currentUser?.uid else {return}

        for post in self.data {
            if post.isPublic == true {
                publicArray.append(post)
            }else if post.authorID == userID && post.isPublic == false {
                privateArray.append(post)
            }
        }
        self.publicData = publicArray
        self.privateData = privateArray
    }
    
    func moveAndZoomMap(){
        // 以台灣中心來準備region
        let coordinate = CLLocationCoordinate2D(latitude: 23.974098094452746 , longitude: 120.9796606886788)
        let span = MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: - Place Pins on MapView
    func placePin(_ data: [PostModel]){
        guard let userID = Auth.auth().currentUser?.uid else {return}
        for post in data{
            if post.isPublic == true{
                if switchDataSourceControl.selectedSegmentIndex == 1 {
                    self.mapView.addAnnotation(post)
                }
            }else if post.authorID == userID && post.isPublic == false {
                if switchDataSourceControl.selectedSegmentIndex == 0 {
                    self.mapView.addAnnotation(post)
                }
            }
        }
        
    }
}

//MARK: - MKMapViewDelegate
extension MapVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? PostModel else {
            return nil
        }
        
        //Handle ImageAnnotations..
        // reuseID cannot be the same
        guard let reuseID = annotation.postID else {return nil}
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) //as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        } else {
            pinView?.annotation = annotation
        }
                
        switch annotation.type {
        case "mountain":
            pinView?.image = UIImage(named: "mpin")
        case "waterfall":
            pinView?.image = UIImage(named: "wpin")
        case "hotspring":
            pinView?.image = UIImage(named: "hpin")
        case "camping":
            pinView?.image = UIImage(named: "cpin")
        case "snorkeling":
            pinView?.image = UIImage(named: "spin")
        default:
            pinView?.image = UIImage(named: "opin")
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? PostModel {
            print("get pin success")
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            performSegue(withIdentifier: "pinTouched", sender: pin)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTouched"{
            if let postVC = segue.destination as? PostVC {
                postVC.currentPost = sender as? PostModel
            }
        }
    }
}

