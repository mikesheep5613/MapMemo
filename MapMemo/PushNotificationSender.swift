//
//  PushNotificationSender.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/8/17.
//

import Foundation

import UIKit

class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String, postID : String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "body" : body],
                                           "data" : ["postID" : postID]
        ]

        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAEsfyDzM:APA91bGfv3nlxapen_9JI5k1iM1HcB4k3EHyNrB_Rea_JcpeTNTaFAfpmnUi0WVGY3EIGm2H814amB3-y5oRLeCmlKHGkuePe1gRgZcAhmCLJH71JekQN4QyfIuAQKrugPCKpJwuYKAl", forHTTPHeaderField: "Authorization")

        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
