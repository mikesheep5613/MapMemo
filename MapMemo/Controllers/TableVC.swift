//
//  TableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class TableVC: UIViewController {
    
    var data : [PostModel] = []

    var db : Firestore!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        let setting = FirestoreSettings()
        Firestore.firestore().settings = setting
        db = Firestore.firestore()
        queryFromFireStore()// load data from Firebase
        
    }
    
    
    // Retrieve data from Firebase
    func queryFromFireStore() {
        
        if let userID = Auth.auth().currentUser?.email{
            db.collection(userID).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Query error : \(error)")
                }
                guard let snapshot = querySnapshot else {return}
                for document in snapshot.documents{
                    let post = PostModel()
                    post.title = document.data()["title"] as? String
                    post.text = document.data()["text"] as? String
                    post.type = document.data()["type"] as? String
                    post.date = document.data()["date"] as? Date
                    post.imageURL = document.data()["imageURL"] as? String
                    post.latitude = document.data()["latitude"] as? Double
                    post.longitude = document.data()["longitude"] as? Double
                                        
                    self.data.append(post)
                }
                // update UI
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

            }
        }
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "postSegue" {
            // head to PostVC
            if let postVC = segue.destination as? PostVC, let indexPath = self.tableView.indexPathForSelectedRow {
                let post = self.data[indexPath.row]
                postVC.currentPost = post
            }
        }
    }
    

}

extension TableVC : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.detailTextLabel?.text = item.date?.description
        cell.textLabel?.text = item.title
//        cell.imageView?.image = item.imageDownloadFromStorage()
        return cell
    }
    
    
}

extension TableVC : UITableViewDelegate{
    
}
