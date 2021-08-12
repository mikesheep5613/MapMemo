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
import KRProgressHUD

class NewPostTableVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate, PinMapVCDelegate, PHPickerViewControllerDelegate {
    
    
    @IBOutlet var photoImageCollection: [UIImageView]!
//    @IBOutlet weak var photoImageView: UIImageView!
    
    
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
        // type預設為mountain type
        self.newType = "mountain"
        
        // 設置UISwitch功能
        self.isPublicSwitch.addTarget(self, action: #selector(isPublicSwitchPressed(_:)), for: .valueChanged)
                
        // check whether editPost receieve model
        if editPost != nil {
            self.isEditMode = true
            
            // Present to UI
            guard let editImageArray = editPost?.imageArray else {return}
            let imageCount = editImageArray.count
            for i in 0 ..< imageCount {
                self.photoImageCollection[i].image = editImageArray[i]
                imageLayout(imageView: self.photoImageCollection[i])
            }

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
    }
    
    @IBAction func addPhotoBtn(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 3
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
        
        
    }
    
    @IBAction func removePhotoBtn(_ sender: Any) {
        // 照片處理
        for imageView in self.photoImageCollection {
            let image = UIImage(systemName: "photo")
            image?.withTintColor(.opaqueSeparator)
            imageView.image = image
        }
    }
    
    @IBAction func uploadBtnPressed(_ sender: Any) {
        KRProgressHUD.show()
        //Upload image data to firebase storage
        // check Post need to be Added or Edited
        if self.isEditMode == true {
            self.uuid = editPost?.postID
        } else {
            self.uuid = UUID().uuidString
        }
        guard let uuid = self.uuid else {return}
        
//        if self.typeSegmentControl.isSelected != true {
//            KRProgressHUD.dismiss()
//
//            let alert = UIAlertController(title: "Unable to upload!!", message: "Please confirm the fields are filled and submit it again.", preferredStyle: .alert)
//            let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
//            alert.addAction(cancel)
//            self.present(alert, animated: true, completion: nil)
//            return
//        }
        
        
        // 照片處理
        for imageView in self.photoImageCollection {
            //如果照片有更新過才上傳
            if imageView.image != UIImage(systemName: "photo"){
                guard let image = imageView.image?.resize(maxEdge: 1024) else {return}
                guard let uploadImage = image.jpegData(compressionQuality: 0.7) else {return}
                self.images.append(uploadImage)
            }
        }
        
        // 如果沒輸入以下欄位會跳alert
        if  self.titleTextField.text == "" || self.textView.text == "" || self.newLocation == nil || self.newType == nil || self.images.isEmpty  {
            KRProgressHUD.dismiss()

            let alert = UIAlertController(title: "Unable to upload!!", message: "Please confirm the fields are filled and submit it again.", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Continue", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            return
        }

                
        // 同時上傳照片以及資料
        startUploading {
            // All images have been uploaded
            if let userID = Auth.auth().currentUser?.uid,
               let title = self.titleTextField.text,
               let text = self.textView.text,
               let location = self.newLocation,
               let type = self.newType
            {
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
                            KRProgressHUD.dismiss()
                            self.navigationController?.popToRootViewController(animated: true)
                            
                        } else {
                            // if not, pop to MapVC
                            KRProgressHUD.dismiss()
                            self.navigationController?.popViewController(animated: true)
                            
                        }
                    }
                }
            }
        }

    }
    
    @IBAction func trashBtnPressed(_ sender: UIBarButtonItem) {
        
        if self.isEditMode == true {
            self.uuid = editPost?.postID
            
            let alert = UIAlertController(title: "Confirm to delete this post?", message: "Press \"Confirm\" to delete the post.", preferredStyle: .alert)
            let pop = UIAlertAction(title: "Confirm", style: .default ){ (action) in
                // Delete post from Firebase
                if let uuid = self.uuid {
                    self.db.collection("posts").document(uuid).delete()
                }
                self.navigationController?.popToRootViewController(animated: true)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(pop)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "Leave this post ?", message: "Press \"Confirm\" to go back.", preferredStyle: .alert)
            let pop = UIAlertAction(title: "Confirm", style: .default ){ (action) in
                self.navigationController?.popViewController(animated: true)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(pop)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        }
        
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
            self.textView.textColor =  UIColor { tc in
                switch tc.userInterfaceStyle {
                case .dark:
                    return UIColor.white
                default:
                    return UIColor.black
                }
            }

        }
        
        if self.isEditMode == true{
            self.textView.textColor =  UIColor { tc in
                switch tc.userInterfaceStyle {
                case .dark:
                    return UIColor.white
                default:
                    return UIColor.black
                }
            }
        }
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.textView.text.isEmpty {
            self.textView.text = "Write Something You Want To Record..."
            self.textView.textColor = .opaqueSeparator
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
                    self.imageLayout(imageView: self.photoImageCollection[i])
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
    
    
    func imageLayout(imageView: UIImageView) {
        let leading = NSLayoutConstraint(item: imageView as Any, attribute: .leading, relatedBy: .equal, toItem: imageView.superview, attribute: .leading, multiplier: 1, constant: 0)
        leading.isActive = true

        let trailing = NSLayoutConstraint(item: imageView as Any, attribute: .trailing, relatedBy: .equal, toItem: imageView.superview, attribute: .trailing, multiplier: 1, constant: 0)
        trailing.isActive = true

        let top = NSLayoutConstraint(item: imageView as Any, attribute: .top, relatedBy: .equal, toItem: imageView.superview, attribute: .top, multiplier: 1, constant: 0)
        top.isActive = true

        let bottom = NSLayoutConstraint(item: imageView as Any, attribute: .bottom, relatedBy: .equal, toItem: imageView.superview, attribute: .bottom, multiplier: 1, constant: 0)
        bottom.isActive = true

    }

    
}
