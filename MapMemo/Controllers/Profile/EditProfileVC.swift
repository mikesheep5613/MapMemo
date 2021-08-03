//
//  EditProfileVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/28.
//

import UIKit
import Firebase

class EditProfileVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewLabel: UILabel!
    @IBOutlet weak var firstTextFieldLabel: UILabel!
    @IBOutlet weak var firstTextField: UITextField!
    @IBOutlet weak var secondTextFieldLabel: UILabel!
    @IBOutlet weak var secondTextField: UITextField!
    @IBOutlet weak var confirmBtn: UIButton!
    
    var isEditMode : Bool = false
    var userEmail : String?
    var userName : String?
    var userImage : UIImage?
    var db : Firestore!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load data from Firebase
        db = Firestore.firestore()
        
        self.firstTextField.delegate = self
        self.secondTextField.delegate = self
        
        self.confirmBtn.layer.cornerRadius = self.confirmBtn.bounds.height / 2
        self.confirmBtn.clipsToBounds = true
        self.imageViewLabel.text = self.userName
        self.imageView.image = self.userImage
        self.imageView.layer.cornerRadius = self.imageView.bounds.height / 2
        self.imageView.clipsToBounds = true
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(switchProfileImageBtn(_:)))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(imageTap)
        self.imageView.layer.cornerRadius = self.imageView.bounds.height / 2
        self.imageView.clipsToBounds = true

        
        // Do any additional setup after loading the view.
        if userEmail != nil {
            self.isEditMode = true
            self.firstTextField.isSecureTextEntry = false
            self.secondTextField.isSecureTextEntry = false

            
            self.imageViewLabel.text = "Tap to Change"
            self.firstTextFieldLabel.text = "USER EMAIL"
            self.firstTextField.text = self.userEmail
            self.secondTextFieldLabel.text = "USER NAME"
            self.secondTextField.text = self.userName
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
    
    
    @IBAction func saveBtnPressed(_ sender: Any) {
        if self.isEditMode == true {
            if let userEmail = self.firstTextField.text, let username = self.secondTextField.text, let image = self.imageView.image {
                
                Auth.auth().currentUser?.updateEmail(to: userEmail, completion: { error in
                    if let e = error {
                        print("Update email error \(e)")
                        return
                    }
                    print("user email change")
                })
                
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
                            print("user name change")
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
                
                let alert = UIAlertController(title: "SUCCESS", message: "Your account has been successfully updated.", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Continue", style: .cancel) { action in
                    self.navigationController?.popViewController(animated: true)
                }
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
            }
        } else{
            // Password validation
            validationCode()
        }
        
        
    }
    
    @objc func switchProfileImageBtn(_ sender: Any) {
        let controller  = UIImagePickerController()
        controller.sourceType = .savedPhotosAlbum
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
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

//MARK: - UITextFieldDelegate
extension EditProfileVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension EditProfileVC : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageView.image = selectedImage
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.clipsToBounds = true
        }
        dismiss(animated: true, completion: nil)
    }
    
    
}


extension EditProfileVC {
    fileprivate func validationCode() {
        
        if let newPassword = self.firstTextField.text, let confirmPassword = self.secondTextField.text{

            // Double check password.
            if newPassword != confirmPassword {
                openAlert(title: "Alert", message: "Please double confirm password.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                    print("Okay clicked!")
                }])
            }
            else if !newPassword.validatePassword(){
                openAlert(title: "Alert", message: "Please enter valid password.", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                    print("Okay clicked!")
                }])
            }else{
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        self.openAlert(title: "Alert", message: error.localizedDescription , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                            print("Okay clicked!")
                        }])
                    } else {
                        self.openAlert(title: "Success", message: "Password has been updated!" , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                            self.navigationController?.popViewController(animated: true)
                            print("Okay clicked!")
                        }])
                    }
                }
            }
        }
    }
    
}
