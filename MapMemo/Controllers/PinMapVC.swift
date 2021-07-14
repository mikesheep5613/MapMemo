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

class PinMapVC: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {

    var selectedLocation : CLLocationCoordinate2D?
    var isSelected : Bool = false
    weak var delegate : PinMapVCDelegate?
    
    @IBOutlet weak var pinMapView: MKMapView!
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var checkBtn: UIButton!
    
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



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
