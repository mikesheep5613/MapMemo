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
    var userData : [PostModel] = []
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
        monitorAllPostsData()
        
        //Btn outlet
//        self.noneBtn.layer.cornerRadius = 0.5 * self.noneBtn.bounds.size.height
//        self.noneBtn.clipsToBounds = true
    }
    
    
    //MARK: - Myself & All ouf us Segment
    @IBAction func switchDataSourceControlPressed(_ sender: UISegmentedControl) {
        switch switchDataSourceControl.selectedSegmentIndex {
        case 0:
            for annotation in self.data {
                if self.userData.contains(annotation) == false{
                    self.mapView.removeAnnotation(annotation)
                }
            }
        case 1:
            // reset all pins
            self.placePin(self.data)
        default:
            self.placePin(self.data)
        }

    }
    
    //MARK: - typeFilter
    @IBAction func typeFilterBarBtnPressed(_ sender: Any) {
        for filterBtn in typeFilterBtn{
            filterBtn.isHidden = !filterBtn.isHidden
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
            if switchDataSourceControl.selectedSegmentIndex == 0 {
                self.placePin(self.userData)
            }else{
                self.placePin(self.data)
            }

        default:
            break
        }
    }
    
    func mapViewFilter(_ type : String){
        
        let index = switchDataSourceControl.selectedSegmentIndex
        var dataSource : [PostModel]
        if index == 0 {
            dataSource = self.userData
        }else{
            dataSource = self.data
        }

        for annotation in dataSource {
            if annotation.type != type {
                self.mapView.removeAnnotation(annotation)
            } else {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    // Retrieve data from Firebase ( all user or single user)
    func monitorAllPostsData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Invalid userID")
            return
        }
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
                    //Reload Table
                    self.data.insert(post, at: 0)
                    
                    // Insert pin based on data from Post Array
                    //Reload map
                    self.placePin(self.data)

                    //Reload image
                    guard let imageURL = post.imageURL else {return}
                    if let loadImageURL = URL(string: imageURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                post.image = image
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
                        post.imageURL = change.document.data()["imageURL"] as? String
                        post.latitude = change.document.data()["latitude"] as? Double
                        post.longitude = change.document.data()["longitude"] as? Double
                        if let tempDate = change.document.data()["date"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                            post.date = dateFormatter.date(from: tempDate)
                        }

                                                
                        //Reload image
                        guard let imageURL = post.imageURL else {return}
                        if let loadImageURL = URL(string: imageURL){
                            NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                DispatchQueue.main.async {
                                    post.image = image
                                    
                                    //Reload map
                                    self.mapView.removeAnnotations(self.mapView.annotations)
                                    self.placePin(self.data)
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
                            self.placePin(self.data)
                        }

                    }

                }
            }
            
            // update User own data array
            self.monitorUserPostsData()

        }
        
    }
    
    func monitorUserPostsData() {
        // filter data from other users
        self.userData = []
        if let userID = Auth.auth().currentUser?.uid {
            for data in self.data{
                if data.authorID == userID {
                    self.userData.append(data)
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
        self.mapView.addAnnotations(data)
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

