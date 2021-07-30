//
//  PostVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import Foundation
import UIKit
import MapKit
import Firebase

class PostVC: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    
    var currentPost : PostModel?
    var db : Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        // load data from Firebase
        db = Firestore.firestore()
        montitorProfileData()
        
        
        // Present UI.
        self.dataLabel.text = DateFormatter.localizedString(from: (currentPost?.date)!, dateStyle: .long, timeStyle: .none)
        self.titleLabel.text = currentPost?.title
        self.textView.text = currentPost?.text
        self.imageView.image = currentPost?.image
        switch currentPost?.type{
        case "mountain":
            self.typeImageView.image = UIImage(named: "山")
        case "snorkeling":
            self.typeImageView.image = UIImage(named: "浮潛")
        case "waterfall":
            self.typeImageView.image = UIImage(named: "瀑布")
        case "camping":
            self.typeImageView.image = UIImage(named: "露營")
        case "hotspring":
            self.typeImageView.image = UIImage(named: "野溪")
        case "other":
            self.typeImageView.image = UIImage(named: "其他")
        default:
            self.typeImageView.image = UIImage(named: "山")
        }
        
        // If current user is not the author, disable the edit button
        if Auth.auth().currentUser?.uid != self.currentPost?.authorID {
            navigationItem.rightBarButtonItem?.isEnabled = false
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

    
    @IBAction func editBtnPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "editSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editSegue" {
            if let newPostTableVC = segue.destination as? NewPostTableVC {
                newPostTableVC.editPost = self.currentPost
            }
        }
    }
    
    //MARK: - Profile info
    func montitorProfileData() {
        if let userUID = self.currentPost?.authorID {
            db.collection("users").document(userUID).getDocument { (docSnapshot, error) in
                
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let document = docSnapshot else {return}
                
                if let data = document.data(){
                    self.userNameLabel.text = data["username"] as? String
                    
                    //Reload image
                    guard let photoURL = data["photoURL"] as? String else {return}
                    if let loadImageURL = URL(string: photoURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                self.userProfileImage.image = image
                                self.userProfileImage.layer.cornerRadius = self.userProfileImage.bounds.height / 2
                                self.userProfileImage.clipsToBounds = true
                            }

                        }
                    }

                    
                }
                
            }
            
        }
        
    }
    
}
