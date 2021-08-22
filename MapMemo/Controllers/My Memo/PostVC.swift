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
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewSecond: UIImageView!
    @IBOutlet weak var imageViewThird: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var likeBtnOutlet: UIButton!
    @IBOutlet weak var dislikeBtnOutlet: UIButton!
    @IBOutlet weak var commentLabel: UIButton!
    var currentPost : PostModel?
    var db : Firestore!
    
    var imagesPageViewController : ImagesPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // load data from Firebase
        db = Firestore.firestore()
        montitorProfileData()
        
        // Present UI.
        self.dataLabel.text = DateFormatter.localizedString(from: (currentPost?.date)!, dateStyle: .long, timeStyle: .none)
                self.titleLabel.text = currentPost?.title
        self.textView.text = currentPost?.text
        self.pageControl.numberOfPages = currentPost?.imageArray?.count ?? 3
        
        switch currentPost?.type{
        case "mountain":
            self.typeImageView.image = UIImage(named: "山")
        case "snorkeling":
            self.typeImageView.image = UIImage(named: "浮潜")
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
            let reportBtn = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.triangle"), style: .plain, target: self, action: #selector(self.reportButtonAction))
            navigationItem.rightBarButtonItem = reportBtn
        }
        
        // check Like Btn status
        monitorLikeBtn()
        // check Comment Count

        monitirCommentCount()
        
        
        // Guest Login In, not allow to edit
        if UserDefaults.standard.value(forKey: "username") as! String == "guest" {
            self.dislikeBtnOutlet.isEnabled = false
            self.likeBtnOutlet.isEnabled = false
            self.commentLabel.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

    }
    
    // nav invisible
    override func viewWillAppear(_ animated: Bool) {
        // Make the navigation bar background clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        monitirCommentCount()

    }
    override func viewWillDisappear(_ animated: Bool) {
        // Restore the navigation bar to default
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    
    @IBAction func editBtnPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "editSegue", sender: self)
    }
    
    
    @objc func reportButtonAction(_ sender:UIButton!){
        var textField = UITextField()
        
        let reportController = UIAlertController(title: "Report this post?", message: "Please explain the reasons you report this post, we will handle it soonly.",  preferredStyle: .alert)
        
        let reportAction = UIAlertAction(title: "Report", style: .default) { (action) -> Void in
            if let report = textField.text, let userID = Auth.auth().currentUser?.uid, let postID = self.currentPost?.postID{
                self.db.collection("posts").document(postID).collection("reports").document("\(userID)").setData(["report" : report], completion: { error in
                    if let e = error {
                        print("error \(e)")
                        return
                    }
                    self.openAlert(title: "Report Successfully!!", message: "Thanks for your help." , alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in
                    }])
                    
                    
                })
            }
            
        }
        
        reportController.addTextField { (alertTextField) in
            alertTextField.placeholder = "Report this post because ..."
            textField = alertTextField
        }
        
        reportController.addAction(reportAction)
        
        let laterAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        reportController.addAction(laterAction)
        
        self.present(reportController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editSegue" {
            if let newPostTableVC = segue.destination as? NewPostTableVC {
                newPostTableVC.editPost = self.currentPost
            }
        }
        
        if segue.identifier == "messageSegue" {
            if let messageVC = segue.destination as? messageVC {
                messageVC.postID = self.currentPost?.postID
                messageVC.authorID = self.currentPost?.authorID
                messageVC.postTitle = self.currentPost?.title

            }
        }
        
        if segue.identifier == "imagesEmbedSegue"{
            if let imagesPageVC = segue.destination as? ImagesPageViewController {
                imagesPageVC.imagesArray = self.currentPost?.imageArray
                imagesPageViewController = imagesPageVC
                imagesPageViewController?.imagesPageViewControllerDelegate = self
                
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
    
    
    
    //MARK: - Like Button Function
    @IBAction func likeBtnPressed(_ sender: Any) {
        
        //如果是空心
        if let postID = self.currentPost?.postID, let userID = Auth.auth().currentUser?.uid {
            self.db.collection("posts").document(postID).collection("LikeBy").document("\(postID)_\(userID)").setData(["isLikeed" : true]){ error in
                if let e = error {
                    print("Like Button error :\(e)")
                    return
                }
                self.likeBtnOutlet.isHidden = true
                self.dislikeBtnOutlet.isHidden = false
            }
            
        }
    }
    
    //MARK: - Dislike Button Function
    @IBAction func dislikeBtnPressed(_ sender: Any) {
        
        if let postID = self.currentPost?.postID, let userID = Auth.auth().currentUser?.uid {
            self.db.collection("posts").document(postID).collection("LikeBy").document("\(postID)_\(userID)").delete()
            self.likeBtnOutlet.isHidden = false
            self.dislikeBtnOutlet.isHidden = true
        }
    }
    
    func monitorLikeBtn() {
        if let postID = self.currentPost?.postID, let userID = Auth.auth().currentUser?.uid {
            let ref = self.db.collection("posts").document(postID).collection("LikeBy").document("\(postID)_\(userID)")
            ref.getDocument { (qSnapchat, error) in
                if let doc = qSnapchat, doc.exists{
                    self.likeBtnOutlet.isHidden = true
                    self.dislikeBtnOutlet.isHidden = false
                }else{
                    self.likeBtnOutlet.isHidden = false
                    self.dislikeBtnOutlet.isHidden = true
                }
            }
        }
    }
    
    func monitirCommentCount(){
        if let postID = self.currentPost?.postID {
            self.db.collection("posts").document(postID).collection("messages").getDocuments{ qSanpshot, error in
                
                if let e = error {
                    print("monitirCommentCount error \(e)")
                    return
                }
                
                guard let documents = qSanpshot else {return}
                print(documents.count)
                self.commentLabel.setTitle("\(documents.count) Comments", for: .normal)
                
            }
        }
    }
    
}
//MARK: - ImagesPageViewControllerDelegate
extension PostVC : ImagesPageViewControllerDelegate {
    func didUpdatePageIndex(currentIndex: Int) {
        if let index = self.imagesPageViewController?.currentIndex{
            self.pageControl.currentPage = index
        }
    }
    
    
    
}
