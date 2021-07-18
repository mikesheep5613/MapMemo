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
                
        // load data from Firebase
        db = Firestore.firestore()
        monitorData()

        locationManager.requestAlwaysAuthorization()
        if !CLLocationManager.locationServicesEnabled(){
            print("Location Request Denied")
        }else {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.activityType = .automotiveNavigation
            locationManager.showsBackgroundLocationIndicator = true
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        
        // set Mapview for UI press gesture recognizer
        self.setMapview()
        
    }
    
    
    func setMapview(){
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 1.0
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {
            let touchLocation = gestureRecognizer.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            print("Tapped at lat:\(locationCoordinate.latitude), lon:\(locationCoordinate.longitude)")
        }
        if gestureRecognizer.state != UIGestureRecognizer.State.began {
            return
        }
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
                    
                    let post = PostModel(document: change.document)
                    
                    self.data.insert(post, at: 0)
                    
                    guard let imageURL = post.imageURL else {return}
                    if let loadImageURL = URL(string: imageURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                post.image = image
                            }

                        }
                    }

                }
            }
        }
        
    }

    
    // Retrieve data from Firebase
    func queryFromFireStore() {
        
        if let userID = Auth.auth().currentUser?.email{
            db.collection(userID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let snapshot = querySnapshot else {return}
                for document in snapshot.documents{
                    let post = PostModel()
                    post.title = document.data()["title"] as? String
                    post.text = document.data()["text"] as? String
                    post.type = document.data()["type"] as? String
                    post.date = document.data()["date"] as? String
                    post.imageURL = document.data()["imageURL"] as? String
                    post.latitude = document.data()["latitude"] as? Double
                    post.longitude = document.data()["longitude"] as? Double
                    
                    guard let lat = post.latitude, let lon = post.longitude else {return}
                    post.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    self.data.append(post)
                }
                
                // Insert pin based on data from Post Array
                self.placePin()
            }
        }
        
    }
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            assertionFailure("Fail to get any location")
            return
        }
        let coordinate = lastLocation.coordinate
        print ("Location: \(coordinate.latitude),\(coordinate.longitude)")
        moveAndZoomMap()
    }
    
    func moveAndZoomMap(){
        guard  let coordinate = locationManager.location?.coordinate else {
            assertionFailure("Invalid coordinate")
            return
        }
        // Prepare span region
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
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
        // 如果為自己位置，不顯示圖標
        if annotation is MKUserLocation {
            return nil
        }
        
        //Handle ImageAnnotations..
        let reuseID = "pin"
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        if result == nil {
            result = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        } else {
            result?.annotation = annotation
        }
        return result
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? PostModel {
            print("get pin success")
            performSegue(withIdentifier: "pinTouched", sender: pin)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTouched"{
            if let postVC = segue.destination as? PostVC {
                postVC.currentPost = sender as! PostModel
            }
        }
    }
}

