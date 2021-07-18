//
//  NetworkController.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/16.
//

import Foundation
import UIKit

class NetworkController {
    
    static let shared = NetworkController()
    
    let imageCache = NSCache<NSURL, UIImage>()
    
    // fetch image to cache
    func fetchImage(url: URL, completionHandler: @escaping (UIImage?) -> ( )) {
        
        if let image = imageCache.object(forKey: url as NSURL){
            completionHandler(image)
            return
        }
        
        
        //URLRequest, URLSession
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response , error in
            if let e = error {
                print("error : \(e)")
                return
            }
            if let data = data, let image = UIImage(data: data){
                self.imageCache.setObject(image, forKey: url as NSURL)
                completionHandler(image)
            } else {
                completionHandler(nil)
            }
        }
        task.resume()
    }
}
