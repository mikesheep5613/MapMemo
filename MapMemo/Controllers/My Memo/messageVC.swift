//
//  commentVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/8/7.
//

import UIKit
import Firebase

class messageVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var currentUserImage: UIImageView!
    let db = Firestore.firestore()
    
    var messages: [Message] = []

    var postID : String?
    
    var username : String?
    var profilePhotoURL : String?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.messageTextField.delegate = self
        
        self.tableView.separatorStyle = .none
        self.tableView.register(UINib(nibName: "MyMessageCell", bundle: nil), forCellReuseIdentifier: "MyMessageCell")
        loadMessages()

        montitorProfileData()
        
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.setEditing(editing, animated: true)
    }
    
    
    //MARK: - Send message
    @IBAction func sendBtnPressed(_ sender: Any) {
        if let username = self.username, let profileImageURL = self.profilePhotoURL, let messageBody = messageTextField.text, let messageSender = Auth.auth().currentUser?.uid, let postID = self.postID {
           
            let nowDate = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = df.string(from: nowDate)
            
            let timeInterval = Date().timeIntervalSince1970
            
            self.db.collection("posts").document(postID).collection("messages").document("\(timeInterval)").setData([
                "userID": messageSender,
                "body": messageBody,
                "date": dateString,
                "username": username,
                "photoURL" : profileImageURL,
                "timeInterval" : timeInterval
            ]) { error in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                }else {
                    print("Successfully saved data.")
                    
                    DispatchQueue.main.async {
                         self.messageTextField.text = ""
                    }
                }
            }
        }
    }
    //MARK: - Profile info
    func montitorProfileData() {
        if let userUID = Auth.auth().currentUser?.uid {
            db.collection("users").document(userUID).getDocument { (docSnapshot, error) in
                
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let document = docSnapshot else {return}
                
                if let data = document.data(){
                    self.username = data["username"] as? String
                    self.profilePhotoURL = data["photoURL"] as? String
                    print("username: \(String(describing: self.username))")
                    print("userPhotoURL: \(String(describing: self.profilePhotoURL))")
                    
                    //Reload image
                    guard let profileURL = self.profilePhotoURL else {return}
                    if let loadImageURL = URL(string: profileURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                self.currentUserImage.image = image
                                self.currentUserImage.layer.cornerRadius = self.currentUserImage.frame.height / 2
                                self.currentUserImage.clipsToBounds = true

                            }

                        }
                    }
                }
                
            }
            
        }
        
    }
    
    //MARK: - Load messages
    func loadMessages() {
        guard let postID = self.postID else {
            assertionFailure("unwrap postID failed")
            return
        }
        
        self.db.collection("posts").document(postID).collection("messages").order(by: "timeInterval", descending: true).addSnapshotListener({ (querySnapshot, error)  in
            self.messages = []

            if let e = error {
                print("There was an issue retrieving data from Firestore. \(e)")
            }else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let messageSender = data["userID"] as? String,
                           let messageBody = data["body"] as? String,
                           let messageDate = data["date"] as? String,
                           let messageUsername = data["username"] as? String,
                           let messageProfileURL = data["photoURL"] as? String,
                           let messageTimeInterval = data["timeInterval"] as? Double {
        
                            
                            //Reload image
                            if let loadImageURL = URL(string: messageProfileURL){
                                NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                    let newMessage = Message(sender: messageSender, body: messageBody, date: messageDate, photoURL: messageProfileURL, username: messageUsername, profileImage: image, timeInterval: messageTimeInterval)
                                    self.messages.append(newMessage)
                                    self.messages = self.messages.sorted(by: { ($0.timeInterval ) > ($1.timeInterval)})
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        let indexPath = IndexPath(row: 0, section: 0)
                                        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                                    }

                                }
                            }
                            
                        }
                    }
                }
            }
        })
    }
    

}
//MARK: - UITextFieldDelegate
extension messageVC: UITextFieldDelegate {
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

//MARK: - UITableViewDataSource
extension messageVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
        cell.label.text = message.body
        cell.userNameLabel.text = message.username
        cell.dateLabel.text = message.date
        cell.leftImageView.image = message.profileImage

        //This is a message from the current user.
//        if message.sender == Auth.auth().currentUser?.uid {
//            cell.leftImageView.isHidden = true
//        } else {
//            cell.leftImageView.isHidden = false
//        }
        return cell

    }
}

//MARK: - UITableViewDelegate
extension messageVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {//紅色刪除，另一種是綠色加號
            //1.刪除data中的資料
            let message = self.messages.remove(at: indexPath.row)
            guard let postID = self.postID else {return}
            
            if Auth.auth().currentUser?.uid == message.sender {
                self.db.collection("posts").document(postID).collection("messages").document("\(message.timeInterval)").delete()
                //2.通知畫面更新
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }else {
                let alertController = UIAlertController(title: "Unable to delete this message!", message: "Please check you select your message.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)

            }

            
        }
        
    }
    
    
}
