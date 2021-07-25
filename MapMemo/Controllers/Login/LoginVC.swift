//
//  LoginVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/8.
//

import UIKit
import Firebase
//import FirebaseAuth
//import GoogleSignIn
//import FBSDKCoreKit
//import FBSDKLoginKit

class LoginVC: UIViewController,UITextFieldDelegate{

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextfield.delegate = self
        self.passwordTextfield.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - Email signin method
    @IBAction func signinBtnPressed(_ sender: UIButton) {
    
        if let email = emailTextfield.text, let password = passwordTextfield.text {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Sign in error : \(error)")
                } else {
                    UserDefaults.standard.setValue("login", forKey: "username")
                    UserDefaults.standard.synchronize()
                    print(NSHomeDirectory())
                    if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                        self.view.window?.rootViewController = tabVC
                    }
                }
            }
        }
    
    }
    
    
    @IBAction func googleLoginBtn(_ sender: Any) {

    }
    
    
    @IBAction func facebookLoginBtn(_ sender: Any) {
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
