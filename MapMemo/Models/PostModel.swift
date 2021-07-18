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
    
    var date : String?
    var imageURL: String?
    var title : String?
    var text : String?
    var type : String?
    var latitude : Double?
    var longitude : Double?
    var coordinate : CLLocationCoordinate2D
    var postID : String?
    var image : UIImage?
    
    override init() {
        self.postID = UUID().uuidString
        self.coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    init(document: QueryDocumentSnapshot) {
        self.postID = document.data()["postID"] as? String
        self.title = document.data()["title"] as? String
        self.text = document.data()["text"] as? String
        self.type = document.data()["type"] as? String
        self.date = document.data()["date"] as? String
        self.imageURL = document.data()["imageURL"] as? String
        self.latitude = document.data()["latitude"] as? Double
        self.longitude = document.data()["longitude"] as? Double
        
        self.coordinate = CLLocationCoordinate2D(latitude: document.data()["latitude"] as? Double ?? 0.0, longitude: document.data()["longitude"] as? Double ?? 0.0)
//        self.coordinate = CLLocationCoordinate2D(latitude: self.latitude ?? 0.0, longitude: self.longitude ?? 0.0)

    }
    
    
    func thumbnailImage()->UIImage?{
        
        if let image =  self.image {
            
            let thumbnailSize = CGSize(width: 50,height: 50); //設定縮圖大小
            let scale = UIScreen.main.scale //找出目前螢幕的scale，視網膜技術為2.0
            //產生畫布，第一個參數指定大小,第二個參數true:不透明（黑色底）,false表示透明背景,scale為螢幕scale
            UIGraphicsBeginImageContextWithOptions(thumbnailSize,false,scale)
            
            //計算長寬要縮圖比例，取最大值MAX會變成UIViewContentModeScaleAspectFill
            //最小值MIN會變成UIViewContentModeScaleAspectFit
            let widthRatio = thumbnailSize.width / image.size.width;
            let heightRadio = thumbnailSize.height / image.size.height;
            
            let ratio = max(widthRatio,heightRadio);
            
            let imageSize = CGSize(width: image.size.width*ratio, height: image.size.height*ratio);
            
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0,y: 0,width: thumbnailSize.width,height: thumbnailSize.height))
            circlePath.addClip()
            
            image.draw(in: CGRect(x: -(imageSize.width-thumbnailSize.width)/2.0, y: -(imageSize.height-thumbnailSize.height)/2.0,
                                  width: imageSize.width, height: imageSize.height))
            //取得畫布上的縮圖
            let smallImage = UIGraphicsGetImageFromCurrentImageContext();
            //關掉畫布
            UIGraphicsEndImageContext();
            return smallImage
        }else{
            return nil;
        }
    }
}