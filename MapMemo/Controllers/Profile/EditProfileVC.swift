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
    var isNewUser : Bool = false
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
        
        // new user sign up
        if self.isNewUser {
            self.userEmail = "new user email"
            self.secondTextField.placeholder = "Your Username is ..."
            self.userImage = UIImage(systemName: "person.crop.circle")
        }
        
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

        
        // If userEmail not nil, become profile editing mode
        if self.userEmail != nil {
            self.isEditMode = true
            self.firstTextField.isSecureTextEntry = false
            self.secondTextField.isSecureTextEntry = false

            
            self.imageViewLabel.text = "Tap photo to Change"
            self.firstTextFieldLabel.isHidden = true
            self.firstTextField.isHidden = true
            self.secondTextField.placeholder = "Your Username is ..."
            self.secondTextFieldLabel.text = "USER NAME"
            self.secondTextField.text = self.userName
            
        }
        
        if self.userImage == nil {
            self.imageView.image = UIImage(systemName: "person.crop.circle")
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
            
            // 如果沒輸入以下欄位會跳alert
            if self.secondTextField.text == "" {
                let alert = UIAlertController(title: "Alert", message: "Please enter your Username.", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if self.imageView.image == UIImage(systemName: "person.crop.circle") {
                let alert = UIAlertController(title: "Alert", message: "Please upload your Profile image.", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
                alert.addAction(cancel)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            // check user name is exist or not
            if let username = self.secondTextField.text{

                checkUsername(username: username) { bool in
                    if bool == true{
                        // 如果Username已重複會return
                        let alert = UIAlertController(title: "Alert", message: "Sorry, the username has already been taken.", preferredStyle: .alert)
                        let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
                        alert.addAction(cancel)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }else{
                        
                        if let image = self.imageView.image {
                                            
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
                                if self.isNewUser{
                                    if let tabVC = self.storyboard?.instantiateViewController(identifier: "tabbarVC"){
                                        self.view.window?.rootViewController = tabVC
                                    }

                                }else{
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                            alert.addAction(cancel)
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                    }
                }
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
    
    
    // check user name duplication
    func checkUsername(username: String, completion: @escaping (Bool) -> Void) {
        
        // Get your Firebase collection
        let collectionRef = self.db.collection("users")

        // Get all the documents where the field username is equal to the String you pass, loop over all the documents.

        collectionRef.whereField("username", isEqualTo: username).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                completion(false)
            } else {
                for document in (snapshot?.documents)! {
                    if document.data()["username"] != nil {
                        completion(true)
                    }
                }
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
