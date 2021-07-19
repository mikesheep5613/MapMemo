//
//  AboutVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/10.
//

import UIKit
import Firebase

class ProfileVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func signoutBtnPressed(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.synchronize()
            if let window = self.view.window {
                checkLogin(window : window)
            }
        } catch let signOutError as NSError {
            print("Signing out error : \(signOutError)")
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
