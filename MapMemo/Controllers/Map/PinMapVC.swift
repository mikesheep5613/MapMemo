//
//  PinMapVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/13.
//

import UIKit
import MapKit
import CoreLocation

protocol PinMapVCDelegate : AnyObject {
    func didFinishUpdate(location: CLLocationCoordinate2D)
}

class PinMapVC: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    var selectedLocation : CLLocationCoordinate2D?
    var isSelected : Bool = false
    weak var delegate : PinMapVCDelegate?
    let locationManager = CLLocationManager()
    
    
    @IBOutlet weak var pinMapView: MKMapView!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var checkBtn: UIButton!
    @IBOutlet weak var locateMeBtn: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var btnStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.sendSubviewToBack(btnStackView)
        
        pinMapView.delegate = self
        self.setMapview()
        self.searchBar.delegate = self
        
    }
    
    @IBAction func locateMeBtnressed(_ sender: Any) {
        locationManager.requestAlwaysAuthorization()
        if !CLLocationManager.locationServicesEnabled(){ // Location Services is ON
        
            //Redirect to Privacy Setting
            let askController = UIAlertController(title: "Location Request Denied", message: "Redirect to Privacy Setting?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
                if let url = URL(string: "App-Prefs:Privacy&path=LOCATION"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            askController.addAction(okAction)
            let laterAction = UIAlertAction(title: "Later", style: .default, handler: nil)
            askController.addAction(laterAction)
            self.present(askController, animated: true, completion: nil)

            
        }else if locationManager.authorizationStatus == .denied{ // Location Services of App is Never
            //Redirect to Privacy Setting
            let askController = UIAlertController(title: "Location Request Denied", message: "Redirect to Privacy Setting?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Yes", style: .default) { (action) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {return}
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
            askController.addAction(okAction)
            let laterAction = UIAlertAction(title: "Later", style: .default, handler: nil)
            askController.addAction(laterAction)
            self.present(askController, animated: true, completion: nil)

        }else {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.activityType = .automotiveNavigation
            locationManager.showsBackgroundLocationIndicator = true
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }
    
    //    if #available(iOS 10.0, *) { if let url = URL(string: "App-Prefs:Privacy&path=LOCATION") { UIApplication.shared.open(url, options: [:], completionHandler: nil) } } else { if let url = URL(string: "prefs:root=LOCATION_SERVICE") { // If general location settings are disabled then open general location settings UIApplication.shared.openURL(url) } }
    //    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
    //                        return
    //                    }
    
    
    @IBAction func clearBtnPressed(_ sender: UIButton) {
        self.pinMapView.removeAnnotations(self.pinMapView.annotations)
        self.isSelected = false
        self.view.sendSubviewToBack(btnStackView)
    }
    
    @IBAction func checkBtnPressed(_ sender: UIButton) {
        self.isSelected = true
        if let sendLocation = self.selectedLocation{
            self.delegate?.didFinishUpdate(location: sendLocation)
        }
        self.navigationController?.popViewController(animated: true)
        
    }
    
    //MARK: - UIGestureRecognizerDelegate
    func setMapview(){
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.pinMapView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {
            self.pinMapView.removeAnnotations(self.pinMapView.annotations)
            
            let touchLocation = gestureRecognizer.location(in: pinMapView)
            let locationCoordinate = pinMapView.convert(touchLocation, toCoordinateFrom: pinMapView)
            print("Tapped at lat:\(locationCoordinate.latitude), lon:\(locationCoordinate.longitude)")
            
            //            if self.isSelected == false {
            addAnnotationOnLocation(location: locationCoordinate)
            //                clearBtn.isHidden = false
            //                checkBtn.isHidden = false
            self.view.bringSubviewToFront(btnStackView)
            
            self.selectedLocation = locationCoordinate
            //            }
        }
        if gestureRecognizer.state != UIGestureRecognizer.State.began {
            return
        }
    }
    
    //MARK: - MKMapViewDelegate
    func addAnnotationOnLocation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        pinMapView.addAnnotation(annotation)
    }
    
    // Select to move and zoon to certain location
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let coordinate = view.annotation?.coordinate {
            moveAndZoomMap(coordinate)
            
            self.view.bringSubviewToFront(btnStackView)
            self.selectedLocation = coordinate
            
            //             Pin on self loaction
            //            if self.isSelected == false {
            //                self.isSelected = true
            //                clearBtn.isHidden = false
            //                checkBtn.isHidden = false
            //                self.selectedLocation = coordinate
            //            }
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
        moveAndZoomMap(coordinate)
        locationManager.stopUpdatingLocation()
        
        // Pin on self loaction
        if self.isSelected == false {
            addAnnotationOnLocation(location: coordinate)
            self.isSelected = true
            clearBtn.isHidden = false
            checkBtn.isHidden = false
            self.selectedLocation = coordinate
        }
        
    }
    
    func moveAndZoomMap(_ coordinate: CLLocationCoordinate2D){
        // Prepare span region
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        pinMapView.setRegion(region, animated: true)
        pinMapView.showsUserLocation = true
    }
    
    //MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.pinMapView.removeAnnotations(self.pinMapView.annotations)
        self.view.sendSubviewToBack(btnStackView)
        
        generateMKLocalSearch()
        searchBar.resignFirstResponder()
        
    }
    
    func generateMKLocalSearch() {
        
        //        if self.searchController.isActive, let searchText = self.searchController.searchBar.text {
        if let searchText = self.searchBar.text {
            let request = MKLocalSearch.Request()
            
            request.naturalLanguageQuery = searchText
            
            request.region = self.pinMapView.region
            
            let search = MKLocalSearch(request: request)
            
            search.start { response, error in
                guard let response = response else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error").")
                    return
                }
                for item in response.mapItems {
                    
                    // insert search point
                    let annotaiton = MKPointAnnotation()
                    annotaiton.coordinate = item.placemark.coordinate
                    annotaiton.title = item.placemark.name
                    self.pinMapView.addAnnotation(annotaiton)
                }
            }
        }
    }
    
    
}



