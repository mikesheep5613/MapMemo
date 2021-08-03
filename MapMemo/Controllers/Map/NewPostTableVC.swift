//
//  NewPostTableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/12.
//

import UIKit
import MapKit
import Firebase
import PhotosUI

class NewPostTableVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PinMapVCDelegate, PHPickerViewControllerDelegate {
    
    
    @IBOutlet var photoImageCollection: [UIImageView]!
    @IBOutlet weak var photoImageView: UIImageView!
    
    
    @IBOutlet weak var titleTextField: RoundedTextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeSegmentControl: UISegmentedControl!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var uploadBtn: UIBarButtonItem!
    @IBOutlet weak var trashBtn: UIBarButtonItem!
    @IBOutlet weak var isPublicLabel: UILabel!
    @IBOutlet weak var isPublicSwitch: UISwitch!
    
    var newLocation : CLLocationCoordinate2D?
    var newType : String?
    var newImageURL : String?
    var uuid : String?
    
    var activityIndicator = UIActivityIndicatorView()
    var uploadBarButton = UIBarButtonItem()
    var activityBarButton = UIBarButtonItem()
    
    
    // Create property for retrieve data from PostVC
    var editPost : PostModel?
    
    var isEditMode : Bool = false
    var db : Firestore!
    private let storage = Storage.storage().reference()
    
    
    // Upload Imaged dataset
    var images : [Data] = []
    var imagesURL : [String] = []
    /// Here is the completion block
    typealias FileCompletionBlock = () -> Void
    var block: FileCompletionBlock?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.titleTextField.delegate = self
        createToolbar(textField: self.textView)
        
