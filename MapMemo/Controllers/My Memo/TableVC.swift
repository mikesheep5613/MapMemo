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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // load data from Firebase
        db = Firestore.firestore()
        monitorData()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // register a nib for cellReuseIdentifier
        self.tableView.register(UINib(nibName: "MemoTableViewCell", bundle: nil), forCellReuseIdentifier: "memoCell")
        
        
        self.navigationItem.searchController = self.searchController
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchResultsUpdater = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // Retrieve data from Firebase
    // Retrieve data for user only
    func monitorData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            assertionFailure("Invalid userID")
            return
        }
        self.db.collection("posts").whereField("authorID", isEqualTo: userID).addSnapshotListener { qSnapshot, error in
            
            // Start Loading
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()

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
                    guard let imageURLs = post.imageURL else {return}
                    post.imageArray = []
                    for imageURL in imageURLs {
                        if let loadImageURL = URL(string: imageURL){
                            NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                DispatchQueue.main.async {
                                    
                                    guard let image = image else {
                                        assertionFailure("unwrapping image error")
                                        return
                                    }
                                    
                                    post.imageArray?.append(image)
                                    print("Successfully fetch image.")
                                    
                                    //如果圖片陣列讀滿到url陣列數量，更新畫面
                                    if post.imageArray?.count == post.imageURL?.count{
                                        self.data.insert(post, at: 0)
                                        let indexPath = IndexPath(row: 0, section: 0)
                                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                                    }
                                    // Loading Finished
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.isHidden = true

                                }
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
                        post.imageURL = change.document.data()["imageURL"] as? Array<String>
                        post.latitude = change.document.data()["latitude"] as? Double
                        post.longitude = change.document.data()["longitude"] as? Double
                        post.isPublic = change.document.data()["isPublic"] as? Bool
                        if let tempDate = change.document.data()["date"] as? String {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                            post.date = dateFormatter.date(from: tempDate)
                        }
                        
                        //Reload image
                        post.imageArray = []
                        guard let imageURLs = post.imageURL else {return}
                        for imageURL in imageURLs {
                            if let loadImageURL = URL(string: imageURL){
                                NetworkController.shared.fetchImage(url: loadImageURL) { image in
                                    DispatchQueue.main.async {
                                        guard let image = image else {
                                            assertionFailure("unwrapping image error")
                                            return
                                        }
                                        // 把全部圖片刪掉重新load
                                        post.imageArray?.append(image)
                                        print("Successfully fetch image.")
                                        
                                        //如果圖片陣列讀滿到url陣列數量，更新畫面
                                        if post.imageArray?.count == post.imageURL?.count{
                                            if let index = self.data.firstIndex(of: post){
                                                let indexPath = IndexPath(row: index, section: 0)
                                                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                                            }
                                        }
                                        // Loading Finished
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.isHidden = true

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
                    // Loading Finished
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
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
        
        //顯示search bar過濾後內容
        let item = self.searchController.isActive ? self.filteredData[indexPath.row] : self.data[indexPath.row]
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "memoCell", for: indexPath) as! MemoTableViewCell
        cell.titleLabel.text = item.title
        cell.dateLabel.text = DateFormatter.localizedString(from: item.date!, dateStyle: .long, timeStyle: .none)
        if let userUID = item.authorID {
            cell.montitorProfileData(userUID: userUID)
        }
        
        cell.photoImageView.image = item.imageArray?.first
        
        return cell
    }
}

//MARK: -
extension TableVC : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 120 //or whatever you need
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "postSegue", sender: self)
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
        
        if result == "Date:New->Old" {
            self.data = self.data.sorted(by: { ($0.date! ) < ($1.date!)})
        } else if result == "Date:Old->New" {
            self.data = self.data.sorted(by: { ($0.date! ) > ($1.date!)})
        }
        
        self.tableView.reloadData()
        
    }
    
    
}
