//
//  MapVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import UIKit
import MapKit
import CoreLocation


class MyAnnotation: NSObject, MKAnnotation {
    
    var title: String?
    var text : String?
    var date : String?
    var image : String?
    var latitude : Double?
    var longtitude : Double?
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate : CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}



class MapVC: UIViewController, CLLocationManagerDelegate {
    
    var Posts : [Post] = ItemListHelper().decodeItem()
    var getSelectedPin : MyAnnotation?
    
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
        // Insert pin based on data from Post Array
        self.placePin()
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
    
    
    
    
    func placePin(){
        
        for item in Posts {
            let myAnnotation = MyAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longtitude))
            
            myAnnotation.title = item.title
            myAnnotation.text = item.text
            myAnnotation.date = item.date
            myAnnotation.image = item.image
            
            mapView.addAnnotation(myAnnotation)
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

