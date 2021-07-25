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
    
    var db : Firestore!
    
    @IBOutlet weak var mapView: MKMapView!
    
    // class initialized
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                

//        locationManager.requestAlwaysAuthorization()
//        if !CLLocationManager.locationServicesEnabled(){
//            print("Location Request Denied")
//        }else {
//            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.activityType = .automotiveNavigation
//            locationManager.showsBackgroundLocationIndicator = true
//            locationManager.delegate = self
//            locationManager.startUpdatingLocation()
//        }
        mapView.delegate = self
        moveAndZoomMap()
        // load data from Firebase
        db = Firestore.firestore()
        monitorData()
//        queryFromFireStore()
    }
        
    // Retrieve data from Firebase
    func monitorData() {
        guard let userID = Auth.auth().currentUser?.email else {
            assertionFailure("Invalid userID")
            return
        }
        self.db.collection(userID).addSnapshotListener { qSnapshot, error in
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
                    self.placePin()

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
                                    self.placePin()
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
                            self.placePin()
                        }

                    }

                }
            }
        }
        
    }

    
    //MARK: - CLLocationManagerDelegate
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let lastLocation = locations.last else {
//            assertionFailure("Fail to get any location")
//            return
//        }
//        let coordinate = lastLocation.coordinate
//        print ("Location: \(coordinate.latitude),\(coordinate.longitude)")
//        moveAndZoomMap()
//    }
    
    func moveAndZoomMap(){
//        guard  let coordinate = locationManager.location?.coordinate else {
//            assertionFailure("Invalid coordinate")
//            return
//        }
        // Prepare span region
        // 以台灣中心來準備region
        let coordinate = CLLocationCoordinate2D(latitude: 23.974098094452746 , longitude: 120.9796606886788)
        let span = MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: - Place Pins on MapView
    func placePin(){
        for item in self.data {
            mapView.addAnnotation(item)
        }
    }
}

//MARK: - MKMapViewDelegate
extension MapVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? PostModel else {
            return nil
        }
        
        // 如果為自己位置，不顯示圖標
//        if annotation is MKUserLocation {
//            return nil
//        }
        
        //Handle ImageAnnotations..
        let reuseID = "Pin"
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

