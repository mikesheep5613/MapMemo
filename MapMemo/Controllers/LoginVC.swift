//
//  LoginVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/8.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func googleLoginBtn(_ sender: Any) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.signIn()

    }
    
    
    @IBAction func facebookLoginBtn(_ sender: Any) {
        
        
        
        let loginManager = LoginManager()
        loginManager.logOut()
        loginManager.logIn(permissions: [.email], viewController: self) { result in
            
            switch result {
                
            case .success(granted: let granted, declined: let declined, token: let token):
                print("login success : \(result)")
            case .cancelled:
                break
            case .failed(_):
                break
            }
            
        }
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
