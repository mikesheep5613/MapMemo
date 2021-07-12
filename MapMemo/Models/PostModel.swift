//
//  Post.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import Foundation
import UIKit



class PostModel : Decodable  {
    
    var title : String?
    var text : String?
    var date : String?
    var image : String?
    var latitude : Double?
    var longtitude : Double?
    var type : String?
    
    
    
    
    
    
    
    func imageGet() -> UIImage? {
        
        guard let imagePath = Bundle.main.path(forResource: self.image, ofType: nil ) else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
    
    
    func thumbnailImage() -> UIImage? {
        if let image = self.imageGet() {
        let thumbnailSize = CGSize(width:50, height: 50); //設定縮圖大小
        let scale = UIScreen.main.scale //找出目前螢幕的scale，視網膜技術為2.0 //產生畫布，第一個參數指定大小,第二個參數true:不透明(黑色底),false表示透明背景,scale為螢幕scale
        UIGraphicsBeginImageContextWithOptions(thumbnailSize,false,scale)
        //計算長寬要縮圖比例，取最大值MAX會變成UIViewContentModeScaleAspectFill //最小值MIN會變成UIViewContentModeScaleAspectFit
        let widthRatio = thumbnailSize.width / image.size.width;
        let heightRadio = thumbnailSize.height / image.size.height;
        let ratio = max(widthRatio,heightRadio);
        let imageSize = CGSize(width:image.size.width*ratio,height: image.size.height*ratio);
            
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        circlePath.addClip();
            
        image.draw(in:CGRect(x: -(imageSize.width-thumbnailSize.width)/2.0,y: -(imageSize.height-thumbnailSize.height)/2.0,
        width: imageSize.width,height: imageSize.height)) //取得畫布上的縮圖
        let smallImage = UIGraphicsGetImageFromCurrentImageContext(); //關掉畫布
        UIGraphicsEndImageContext();
            return smallImage
        }else{
            return nil;
        }
    }

    
}
