//
//  ImagesViewController.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/8/2.
//

import UIKit

class ImagesViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var image : UIImage?
    
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = image

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
