//
//  RegisterVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/11.
//

import UIKit
import Firebase


class RegisterVC: UIViewController, UITextFieldDelegate{

    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    var db : Firestore!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.usernameField.delegate = self
        self.emailTextfield.delegate = self
        self.passwordTextfield.delegate = self
        self.confirmBtn.layer.cornerRadius = self.confirmBtn.bounds.height / 2
        self.confirmBtn.clipsToBounds = true

        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(switchProfileImageBtn(_:)))
        self.profileImageView.isUserInteractionEnabled = true
        self.profileImageView.addGestureRecognizer(imageTap)
        self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height / 2
        self.profileImageView.clipsToBounds = true
        
        // connect to Firebase
        db = Firestore.firestore()

        
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

    
    @objc func switchProfileImageBtn(_ sender: Any) {
        let controller  = UIImagePickerController()
        controller.sourceType = .savedPhotosAlbum
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
 
    
    
    @IBAction func snedBtnPressed(_ sender: Any) {
        
        // check format
        
        // 如果沒輸入以下欄位會跳alert
        if self.usernameField.text == "" {
            let alert = UIAlertController(title: "Alert", message: "Please enter your Username.", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            return
        }

        
        if let email = self.emailTextfield.text, let password = self.passwordTextfield.text, let username = self.usernameField.text, let image = self.profileImageView.image {
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Resgister error : \(error)")
                    self.openAlert(title: "Alert", message: error.localizedDescription , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                        print("Okay clicked!")
                    }])

                } else {
                   
                    //1. upload profile image to storage
                    
                    self.uploadProfileImage(image: image) { url in
                        
                        guard let url = url else {return}
                        
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = username
                        changeRequest?.photoURL = url
                        
                        changeRequest?.commitChanges(completion: { error in
                            if let e = error {
                                print("error \(e)")
                                return
                            } else {
                                print("user created")
                                //2. save profile data to firebase database
                                self.saveProfile(username: username, profileImageURL: url) { success in
                                    if success {
                                        //3. dismiss the view
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                }
                            }
                        })
                    }
                    
                    let alert = UIAlertController(title: "SUCCESS", message: "Your account has been successfully created.", preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Continue", style: .cancel) { action in
                        NotificationCenter.default.post(name: .passUserEmail , object: nil, userInfo: ["email": self.emailTextfield.text!])
                        self.navigationController?.popViewController(animated: true)
                    }
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    func uploadProfileImage(image: UIImage, completion: @escaping ((URL?) -> Void)) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("user/\(uid)")
        
        guard let uploadImage = image.resize(maxEdge: 1024) else {return}

        guard let imageData = uploadImage.jpegData(compressionQuality: 0.75) else {return}

        let task = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let e = error {
                print("profile image upload error \(e)")
                return
            }
            storageRef.downloadURL { url, error in
                guard let url = url , error == nil else{
                    return
                }
                completion(url)
            }
        }
        task.resume()
    }
    
    func saveProfile(username : String , profileImageURL : URL, completion: @escaping ((_ success: Bool) -> Void)){
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        let ref = self.db.collection("users").document(uid)
        
        let userObject = [
            "username" : username,
            "photoURL" : profileImageURL.absoluteString
        ] as [String : Any]
        
        ref.setData(userObject) { error in
            if let e = error {
                print("error \(e)")
                return
            } else {
                print("Set Data Successfully.")

            }
        }

    }

}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension RegisterVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profileImageView.image = selectedImage
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.clipsToBounds = true
        }
        
//        imageLayout(imageView: photoImageView)
        dismiss(animated: true, completion: nil)
    }

    
}


//定義通知名稱
extension Notification.Name{
    static let passUserEmail = Notification.Name("passUserEmail")
}
