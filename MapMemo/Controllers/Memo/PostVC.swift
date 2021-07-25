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
    @IBOutlet weak var typeImageView: UIImageView!
    var currentPost : PostModel?
        
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
}
