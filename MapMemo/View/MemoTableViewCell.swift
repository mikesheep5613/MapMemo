//
//  MemoTableViewCell.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/30.
//

import UIKit
import Firebase

class MemoTableViewCell: UITableViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    var db : Firestore!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // load data from Firebase
        db = Firestore.firestore()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - Profile info
    func montitorProfileData(userUID : String) {
            db.collection("users").document(userUID).getDocument { (docSnapshot, error) in
                
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let document = docSnapshot else {return}
                
                if let data = document.data(){
                    self.profileName.text = data["username"] as? String
                    
                    //Reload image
                    guard let photoURL = data["photoURL"] as? String else {return}
                    if let loadImageURL = URL(string: photoURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                self.profileImageView.image = image
                                self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height / 2
                                self.profileImageView.clipsToBounds = true
                            }

                        }
                    }

                    
                }
                
            }
    }

}
