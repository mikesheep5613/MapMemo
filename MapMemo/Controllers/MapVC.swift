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
        
        queryFromFireStore()
        
        // Insert pin based on data from Post Array
        self.placePin()
        
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
    func queryFromFireStore() {
        let setting = FirestoreSettings()
        Firestore.firestore().settings = setting
        db = Firestore.firestore()
        
        if let userID = Auth.auth().currentUser?.uid{
            db.collection(userID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let snapshot = querySnapshot else {return}
                for document in snapshot.documents{
                    let post = PostModel()
                    post.title = document.data()["title"] as? String
                    post.text = document.data()["text"] as? String
                    post.date = document.data()["date"] as? Date
                    post.image = document.data()["image"] as? String
                    post.type = document.data()["type"] as? String
                    
                    if let geopoint = document.data()["coords"] as? GeoPoint {
                        post.coordinate?.latitude = geopoint.latitude
                        post.coordinate?.longitude = geopoint.longitude
                    }
                    
                    self.data.append(post)
                }
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
            print(item.coordinate)
            mapView.addAnnotation(item as! MKAnnotation)
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
        if let pin = view.annotation as? MyAnnotation {
            print("get pin success")
            performSegue(withIdentifier: "pinTouched", sender: pin)
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinTouched"{
            if let postVC = segue.destination as? PostVC {
                postVC.currentAnnotation = sender as? MyAnnotation
            }
        }
    }
}

