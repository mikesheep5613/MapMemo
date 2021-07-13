//
//  MyAnnotation.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/11.
//

import Foundation
import CoreLocation
import MapKit

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
