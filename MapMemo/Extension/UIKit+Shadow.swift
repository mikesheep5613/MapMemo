//
//  Shadow.swift
//  CafeSeeker
//
//  Created by ChengLu on 2021/7/23.
//

import Foundation
import UIKit

struct Shadow {
    static let shard = Shadow()

    func shadow(textField: UITextField) {
        textField.layer.shadowOpacity = 1;
        textField.layer.shadowRadius = 5;
        textField.layer.shadowColor = UIColor(displayP3Red: 0.4, green: 0.2, blue: 0.1, alpha: 0.2).cgColor
        textField.layer.shadowOffset = CGSize(width: -5.0, height: 10.0)
        
        
//        textField.layer.cornerRadius = 15.0
//        textField.clipsToBounds = true
//        textField.layer.cornerRadius = textField.heightAnchor(
//        textField.layer.borderWidth = 1
//        textField.layer.borderColor = UIColor.gray.cgColor
        
    }
    
    func shadow(UITextView: UITextView) {
        UITextView.layer.shadowOpacity = 1;
        UITextView.layer.shadowRadius = 5;
        UITextView.layer.shadowColor = UIColor(displayP3Red: 0.4, green: 0.2, blue: 0.1, alpha: 0.2).cgColor
        UITextView.layer.shadowOffset = CGSize(width: -5.0, height: 10.0)
        
        
//        textField.layer.cornerRadius = 15.0
//        textField.clipsToBounds = true
//        textField.layer.cornerRadius = textField.heightAnchor(
//        textField.layer.borderWidth = 1
//        textField.layer.borderColor = UIColor.gray.cgColor
        
    }
    
    func shadow(UIView: UIView) {
        UIView.layer.shadowOpacity = 1;
        UIView.layer.shadowRadius = 5;
        UIView.layer.shadowColor = UIColor(displayP3Red: 0.4, green: 0.2, blue: 0.1, alpha: 0.2).cgColor
        UIView.layer.shadowOffset = CGSize(width: -5.0, height: 10.0)
    }

}

