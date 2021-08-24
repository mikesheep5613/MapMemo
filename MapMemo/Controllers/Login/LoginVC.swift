//
//  LoginVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/8.
//

import UIKit
import Firebase
import AppTrackingTransparency
import AuthenticationServices
import CryptoKit
import GoogleSignIn




class LoginVC: UIViewController,UITextFieldDelegate{
    
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var confirmBtn: UIButton!
//    @IBOutlet weak var regiterBtn: UIButton!
    
    @IBOutlet weak var appleSignInBtn: UIButton!
    @IBOutlet weak var googleSignInBtn: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var animateSwitch: UISwitch!
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var textFieldContainerView: UIView!
    
    var loading_1: UIImage!
    var loading_2: UIImage!
    var loading_3: UIImage!
    var images: [UIImage]!
    var animatedImage: UIImage!
    private var currentNonce: String?
    
    
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
//        self.regiterBtn.layer.cornerRadius = self.regiterBtn.bounds.height / 2
//        self.regiterBtn.clipsToBounds = true
        self.appleSignInBtn.layer.cornerRadius = self.appleSignInBtn.bounds.height / 2
        self.appleSignInBtn.clipsToBounds = true
        self.googleSignInBtn.layer.cornerRadius = self.googleSignInBtn.bounds.height / 2
        self.googleSignInBtn.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            self.emailTextfield.widthAnchor.constraint(equalTo: self.textFieldContainerView.widthAnchor , multiplier: 0.9),
            self.emailTextfield.heightAnchor.constraint(equalTo: self.textFieldContainerView.heightAnchor , multiplier: 0.2),

            self.passwordTextfield.widthAnchor.constraint(equalTo: self.textFieldContainerView.widthAnchor , multiplier: 0.9),
            self.passwordTextfield.heightAnchor.constraint(equalTo: self.textFieldContainerView.heightAnchor , multiplier: 0.2),

            self.confirmBtn.widthAnchor.constraint(equalTo: self.textFieldContainerView.widthAnchor , multiplier: 0.9),
            self.confirmBtn.heightAnchor.constraint(equalTo: self.textFieldContainerView.heightAnchor , multiplier: 0.2),

            
            
            self.appleSignInBtn.widthAnchor.constraint(equalTo: self.buttonContainerView.widthAnchor , multiplier: 0.9),
            self.appleSignInBtn.heightAnchor.constraint(equalTo: self.buttonContainerView.heightAnchor , multiplier: 0.4),

            self.googleSignInBtn.widthAnchor.constraint(equalTo: self.buttonContainerView.widthAnchor , multiplier: 0.9),
            self.googleSignInBtn.heightAnchor.constraint(equalTo: self.buttonContainerView.heightAnchor , multiplier: 0.4)
        ])

        // add sepearate line of bottom Stackview
        self.bottomStackView.addSeparators(at: [1], color: .systemBlue)
        self.bottomStackView.addSeparators(at: [3], color: .systemBlue)

        
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
    // nav invisible
    override func viewWillAppear(_ animated: Bool) {
        // Make the navigation bar background clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
      }
      override func viewWillDisappear(_ animated: Bool) {
        // Restore the navigation bar to default
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
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
                    guard let bool = authResult?.additionalUserInfo?.isNewUser else { return }
                    print("is New User: \(bool)")
                    if bool {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let editProfileVC = storyboard.instantiateViewController(identifier: "editProfile") as? EditProfileVC {
                            editProfileVC.isNewUser = true
                            self.present(editProfileVC, animated: true, completion: nil)
                        }

                    }else{
                        // Login Successfully
                        if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                            self.view.window?.rootViewController = tabVC
                        }
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

            // Call the signInAnonymouslyWithCompletion: method
//            Auth.auth().signInAnonymously { authResult, error in
//            }

        }
        askController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        askController.addAction(cancelAction)
        
        self.present(askController, animated: true, completion: nil)
        
    }
    
    //MARK: - Sign in with Google
    @IBAction func signInWithGoogleBtnPressed(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            if let e = error {
                print("Google Sign in error \(e)")
                return
            }
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            // login process with the auth credential
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Sign in error : \(error)")
                    self.openAlert(title: "Alert", message: error.localizedDescription , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                        print("Okay clicked!")
                    }])
                    
                } else {
                    UserDefaults.standard.setValue("google_login", forKey: "username")
                    UserDefaults.standard.synchronize()
                    guard let bool = authResult?.additionalUserInfo?.isNewUser else { return }
                    print("is New User: \(bool)")
                    if bool {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let editProfileVC = storyboard.instantiateViewController(identifier: "editProfile") as? EditProfileVC {
                            editProfileVC.isNewUser = true
                            self.present(editProfileVC, animated: true, completion: nil)
                        }

                    }else{
                        if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                            self.view.window?.rootViewController = tabVC
                        }
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
    
    //MARK: - Sign in with Apple
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    @IBAction func signInWithAppleBtnPressed(_ sender: ASAuthorizationAppleIDButton) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email]
        currentNonce = randomNonceString()
        request.nonce = sha256(currentNonce!)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        
    }
    
    // New user redirect to Profile VC for sign up
    func showProfileVC (bool: Bool, email: String) -> EditProfileVC? {
        
        if bool {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let editProfileVC = storyboard.instantiateViewController(identifier: "editProfile") as? EditProfileVC {
                editProfileVC.userEmail = email
                return editProfileVC
            }
        }
        return nil
    }

}

//MARK: - AppTrackingPermissionError
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

//MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

//MARK: - ASAuthorizationControllerDelegate
extension LoginVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                }
                // User is signed in to Firebase with Apple.
                UserDefaults.standard.setValue("apple_login", forKey: "username")
                UserDefaults.standard.synchronize()
                guard let bool = authResult?.additionalUserInfo?.isNewUser else { return }
                print("is New User: \(bool)")
                if bool {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let editProfileVC = storyboard.instantiateViewController(identifier: "editProfile") as? EditProfileVC {
                        editProfileVC.isNewUser = true
                        self.present(editProfileVC, animated: true, completion: nil)
                    }

                }else{
                    // Login Successfully
                    if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                        self.view.window?.rootViewController = tabVC
                    }
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
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}

