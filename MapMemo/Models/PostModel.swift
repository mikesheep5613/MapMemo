//
//  Post.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import Foundation
import Firebase
import MapKit
import CoreLocation


class PostModel : NSObject, MKAnnotation {
    
    var date : Date?
    var imageURL: String?
    var title : String?
    var text : String?
    var type : String?
    var latitude : Double?
    var longitude : Double?
    var coordinate : CLLocationCoordinate2D
    var noteID : String
    
    override init() {
        self.noteID = UUID().uuidString
        self.coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    

    
//
//    func imageDownloadFromStorage() -> UIImage? {
//
//        var imageFromFS : UIImage?
//
//        if let imageURL = self.image {
//            let imageRef = Storage.storage().reference(forURL: "gs://mapmemo-17e75.appspot.com/\(imageURL)")
//            imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
//                if let error = error {
//                    print("getImage error :\(error)")
//                }
//                guard let data = data else {
//                    return
//                }
//                imageFromFS = UIImage(data: data)
//            }
//        }
//        return imageFromFS
//    }

}
