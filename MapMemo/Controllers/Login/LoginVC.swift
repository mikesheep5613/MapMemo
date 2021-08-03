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
    
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var regiterBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextfield.delegate = self
        self.passwordTextfield.delegate = self
        
        self.confirmBtn.layer.cornerRadius = self.confirmBtn.bounds.height / 2
        self.confirmBtn.clipsToBounds = true
        self.regiterBtn.layer.cornerRadius = self.regiterBtn.bounds.height / 2
        self.regiterBtn.clipsToBounds = true


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
        
        // check format
        validationCode()
        
    
        if let email = emailTextfield.text, let password = passwordTextfield.text {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Sign in error : \(error)")
                    self.openAlert(title: "Alert", message: error.localizedDescription , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                        print("Okay clicked!")
                    }])

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
    
    //MARK: - Password forgot
    
 
    @IBAction func forgotPasswordBtnPressed(_ sender: Any) {
        Auth.auth().sendPasswordReset(withEmail: emailTextfield.text!) { error in
            if error == nil {
                self.openAlert(title: "Alert!", message: "Please check your Email to reset password", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{_ in}])
                print("Send reset your password Email.")
                
            } else {
                self.openAlert(title: "Reset Password", message: "Please provide your Email", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{_ in}])
                print("Failed: \(String(describing: error?.localizedDescription))")
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

extension LoginVC {
    fileprivate func validationCode() {
        if let email = emailTextfield.text, let password = passwordTextfield.text{
            if !email.validateEmail(){
                openAlert(title: "Alert", message: "Please check your Email format.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                    print("Okay clicked!")
                }])
            }else if !password.validatePassword(){
                openAlert(title: "Alert", message: "Please enter valid password.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                    print("Okay clicked!")
                }])
            }else{
                
            }

        }else{
            openAlert(title: "Alert", message: "Please input your Email & Password", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{_
                in
                print("OKay clicked")
            }])
        }
        
        
    }
    
    
    
}
