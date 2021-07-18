//
//  TableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import UIKit
import Firebase
import FirebaseFirestore
//import FirebaseAuth
import FirebaseStorage

class TableVC: UIViewController {
    
    var data : [PostModel] = []

    var db : Firestore!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load data from Firebase
        db = Firestore.firestore()
        monitorData()

        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    
    // Retrieve data from Firebase
    func monitorData() {
        guard let userID = Auth.auth().currentUser?.email else {
            assertionFailure("Invalid userID")
            return
        }
        self.db.collection(userID).addSnapshotListener { qSnapshot, error in
            if let e = error {
                print("error snapshot listener \(e)")
                return
            }
            guard let documentsChange = qSnapshot?.documentChanges else {return}
           
            for change in documentsChange {
                
                if change.type == .added{
                    //建立資料
                    let post = PostModel(document: change.document)
                    //Reload Table
                    self.data.insert(post, at: 0)
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: .automatic)
                    //Reload image
                    guard let imageURL = post.imageURL else {return}
                    if let loadImageURL = URL(string: imageURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                post.image = image
                                self.tableView.reloadData()
                            }

                        }
                    }

                }else if change.type == .modified{
                    
                    //透過documentId找到self.data相對應的Note
                    let docID = change.document.data()["postID"] as? String
                    if let post = self.data.filter({ post in post.postID == docID }).first{
                        //更新資料
                        post.title = change.document.data()["title"] as? String
                        post.text = change.document.data()["text"] as? String
                        post.type = change.document.data()["type"] as? String
                        post.date = change.document.data()["date"] as? String
                        post.imageURL = change.document.data()["imageURL"] as? String
                        post.latitude = change.document.data()["latitude"] as? Double
                        post.longitude = change.document.data()["longitude"] as? Double
                        
                        //Reload Table
                        if let index = self.data.firstIndex(of: post){
                            let indexPath = IndexPath(row: index, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                        //Reload image
                        guard let imageURL = post.imageURL else {return}
                        if let loadImageURL = URL(string: imageURL){
                            NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                DispatchQueue.main.async {
                                    post.image = image
                                    self.tableView.reloadData()
                                }

                            }
                        }

                    }
                }else if change.type == .removed {
                    //透過documentId找到self.data相對應的Note
                    let docID = change.document.data()["postID"] as? String
                    if let post = self.data.filter({ post in post.postID == docID }).first{
                        //Reload Table
                        if let index = self.data.firstIndex(of: post){
                            self.data.remove(at: index)
                            let indexPath = IndexPath(row: index, section: 0)
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        }

                    }

                }
            }
        }
        
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
                    post.date = document.data()["date"] as? String
                    post.imageURL = document.data()["imageURL"] as? String
                    post.latitude = document.data()["latitude"] as? Double
                    post.longitude = document.data()["longitude"] as? Double
                    
                    if let loadImageURL = URL(string: post.imageURL!){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                post.image = image
                                self.tableView.reloadData()
                            }

                        }
                    }
                                        
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
        cell.imageView?.image = item.thumbnailImage()
        return cell
    }
    
    
}

extension TableVC : UITableViewDelegate{
    
}
