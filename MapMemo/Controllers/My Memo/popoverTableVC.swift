//
//  popoverTableVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/23.
//

import UIKit

protocol PopoverViewControllerDelegate: AnyObject {
    func didSelectData(_ result: String)
}

class popoverTableVC: UITableViewController {
    let sortOption = ["Date:New->Old","Date:Old->New"]
    
    weak var delegate: PopoverViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sortOption.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = self.sortOption[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let selectedItem = self.sortOption[indexPath.row]
        self.delegate?.didSelectData(selectedItem)
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
        
    }

}
