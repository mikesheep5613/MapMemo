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

class PinMapVC: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    var selectedLocation : CLLocationCoordinate2D?
    var isSelected : Bool = false
    weak var delegate : PinMapVCDelegate?
    // class initialized
    let locationManager = CLLocationManager()

    
    @IBOutlet weak var pinMapView: MKMapView!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var checkBtn: UIButton!
    @IBOutlet weak var locateMeBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearBtn.isHidden = true
        checkBtn.isHidden = true
        pinMapView.delegate = self
        self.setMapview()
    }
    
    @IBAction func clearBtnPressed(_ sender: UIButton) {
        self.pinMapView.removeAnnotations(self.pinMapView.annotations)
        self.isSelected = false
        clearBtn.isHidden = true
        checkBtn.isHidden = true

    }
    
    @IBAction func checkBtnPressed(_ sender: UIButton) {
        if let sendLocation = self.selectedLocation{
            self.delegate?.didFinishUpdate(location: sendLocation)
        }
        self.navigationController?.popViewController(animated: true)
        
    }
    
    //set Mapview to detect gesture
    func setMapview(){
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.pinMapView.addGestureRecognizer(lpgr)
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {
            let touchLocation = gestureRecognizer.location(in: pinMapView)
            let locationCoordinate = pinMapView.convert(touchLocation, toCoordinateFrom: pinMapView)
            print("Tapped at lat:\(locationCoordinate.latitude), lon:\(locationCoordinate.longitude)")
            
            if self.isSelected == false {
                addAnnotationOnLocation(location: locationCoordinate)
                self.isSelected = true
                clearBtn.isHidden = false
                checkBtn.isHidden = false

                self.selectedLocation = locationCoordinate
            }
        }
        if gestureRecognizer.state != UIGestureRecognizer.State.began {
            return
        }
    }
    
    
    func addAnnotationOnLocation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        pinMapView.addAnnotation(annotation)
    }

    
    @IBAction func locateMeBtnressed(_ sender: Any) {
        
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
        
        // Pin on self loaction
        if self.isSelected == false {
            addAnnotationOnLocation(location: coordinate)
            self.isSelected = true
            clearBtn.isHidden = false
            checkBtn.isHidden = false
            self.selectedLocation = coordinate
        }

    }
    
    func moveAndZoomMap(){
        guard  let coordinate = locationManager.location?.coordinate else {
            assertionFailure("Invalid coordinate")
            return
        }
        // Prepare span region
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        pinMapView.setRegion(region, animated: true)
        pinMapView.showsUserLocation = true
    }

    
}
