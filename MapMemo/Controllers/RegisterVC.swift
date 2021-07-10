//
//  RegisterVC.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/11.
//

import UIKit
import Firebase

class RegisterVC: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func snedBtnPressed(_ sender: Any) {
        
        if let email = emailTextfield.text, let password = passwordTextfield.text {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Resgister error : \(error)")
                } else {
                    let alert = UIAlertController(title: "SUCCESS", message: "Your account has been successfully created.", preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "Continue", style: .cancel) { action in
                        self.navigationController?.popViewController(animated: true)
                    }
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
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
