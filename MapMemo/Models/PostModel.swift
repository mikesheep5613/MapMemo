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


class PostModel  {
    
    var title : String?
    var text : String?
    var type : String?
    var date : Date?
    var image: String?
    var coordinate : CLLocationCoordinate2D?

    
    
    func imageDownloadFromStorage() -> UIImage? {
       
        var imageFromFS : UIImage?

        if let imageURL = self.image {
            let imageRef = Storage.storage().reference(forURL: "gs://mapmemo-17e75.appspot.com/\(imageURL)")
            imageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("getImage error :\(error)")
                }
                guard let data = data else {
                    return
                }
                imageFromFS = UIImage(data: data)
            }
        }
        return imageFromFS
    }

//        // Create local filesystem URL
//        let localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//
//        // Download to the local filesystem
//        let downloadTask = imageRef.write(toFile: localURL) { url, error in
//          if let error = error {
//            // Uh-oh, an error occurred!
//            print("Download image errpr :\(error)")
//          } else {
//            // Local file URL for "images/island.jpg" is returned
//            return  UIImage(contentsOfFile: localURL.pa)
//          }
//        }
//
//        return nil
    

    
}
