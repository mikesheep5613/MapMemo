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
import GoogleSignIn


class ProfileVC: UIViewController, UITableViewDelegate,  MFMailComposeViewControllerDelegate {
    
    var sectionTitles = ["Account Setting", "Feedback", "Version"]
    var sectionContent = [[( image: "person.fill", text: "Edit Profile"),
                           ( image: "lock.fill", text: "Change Password"),
                           ( image: "hand.point.left.fill", text: "Log Out")],
                          [( image: "envelope.fill", text: "Send Email To Developer"),
                           (image: "star.circle.fill" , text: "Rate Us On App Store")],
                          [ (image: "wrench.and.screwdriver.fill" , text:"1.0.0"),(image: "doc.fill" , text: "Privacy Policy") ]]
    
    var db : Firestore!
    var userEmail : String?
    var userName : String?
    var userImage : UIImage?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update App Version
        guard let version = Bundle.main.versionNumber else {return}
        sectionContent[2][0].text = version
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        //        navigationController?.navigationBar.prefersLargeTitles = true
        
        self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
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
        
        if UserDefaults.standard.value(forKey: "username") as! String == "guest" {
            return
        }
        
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
                
                // Guest Login
                if UserDefaults.standard.value(forKey: "username") as! String == "guest" {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    return
                }
                
                performSegue(withIdentifier: "editProfileSegue", sender: self)
            } else if indexPath.row == 1{
                // Change Password
                
                // Guest Login
                if UserDefaults.standard.value(forKey: "username") as! String == "guest" {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    return
                }
                
                performSegue(withIdentifier: "editProfileSegue", sender: self)
            } else if indexPath.row == 2{
                
                if UserDefaults.standard.value(forKey: "username") as! String == "guest" {
                    UserDefaults.standard.removeObject(forKey: "username")
                    UserDefaults.standard.synchronize()
                    if let window = self.view.window {
                        checkLogin(window : window)
                    }
                    return
                }
                
                // set fcmToken Id as 0 (null)
                if let userID = Auth.auth().currentUser?.uid {
                    let usersRef = Firestore.firestore().collection("users_table").document(userID)
                    //                    usersRef.setData(["fcmToken": "0"], merge: true)
                    usersRef.setData(["fcmToken": "0"], merge: true) { error in
                        if let e = error {
                            print("set fcmToken Id as 0 (null) error: \(e)")
                        }
                        
                        // Log Out
                        let firebaseAuth = Auth.auth()
                        do {
                            try firebaseAuth.signOut()
                            GIDSignIn.sharedInstance.signOut()
                            UserDefaults.standard.removeObject(forKey: "username")
                            UserDefaults.standard.synchronize()
                        } catch let signOutError as NSError {
                            print("Error signing out: %@", signOutError)
                        }
                        if let window = self.view.window {
                            checkLogin(window: window)
                        }
                        
                        
                    }
                    
                    
                    
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
                                                    mailController.setToRecipients(["mikesheep5613@gmail.com"])
                                                    self.present(mailController, animated: true, completion: nil)
                                                })
                    alert.addAction(email)
                    self.present(alert, animated: true, completion: nil)
                }else{
                    //alert user can't send email
                    self.openAlert(title: "Alert", message: "Unable to send email, please check your device configuration." , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                        print("Okay clicked!")
                    }])
                    
                }
                
                
            } else if indexPath.row == 1{
                //Rate us
                let askController = UIAlertController(title: "Hello App User", message: "If you like this app,please rate in App Store. Thanks.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Rate it", style: .default) { (action) -> Void in
                    let appID = "1579619070" // My App ID
                    let appURL =
                        URL(string: "https://itunes.apple.com/us/app/itunes-u/id\(appID)?action=write-review")!
                    UIApplication.shared.open(appURL, options: [:],
                                              completionHandler: { (success) in
                                              })
                }
                askController.addAction(okAction)
                
                let laterAction = UIAlertAction(title: "Later", style: .default, handler: nil)
                askController.addAction(laterAction)
                
                self.present(askController, animated: true, completion: nil)
                
            }
        // Version section
        case 2:
            if indexPath.row == 1 {
                if let blogURL = URL(string: "https://mapmemoapp.blogspot.com/"){
                    UIApplication.shared.open(blogURL, options: [:]) { (success) in
                        
                    }
                }
            }
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension Bundle {
    var versionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var bundleName: String? {
        return infoDictionary?["CFBundleName"] as? String
    }
}
