//
//  PostVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import Foundation
import UIKit
import MapKit

class PostVC: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    var currentPost : PostModel?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change tab bar index to tableVC
        tabBarController?.selectedIndex = 1
        
        self.dataLabel.text = currentPost?.date
        self.titleLabel.text = currentPost?.title
        self.textView.text = currentPost?.text
        self.imageView.image = currentPost?.image
                
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
    
}
