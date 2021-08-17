//
//  LoginVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/8.
//

import UIKit
import Firebase
import AppTrackingTransparency




class LoginVC: UIViewController,UITextFieldDelegate{

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var regiterBtn: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var animateSwitch: UISwitch!
    
    var loading_1: UIImage!
    var loading_2: UIImage!
    var loading_3: UIImage!
    var images: [UIImage]!
    var animatedImage: UIImage!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = AppTrackingPermission().requestAppTrackingPermission{ success, error in
          if success == true {
            print("User permit to track the user")
          } else {
            print("AppTrackingPermission:: ", error.debugDescription)
          }
        }

        self.emailTextfield.delegate = self
        self.passwordTextfield.delegate = self
        
        self.confirmBtn.layer.cornerRadius = self.confirmBtn.bounds.height / 2
        self.confirmBtn.clipsToBounds = true
        self.regiterBtn.layer.cornerRadius = self.regiterBtn.bounds.height / 2
        self.regiterBtn.clipsToBounds = true

        loading_1 = UIImage(named: "S1")
        loading_2 = UIImage(named: "S2")
        loading_3 = UIImage(named: "S3")
        images = [loading_1, loading_2, loading_3]
        animatedImage = UIImage.animatedImage(with: images, duration: 0.8)


        //Autofill registered email
        NotificationCenter.default.addObserver(self, selector: #selector(finishRegister(notification:)), name: .passUserEmail, object: nil)


    }
    
    @objc func finishRegister(notification: Notification) {
        if let email = notification.userInfo?["email"] as? String {
            self.emailTextfield.text = email
        }
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
    
    //MARK: - Login Animation
    @IBAction func animateSwitch(_ sender: Any) {
        if self.animateSwitch.isOn {
            self.backgroundImageView.image = self.animatedImage
        }else {
            self.backgroundImageView.image = self.loading_3
        }
    }
    
    
    
    //MARK: - Email signin method
    @IBAction func signinBtnPressed(_ sender: UIButton) {
        
        // check format        
    
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
                    
                    // Update fcmToken
                    Messaging.messaging().token { token, error in
                      if let error = error {
                        print("Error fetching FCM registration token: \(error)")
                      } else if let token = token {
                        print("FCM registration token: \(token)")
                        
                        if let userID = Auth.auth().currentUser?.uid {
                                    let usersRef = Firestore.firestore().collection("users_table").document(userID)
                                    usersRef.setData(["fcmToken": token], merge: true)
                        }

                      }
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
    
    
    @IBAction func guestLoginBtnPressed(_ sender: Any) {
        
        let askController = UIAlertController(title: "Sign In As Guest?", message: "Guest should not be able to use entire function and access profile information of other users." , preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Sign In", style: .default) { (action) -> Void in
            UserDefaults.standard.setValue("guest", forKey: "username")
            UserDefaults.standard.synchronize()
            if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                self.view.window?.rootViewController = tabVC
            }
        }
        askController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        askController.addAction(cancelAction)
        
        self.present(askController, animated: true, completion: nil)

    }
    
}


//extension LoginVC {
//    fileprivate func validationCode() {
//        if let email = emailTextfield.text, let password = passwordTextfield.text{
//            if !email.validateEmail(){
//                openAlert(title: "Alert", message: "Please check your Email format.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
//                    print("Okay clicked!")
//                }])
//            }else if !password.validatePassword(){
//                openAlert(title: "Alert", message: "Please enter valid password.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
//                    print("Okay clicked!")
//                }])
//            }else{
//
//            }
//
//        }else{
//            openAlert(title: "Alert", message: "Please input your Email & Password", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{_
//                in
//                print("OKay clicked")
//            }])
//        }
//
//
//    }
//
//
//
//}

enum AppTrackingPermissionError: Error {
  case denied
  case notDetermined
  case restricted
}

class AppTrackingPermission {
  
  func requestAppTrackingPermission(completion: @escaping (Bool, AppTrackingPermissionError?) -> ()) {
    ATTrackingManager.requestTrackingAuthorization { trackingAuthorizationStatus in
      switch trackingAuthorizationStatus {
        case .authorized:
          print(trackingAuthorizationStatus)
          completion(true, nil)
        case .denied:
          print(trackingAuthorizationStatus)
          completion(false, .denied)
        case .notDetermined:
          print(trackingAuthorizationStatus)
          completion(false, .notDetermined)
        case .restricted:
          print(trackingAuthorizationStatus)
          completion(false, .restricted)
        @unknown default:
          break
      }
    }
  }
}