        self.textView.delegate = self
        self.textView.layer.cornerRadius = 5.0
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.textView.layer.borderWidth = 1
        // 設置UISwitch功能
        self.isPublicSwitch.addTarget(self, action: #selector(isPublicSwitchPressed(_:)), for: .valueChanged)
        
        
        
        //        let image = UIImage(systemName: "photo")
        //        self.photoImageView.image = image
        
        
        // check whether editPost receieve model
        if editPost != nil {
            self.isEditMode = true
            
            // Present to UI
            self.photoImageCollection.first?.image = editPost?.imageArray?.first
            self.photoImageCollection[1].image = editPost?.imageArray?[1]
            self.photoImageCollection[2].image = editPost?.imageArray?[2]
            
            
            //            self.photoImageView.contentMode = .scaleAspectFill
            //            imageLayout(imageView: photoImageView)
            self.titleTextField.text = editPost?.title
            self.datePicker.date = editPost?.date ?? Date.init()
            self.typeSegmentControl.selectedSegmentIndex = typeSegmentIndexCheck(editPost?.type ?? "other")
            self.newType = editPost?.type
            self.textView.text = editPost?.text
            self.newLocation = editPost?.coordinate
            self.isPublicSwitch.isOn = editPost?.isPublic ?? false
            self.isPublicLabel.text = self.isPublicSwitch.isOn ? "Public" : "Only Me"
            
            guard let location = editPost?.coordinate else {
                assertionFailure("Fail to unwrap edit post coordinate")
                return
            }
            convertToPlaceMark(location) { (address) in
                if let address = address {
                    self.locationLabel.text = address
                }
            }
        }
        
        // connect to Firebase
        db = Firestore.firestore()
        
        
        // add right barbutton item
        activityIndicator.sizeToFit()
        activityIndicator.color = .gray
        activityBarButton = UIBarButtonItem(customView: activityIndicator)
        uploadBarButton = UIBarButtonItem(image: UIImage(named: "ok"), style: .plain, target: self, action: #selector(uploadPost(_:)))
        showUploadBarButton()
        
        
    }
    
    @IBAction func addPhotoBtn(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 3
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
        
        
    }
    @IBAction func uploadPost(_ sender: UIBarButtonItem) {
        
        showActivityIndicator()
        activityIndicator.startAnimating()
        
        //Upload image data to firebase storage
        // check Post need to be Added or Edited
        if self.isEditMode == true {
            self.uuid = editPost?.postID
        } else {
            self.uuid = UUID().uuidString
        }
        
        //        if self.photoImageView.image == UIImage(systemName: "photo") || self.titleTextField.text == "" || self.textView.text == "" || self.newLocation == nil || self.newType == "" {
        if self.titleTextField.text == "" || self.textView.text == "" || self.newLocation == nil || self.newType == "" {
            

            self.activityIndicator.stopAnimating()
            self.showUploadBarButton()
            let alert = UIAlertController(title: "貼文上傳失敗!", message: "確認所有欄位是否都有正確填入", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "繼續", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //        guard let uploadImage = self.photoImageView.image?.resize(maxEdge: 1024) else {return}
        //        guard let realUploadImage = uploadImage.jpegData(compressionQuality: 0.7) else {return}
        guard let uuid = self.uuid else {return}
        
        guard let firstImage = self.photoImageCollection.first?.image?.resize(maxEdge: 1024) else {return}
        guard let firstUploadImage = firstImage.jpegData(compressionQuality: 0.7) else {return}
        guard let secondImage = self.photoImageCollection[1].image?.resize(maxEdge: 1024) else {return}
        guard let secondUploadImage = secondImage.jpegData(compressionQuality: 0.7) else {return}
        guard let thirdImage = self.photoImageCollection[2].image?.resize(maxEdge: 1024) else {return}
        guard let thirdUploadImage = thirdImage.jpegData(compressionQuality: 0.7) else {return}
        
        self.images = [firstUploadImage, secondUploadImage, thirdUploadImage]
        
        startUploading {
            // All images have been uploaded
            if let userID = Auth.auth().currentUser?.uid,
               let title = self.titleTextField.text,
               let text = self.textView.text,
               let location = self.newLocation,
               let type = self.newType
            {
                
                //                    let documentID = "\(Date().timeIntervalSince1970)"
                let isPublic = self.isPublicSwitch.isOn
                let date = self.datePicker.date.description
                let imageURL = self.imagesURL
                let ref = self.db.collection("posts").document(uuid)
                let data = [
                    "authorID" : userID,
                    "postID" : uuid,
                    "title": title,
                    "text": text,
                    "date": date,
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "type": type,
                    "imageURL" : imageURL,
                    "isPublic" : isPublic
                ] as [String : Any]
                
                ref.setData(data) { error in
                    if let e = error {
                        print ("Fail to setData: \(e).")
                    } else {
                        print("Set Data Successfully.")
                        
                        
                        // if is edit mode pop to TableVC
                        if self.isEditMode == true {
                            self.navigationController?.popToRootViewController(animated: true)
                            
                        } else {
                            // if not, pop to MapVC
                            self.navigationController?.popViewController(animated: true)
                            
                        }
                        
                    }
                }
            }
        }
        
        /*storage.child("images/\(uuid).jpeg").putData(realUploadImage, metadata: nil) { _, error
         in
         if let error = error {
         assertionFailure("Fail to upload image: \(error)")
         return
         }
         self.storage.child("images/\(uuid).jpeg").downloadURL { url, error in
         guard let url = url , error == nil else{
         return
         }
         self.newImageURL = url.absoluteString // Save to global property
         
         //Upload Dict to firebase
         if let userID = Auth.auth().currentUser?.uid,
         let title = self.titleTextField.text,
         let text = self.textView.text,
         let location = self.newLocation,
         let type = self.newType,
         let imageURL = self.newImageURL {
         
         //                    let documentID = "\(Date().timeIntervalSince1970)"
         let date = self.datePicker.date.description
         
         let ref = self.db.collection("posts").document(uuid)
         let data = [
         "authorID" : userID,
         "postID" : uuid,
         "title": title,
         "text": text,
         "date": date,
         "latitude": location.latitude,
         "longitude": location.longitude,
         "type": type,
         "imageURL" : imageURL
         ] as [String : Any]
         
         ref.setData(data) { error in
         if let e = error {
         print ("Fail to setData: \(e).")
         } else {
         print("Set Data Successfully.")
         
         
         // if is edit mode pop to TableVC
         if self.isEditMode == true {
         self.navigationController?.popToRootViewController(animated: true)
         
         } else {
         // if not, pop to MapVC
         self.navigationController?.popViewController(animated: true)
         
         }
         
         }
         }
         }
         }
         }*/
    }
    
    
    @IBAction func trashBtnPressed(_ sender: UIBarButtonItem) {
        
        if self.isEditMode == true {
            self.uuid = editPost?.postID
            
            let alert = UIAlertController(title: "是否刪除本篇心得??", message: "按下確認刪除資料", preferredStyle: .alert)
            let pop = UIAlertAction(title: "確認", style: .default ){ (action) in
                // Delete post from Firebase
                if let userID = Auth.auth().currentUser?.email, let uuid = self.uuid {
                    self.db.collection("posts").document(uuid).delete()
                }
                self.navigationController?.popToRootViewController(animated: true)
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(pop)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "是否放棄本次編輯??", message: "按下確認返回前一頁面", preferredStyle: .alert)
            let pop = UIAlertAction(title: "確認", style: .default ){ (action) in
                self.navigationController?.popViewController(animated: true)
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(pop)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    func showUploadBarButton() {
        self.navigationItem.setRightBarButton(self.uploadBarButton, animated: true)
    }
    
    func showActivityIndicator() {
        self.navigationItem.setRightBarButton(self.activityBarButton, animated: true)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if self.textView.text == "Write Something You Want To Record..." {
            self.textView.text = nil
            self.textView.textColor = UIColor.black
        }
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.textView.text.isEmpty {
            self.textView.text = ""
        }
    }
    
    // create toolbar for resign keyboard
    func createToolbar(textField : UITextView) {
        let toolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let hidekeyboard = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(hidekeyboardd))
        
        toolbar.items = [flexSpace,hidekeyboard]
        self.textView.inputAccessoryView = toolbar
    }
    
    @objc func hidekeyboardd() {
        self.textView.resignFirstResponder()
    }
    
    
    //MARK: - Input Type
    @IBAction func typeSegmentControlPressed(_ sender: UISegmentedControl) {
        
        switch typeSegmentControl.selectedSegmentIndex {
        case 0:
            self.newType = "mountain"
        case 1:
            self.newType = "waterfall"
        case 2:
            self.newType = "hotspring"
        case 3:
            self.newType = "camping"
        case 4:
            self.newType = "snorkeling"
        case 5:
            self.newType = "other"
        default:
            self.newType = "mountain"
        }
    }
    
    func typeSegmentIndexCheck(_ type: String) -> Int {
        var int : Int = 0
        if type == "mountain" {
            int = 0
        } else if type == "waterfall"{
            int = 1
        } else if type == "hotspring"{
            int = 2
        } else if type == "camping"{
            int = 3
        } else if type == "snorkeling"{
            int = 4
        } else{
            int = 5
        }
        return int
    }
    
    //MARK: - isPublic UISwitch
    @objc
    func isPublicSwitchPressed(_ sender : AnyObject){
        let tempSwitch = sender as! UISwitch
        
        if tempSwitch.isOn{
            self.isPublicLabel.text = "Public"
            print("switch is on")
        } else {
            self.isPublicLabel.text = "Only Me"
            print("switch is off")
            
            
        }
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 7
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            
            let photoSourceRequestController = UIAlertController(title: "", message: "Choose your photo source", preferredStyle: .actionSheet)
            
            
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .camera
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
            
            let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (action) in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                    let imagePicker = UIImagePickerController()
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .photoLibrary
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
            photoSourceRequestController.addAction(cameraAction)
            photoSourceRequestController.addAction(photoLibraryAction)
            
            //for iPad
            if let popoverController = photoSourceRequestController.popoverPresentationController {
                if let cell = tableView.cellForRow(at: indexPath){
                    popoverController.sourceView = cell
                    popoverController.sourceRect = cell.bounds
                }
            }
            present(photoSourceRequestController, animated: true, completion: nil)
            
        }
        
    }
    
    //MARK: - UIImagePickerControllerDelegate
    //    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    //        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
    //            self.photoImageView.image = selectedImage
    //            self.photoImageView.contentMode = .scaleAspectFill
    //            self.photoImageView.clipsToBounds = true
    //        }
    //
    //        imageLayout(imageView: photoImageView)
    //        dismiss(animated: true, completion: nil)
    //    }
    //
    //    func imageLayout(imageView: UIImageView) {
    //        let leading = NSLayoutConstraint(item: photoImageView as Any, attribute: .leading, relatedBy: .equal, toItem: photoImageView.superview, attribute: .leading, multiplier: 1, constant: 0)
    //        leading.isActive = true
    //
    //        let trailing = NSLayoutConstraint(item: photoImageView as Any, attribute: .trailing, relatedBy: .equal, toItem: photoImageView.superview, attribute: .trailing, multiplier: 1, constant: 0)
    //        trailing.isActive = true
    //
    //        let top = NSLayoutConstraint(item: photoImageView as Any, attribute: .top, relatedBy: .equal, toItem: photoImageView.superview, attribute: .top, multiplier: 1, constant: 0)
    //        top.isActive = true
    //
    //        let bottom = NSLayoutConstraint(item: photoImageView as Any, attribute: .bottom, relatedBy: .equal, toItem: photoImageView.superview, attribute: .bottom, multiplier: 1, constant: 0)
    //        bottom.isActive = true
    //
    //    }
    //
    //MARK: - PinMapVCDelegate
    func didFinishUpdate(location: CLLocationCoordinate2D) {
        
        // Save to variable
        self.newLocation = location
        
        // Present to UI
        convertToPlaceMark(location) { (address) in
            if let address = address {
                self.locationLabel.text = address
            }
        }
        
    }
    
    func convertToPlaceMark(_ location: CLLocationCoordinate2D, _ handler: @escaping ((String?) -> Void)) {
        
        let loc : CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        CLGeocoder().reverseGeocodeLocation(loc) {
            placemarks,err in
            
            if err != nil {
                print("geocoder error")
                handler(nil)
                return
            }
            if let places = placemarks{
                guard let subAdministrativeArea = places[0].subAdministrativeArea else {
                    self.locationLabel.text = "Can't locate associated region"
                    return
                }
                handler(subAdministrativeArea)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinMapSegue"{
            if let PinMapVC = segue.destination as? PinMapVC{
                PinMapVC.delegate = self
            }
        }
    }
    
    //MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProviders = results.map(\.itemProvider)
        for (i, itemProvider) in itemProviders.enumerated() where itemProvider.canLoadObject(ofClass: UIImage.self) {
            
            let previousImage = self.photoImageCollection[i].image
            itemProvider.loadObject(ofClass: UIImage.self) {[weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage, self.photoImageCollection[i].image == previousImage else { return }
                    self.photoImageCollection[i].image = image
                }
            }
            
        }
        
    }
    
    // Upload mutiple images.
    func startUploading(completion: @escaping FileCompletionBlock) {
        if self.images.count == 0 {
            completion()
            return;
        }
        
        block = completion
        uploadImage(forIndex: 0)
    }
    
    func uploadImage(forIndex index:Int) {
        
        if index < self.images.count {
            /// Perform uploading
            let data = self.images[index]
            guard let uuid = self.uuid else { return }
            let fileName = String(format: "%@.jpeg", "\(uuid)_\(index)")
            
            UploadToStorage.shared.upload(data: data, withName: fileName, block: { (url) in
                /// After successfully uploading call this method again by increment the **index = index + 1**
                print(url ?? "Couldn't not upload. You can either check the error or just skip this.")
                if let imageURL = url {
                    self.imagesURL.append(imageURL)
                }
                self.uploadImage(forIndex: index + 1)
            })
            return;
        }
        
        if block != nil {
            block!()
        }
    }
    
    
    
}
