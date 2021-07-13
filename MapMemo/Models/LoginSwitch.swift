//
//  LoginSwitch.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/11.
//

import Foundation
import UIKit

func checkLogin (window : UIWindow ) {
    
    if UserDefaults.standard.object(forKey: "username") == nil {
        //切換rootViewController到login Controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "loginVC")
        window.rootViewController = loginVC
    }

}
