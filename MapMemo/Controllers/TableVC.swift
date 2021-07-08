//
//  TableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/3.
//

import UIKit

class TableVC: UIViewController {
    
    var Posts : [Post] = ItemListHelper().decodeItem()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        

        // Do any additional setup after loading the view.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "postSegue" {
            // head to PostVC
            if let postVC = segue.destination as? PostVC, let indexPath = self.tableView.indexPathForSelectedRow {
                let post = self.Posts[indexPath.row]
                postVC.currentPost = post
            }
        }
    }
    

}

extension TableVC : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.Posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = Posts[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.detailTextLabel?.text = item.date
        cell.textLabel?.text = item.title
        cell.imageView?.image = item.thumbnailImage()
        
        
        return cell
    }
    
    
}

extension TableVC : UITableViewDelegate{
    
}
