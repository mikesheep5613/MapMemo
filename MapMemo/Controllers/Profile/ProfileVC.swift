//
//  AboutVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/10.
//

import UIKit
import Firebase
import StoreKit
import MessageUI


class ProfileVC: UIViewController, UITableViewDelegate,  MFMailComposeViewControllerDelegate {
    
    var sectionTitles = ["Account Setting", "Feedback"]
    var sectionContent = [[( image: "person.fill", text: "Edit Profile"),
                           ( image: "lock.fill", text: "Change Password"),
                           ( image: "hand.point.left.fill", text: "Log Out")],
                          [( image: "envelope.fill", text: "Send Email To Developer"),
                           (image: "star.circle" , text: "Rate Us On App Store")]]
    var db : Firestore!
    var userEmail : String?
    var userName : String?
    var userImage : UIImage?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        //        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.imageView.layer.cornerRadius = self.imageView.bounds.height / 2
        self.imageView.clipsToBounds = true
        
        // load data from Firebase
        db = Firestore.firestore()
        montitorProfileData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        montitorProfileData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editProfileSegue" {
            // head to PostVC
            if let editProfileVC = segue.destination as? EditProfileVC, let indexPath = self.tableView.indexPathForSelectedRow {
                //                print(indexPath)
                if indexPath.row == 0 {
                    // Edit Profile
                    editProfileVC.userEmail = self.userEmail
                    editProfileVC.userName = self.userName
                    editProfileVC.userImage = self.userImage
                    
                } else if indexPath.row == 1{
                    // Change Password
                    // do not send userEmail bcz is a switch for EditPorfile VC
                    editProfileVC.userName = self.userName
                    editProfileVC.userImage = self.userImage

                }
            }
        }
    }
    
    // Get Profile Data
    func montitorProfileData() {
        self.userEmail = Auth.auth().currentUser?.email
        
        guard let userID = Auth.auth().currentUser?.uid else {return}
        
        self.db.collection("users").addSnapshotListener { qSnapshot, error in
            if let e = error {
                print("error snapshot listener \(e)")
                return
            }
            
            guard let qsanp = qSnapshot else {return}
            for doc in qsanp.documents {
                if doc.documentID == userID{
                    let userName = doc.data()["username"] as? String
                    self.userName = userName
                    self.userNameLabel.text = self.userName
                    
                    let photoURL = doc.data()["photoURL"] as? String
                    //Reload image
                    guard let photoURL = photoURL else {return}
                    if let loadImageURL = URL(string: photoURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                self.userImage = image
                                self.imageView.image = self.userImage
                                self.imageView.layer.cornerRadius = self.imageView.bounds.height / 2
                                self.imageView.clipsToBounds = true
                            }
                        }
                    }
                }
            }
            
        }
        
    }
}


//MARK: - UITableViewDataSource
extension ProfileVC : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionContent[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sectionContent[indexPath.section][indexPath.row]
        cell.textLabel?.text = item.text
        cell.imageView?.image = UIImage(systemName: item.image)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        // Account section
        case 0:
            if indexPath.row == 0 {
                // Edit Profile
                performSegue(withIdentifier: "editProfileSegue", sender: self)
            } else if indexPath.row == 1{
                // Change Password
                performSegue(withIdentifier: "editProfileSegue", sender: self)
            } else if indexPath.row == 2{
                // Log Out
                do {
                    try Auth.auth().signOut()
                    UserDefaults.standard.removeObject(forKey: "username")
                    UserDefaults.standard.synchronize()
                    if let window = self.view.window {
                        checkLogin(window : window)
                    }
                } catch let signOutError as NSError {
                    print("Signing out error : \(signOutError)")
                }
                
            }
        // Feedback section
        case 1:
            if indexPath.row == 0 {
                // Mail us
                if ( MFMailComposeViewController.canSendMail()){
                    let alert = UIAlertController(title: "", message: "We want to hear from you, Please send us your feedback by email in English", preferredStyle: .alert)
                    let email = UIAlertAction(title: "email", style: .default, handler:
                                                { (action) -> Void in
                                                    let mailController = MFMailComposeViewController()
                                                    mailController.mailComposeDelegate = self
                                                    mailController.title = "I have question"
                                                    mailController.setSubject("I have question")
                                                    let version = Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString")
                                                    let product = Bundle.main.object(forInfoDictionaryKey:"CFBundleName")
                                                    let messageBody = "<br/><br/><br/>Product:\(product!)(\(version!))"
                                                    mailController.setMessageBody(messageBody, isHTML: true)
                                                    mailController.setToRecipients(["support@yoursupportemail.com"])
                                                    self.present(mailController, animated: true, completion: nil)
                                                })
                    alert.addAction(email)
                    self.present(alert, animated: true, completion: nil)
                }else{
                    //alert user can't send email
                }
                
                
            } else if indexPath.row == 1{
                //Rate us
                let askController = UIAlertController(title: "Hello App User", message: "If you like this app,please rate in App Store. Thanks.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "我要評分", style: .default) { (action) -> Void in
                    let appID = "12345"
                    let appURL =
                        URL(string: "https://itunes.apple.com/us/app/itunes-u/id\(appID)?action=write-review")!
                    UIApplication.shared.open(appURL, options: [:],
                                              completionHandler: { (success) in
                                              })
                }
                askController.addAction(okAction)
                
                let laterAction = UIAlertAction(title: "稍候再評", style: .default, handler: nil)
                askController.addAction(laterAction)
                
                self.present(askController, animated: true, completion: nil)
                
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
