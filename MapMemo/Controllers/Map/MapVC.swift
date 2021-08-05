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


class MapVC: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    var data : [PostModel] = []
    var publicData : [PostModel] = []
    var privateData : [PostModel] = []
    var db : Firestore!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var switchDataSourceControl: UISegmentedControl!
    @IBOutlet var typeFilterBtn: [UIButton]!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var typeFilterStackView: UIStackView!
    
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
        self.typeFilterStackView.isHidden = !self.typeFilterStackView.isHidden
                if self.typeFilterStackView.isHidden {
                    self.view.sendSubviewToBack(self.typeFilterStackView)
                }else{

                    self.view.bringSubviewToFront(self.typeFilterStackView)
                }
    }
    
    func mapViewFilter(_ type : String){
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

        var dataSource : [PostModel]
        if switchDataSourceControl.selectedSegmentIndex == 0 {
            dataSource = privateArray
        }else{
            dataSource = publicArray
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
                
        self.db.collection("posts").addSnapshotListener { qSnapshot, error in
            
            // Start Loading
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()

            if let e = error {
                print("error snapshot listener \(e)")
                return
            }
            guard let documentsChange = qSnapshot?.documentChanges else {return}
            print("documentsChange.count:\(documentsChange.count)")
            
            var index = 0
            
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
                                        self.testplacePin(post)
                                        index += 1
                                        print("index:\(index)")

                                        // Loading Finished, fetch all documentschange
                                        if index == documentsChange.count{
                                            self.activityIndicator.stopAnimating()
                                            self.activityIndicator.isHidden = true
                                        }
                                    }

                                }
                            }
                        }
                        
                    }
                    
                }else if change.type == .modified{
                    //透過documentId找到self.data相對應的Note
                    let docID = change.document.data()["postID"] as? String
                    if let updatePost = self.data.filter({ post in post.postID == docID }).first{
                        //更新資料
                        updatePost.authorID = change.document.data()["authorID"] as? String
                        
                        updatePost.title = change.document.data()["title"] as? String
                        updatePost.text = change.document.data()["text"] as? String
                        updatePost.type = change.document.data()["type"] as? String
                        updatePost.imageURL = change.document.data()["imageURL"] as? Array<String>
                        updatePost.latitude = change.document.data()["latitude"] as? Double
                        updatePost.longitude = change.document.data()["longitude"] as? Double
                        updatePost.isPublic = change.document.data()["isPublic"] as? Bool
                        if let tempDate = change.document.data()["date"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                            updatePost.date = dateFormatter.date(from: tempDate)
                        }

                        //Reload image
                        updatePost.imageArray = []
                        guard let imageURLs = updatePost.imageURL else {return}
                        for imageURL in imageURLs {
                            if let loadImageURL = URL(string: imageURL){
                                NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                    DispatchQueue.main.async {
                                        guard let image = image else {
                                            assertionFailure("unwrapping image error")
                                            return
                                        }
                                        // 把全部圖片刪掉重新load
                                        updatePost.imageArray?.append(image)
                                        print("Successfully fetch image.")
                                        //如果圖片陣列讀滿到url陣列數量，更新畫面
                                        if updatePost.imageArray?.count == updatePost.imageURL?.count{
                                            self.mapView.removeAnnotation(updatePost)
                                            self.testplacePin(updatePost)
                                            //Reload map
                                            index += 1
                                            print("index:\(index)")

                                            // Loading Finished, fetch all documentschange
                                            if index == documentsChange.count{
                                                self.activityIndicator.stopAnimating()
                                                self.activityIndicator.isHidden = true
                                            }

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
                            self.mapView.removeAnnotation(post)
                            // Loading Finished
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true

                        }
                    }
                }
            }
        }
        
        
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
    
    func testplacePin(_ post: PostModel){
        guard let userID = Auth.auth().currentUser?.uid else {return}
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

//MARK: - MKMapViewDelegate
extension MapVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? PostModel else {
            return nil
        }
        
        //Handle ImageAnnotations..
        // reuseID cannot be the same
        guard let reuseID = annotation.type else {return nil}
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        
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
        
        if view.annotation is MKUserLocation {
            
        }
        
        self.mapView.deselectAnnotation(view.annotation, animated: true)

        if let pin = view.annotation as? PostModel {
            print("get pin success")
            performSegue(withIdentifier: "pinTouched", sender: pin)
        }
    }
    
//    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
//        if self.mapView.annotations.count == self.data.count{
//            self.activityIndicator.stopAnimating()
//            self.activityIndicator.isHidden = true
//        }
//
//    }
//
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTouched"{
            if let postVC = segue.destination as? PostVC {
                postVC.currentPost = sender as? PostModel
            }
        }
    }
}

