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
    
    var data : [PostModel] = [] //全部的資料都在這,searchcontroller.isActive=false時顯示
    var filteredData : [PostModel] = [] //過濾後的資料,searchcontroller.isActive=true時顯示
    
    var searchController = UISearchController(searchResultsController: nil)

    var db : Firestore!
    
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // load data from Firebase
        db = Firestore.firestore()
        monitorData()

        self.tableView.dataSource = self
        
        self.navigationItem.searchController = self.searchController
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self

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
                    //Reload image
                    guard let imageURL = post.imageURL else {return}
                    if let loadImageURL = URL(string: imageURL){
                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
                            DispatchQueue.main.async {
                                post.image = image
                                //Reload Table
                                self.data.insert(post, at: 0)
                                let indexPath = IndexPath(row: 0, section: 0)
                                self.tableView.insertRows(at: [indexPath], with: .automatic)
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
                        post.imageURL = change.document.data()["imageURL"] as? String
                        post.latitude = change.document.data()["latitude"] as? Double
                        post.longitude = change.document.data()["longitude"] as? Double
                        if let tempDate = change.document.data()["date"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                            post.date = dateFormatter.date(from: tempDate)
                        }
                        
                        //Reload image
                        guard let imageURL = post.imageURL else {return}
                        if let loadImageURL = URL(string: imageURL){
                            NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                DispatchQueue.main.async {
                                    post.image = image
                                    if let index = self.data.firstIndex(of: post){
                                        let indexPath = IndexPath(row: index, section: 0)
                                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                    }

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
    
//     Retrieve data from Firebase
//    func queryFromFireStore() {
//
//        if let userID = Auth.auth().currentUser?.email{
//            db.collection(userID).getDocuments { (querySnapshot, error) in
//                if let error = error {
//                    print("Query error : \(error)")
//                }
//                guard let snapshot = querySnapshot else {return}
//                for document in snapshot.documents{
//                    let post = PostModel()
//                    post.title = document.data()["title"] as? String
//                    post.text = document.data()["text"] as? String
//                    post.type = document.data()["type"] as? String
//                    post.date = document.data()["date"] as? String
//                    post.imageURL = document.data()["imageURL"] as? String
//                    post.latitude = document.data()["latitude"] as? Double
//                    post.longitude = document.data()["longitude"] as? Double
//
//                    if let loadImageURL = URL(string: post.imageURL!){
//                        NetworkController.shared.fetchImage(url: loadImageURL) { image in
//                            DispatchQueue.main.async {
//                                post.image = image
//                                self.tableView.reloadData()
//                            }
//
//                        }
//                    }
//
//                    self.data.append(post)
//                }
//                // update UI
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//
//            }
//        }
//    }


    
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
        
        if segue.identifier == "sortingSegue"{
            if let popoverVC = segue.destination as? popoverTableVC {
                popoverVC.preferredContentSize = CGSize(width: 180, height: 90)
                popoverVC.popoverPresentationController?.delegate = self
                popoverVC.delegate = self

            }
        }
    }
}

//MARK: - UITableViewDataSource
extension TableVC : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive {//搜尋模式，找filteredData
            return self.filteredData.count
        }else{
            return self.data.count//10
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        //顯示search bar過濾後內容
        let item = self.searchController.isActive ? self.filteredData[indexPath.row] : self.data[indexPath.row]

        cell.textLabel?.text = item.title
        cell.imageView?.image = item.thumbnailImage()
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: item.date!, dateStyle: .long, timeStyle: .none)
        return cell
    }
    
    
}

//MARK: - UISearchResultsUpdating
extension TableVC : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        //key search字會被呼叫的delegate方法
        //根據使用者輸入的字，過濾資料放到filteredData
        generateFilterData()
        //更新tableView
        self.tableView.reloadData()
    }
    
    func generateFilterData() {
        
        if self.searchController.isActive , let text = self.searchController.searchBar.text {
            // 根據使用者輸入字，過濾資料放到filteredData
            self.filteredData = self.data.filter { n in
                if let content = n.title {
                    let isMatch = content.localizedCaseInsensitiveContains(text)
                    return isMatch
                }
                return false
            }
            
        } else {
            self.filteredData = []
        }
    }
}

//MARK: - UIPopoverPresentationControllerDelegate
extension TableVC : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return .none
        
    }
}

extension TableVC : PopoverViewControllerDelegate {
    func didSelectData(_ result: String) {
        
        if result == "Date: New -> Old" {
            self.data = self.data.sorted(by: { ($0.date! ) < ($1.date!)})
        } else {
            self.data = self.data.sorted(by: { ($0.date! ) > ($1.date!)})
        }
        
        self.tableView.reloadData()

    }
    
    
}
