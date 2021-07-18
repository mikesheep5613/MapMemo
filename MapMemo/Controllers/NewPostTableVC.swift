//
//  NewPostTableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/12.
//

import UIKit
import MapKit
import Firebase

class NewPostTableVC: UITableViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PinMapVCDelegate {
    
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleTextField: RoundedTextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeSegmentControl: UISegmentedControl!
    @IBOutlet weak var textView: UITextView!
    
    var newLocation : CLLocationCoordinate2D?
    var newType : String?
    var newImageURL : String?
    var db : Firestore!
    
    // Create property for retrieve data from PostVC
    var editPost : PostModel?
    
    private let storage = Storage.storage().reference()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.titleTextField.delegate = self
        
        self.textView.delegate = self
        self.textView.layer.cornerRadius = 5.0
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.textView.layer.borderWidth = 1
        
        self.photoImageView.image = editPost?.image
        self.titleTextField.text = editPost?.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        self.datePicker.date = dateFormatter.date(from: editPost?.date ?? "") as? Date ?? Date.init()

        
        self.locationLabel.text = reverseGeocodeLocation(location: editPost?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0))
        
        
        self.typeSegmentControl.selectedSegmentIndex = typeSegmentIndexCheck(editPost?.type ?? "other")
        self.textView.text = editPost?.text
        

        
        createToolbar(textField: self.textView)
        db = Firestore.firestore()
    }
    
    @IBAction func uploadPost(_ sender: UIBarButtonItem) {
        
        self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "slowmo")
        self.navigationItem.rightBarButtonItem?.tintColor = .lightGray
        
        //Upload image data to firebase storage
        let uuid = UUID().uuidString
        guard let uploadImage = self.photoImageView.image?.resize(maxEdge: 1024) else {return}
        guard let realUploadImage = uploadImage.jpegData(compressionQuality: 0.7) else {return}

        storage.child("images/\(uuid).jpeg").putData(realUploadImage, metadata: nil) { _, error
            in
            if let error = error {
                assertionFailure("Fail to upload image")
            }
            self.storage.child("images/\(uuid).jpeg").downloadURL { url, error in
                guard let url = url , error == nil else{
                    return
                }
                self.newImageURL = url.absoluteString // Save to global property
                
                //Upload Dict to firebase
                if let userID = Auth.auth().currentUser?.email, let title = self.titleTextField.text , let text = self.textView.text,  let location = self.newLocation, let type = self.newType, let imageURL = self.newImageURL  {
                    
                    let documentID = "\(Date().timeIntervalSince1970)"
                    let date = self.datePicker.date.description

                    let ref = self.db.collection(userID).document(documentID)
                    let data = [
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
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
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
            self.textView.textColor = UIColor.black
        }

    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.textView.text.isEmpty {
            self.textView.text = ""
//            self.textView.textColor = UIColor.lightGray
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
            self.newType = "mountain_climbing"
        case 1:
            self.newType = "river_trekking"
        case 2:
            self.newType = "waterfall"
        case 3:
            self.newType = "camping"
        case 4:
            self.newType = "snorkeling"
        case 5:
            self.newType = "other"
        default:
            self.newType = "mountain_climbing"
        }
    }
    
    func typeSegmentIndexCheck(_ type: String) -> Int {
        var int : Int = 0
        if type == "mountain_climbing" {
            int = 0
        } else if type == "river_trekking"{
            int = 1
        } else if type == "waterfall"{
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
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photoImageView.image = selectedImage
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.clipsToBounds = true
        }
        
        imageLayout(imageView: photoImageView)
        dismiss(animated: true, completion: nil)
    }
    
    func imageLayout(imageView: UIImageView) {
            let leading = NSLayoutConstraint(item: photoImageView as Any, attribute: .leading, relatedBy: .equal, toItem: photoImageView.superview, attribute: .leading, multiplier: 1, constant: 0)
            leading.isActive = true

            let trailing = NSLayoutConstraint(item: photoImageView as Any, attribute: .trailing, relatedBy: .equal, toItem: photoImageView.superview, attribute: .trailing, multiplier: 1, constant: 0)
            trailing.isActive = true

            let top = NSLayoutConstraint(item: photoImageView as Any, attribute: .top, relatedBy: .equal, toItem: photoImageView.superview, attribute: .top, multiplier: 1, constant: 0)
            top.isActive = true

            let bottom = NSLayoutConstraint(item: photoImageView as Any, attribute: .bottom, relatedBy: .equal, toItem: photoImageView.superview, attribute: .bottom, multiplier: 1, constant: 0)
            bottom.isActive = true

        }

    //MARK: - PinMapVCDelegate
    func didFinishUpdate(location: CLLocationCoordinate2D) {
                
        // Save to variable
        self.newLocation = location

        // Present to UI
        if let locationLabel = reverseGeocodeLocation(location: location) {
            self.locationLabel.text = locationLabel
        }
        self.tableView.reloadData()
    }
    
    func reverseGeocodeLocation(location: CLLocationCoordinate2D) -> String? {
        
        let geocoder = CLGeocoder()
        var description : String = ""
        let loc : CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geocoder.reverseGeocodeLocation(loc) { (placemarks, error) in
            if let places = placemarks{
                guard let subAdministrativeArea = places[0].subAdministrativeArea else {
                    description = "Can't locate associated region"
                    return }
                description = subAdministrativeArea
            }
        }
        return description
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinMapSegue"{
            if let PinMapVC = segue.destination as? PinMapVC{
                PinMapVC.delegate = self
            }
        }
    }
    
}
