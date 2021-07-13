//
//  PostVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import Foundation
import UIKit
class PostVC: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var currentPost : PostModel?
    
    var currentAnnotation : MyAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataLabel.text = currentPost?.date?.description
        self.titleLabel.text = currentPost?.title
        self.textView.text = currentPost?.text
//        self.imageView.image = currentPost?.imageGet()
//        
        
//        guard let imagePath = Bundle.main.path(forResource: self.currentAnnotation?.image, ofType: nil ) else {
//            return
//        }
//
//        self.dataLabel.text = currentAnnotation?.date
//        self.titleLabel.text = currentAnnotation?.title
//        self.textView.text = currentAnnotation?.text
//        self.imageView.image = UIImage(contentsOfFile: imagePath)
//
//        
//        print("post did load")
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
