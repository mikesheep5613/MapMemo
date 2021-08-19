//
//  UIStackView+Extension.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/8/19.
//

import Foundation
import UIKit
extension UIStackView {
    
    public func addSeparators(at positions: [Int], color: UIColor) {
        for position in positions {
            let separator = UIView()
            separator.backgroundColor = color
            
            insertArrangedSubview(separator, at: position)
            switch self.axis {
            case .horizontal:
                separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
                separator.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1).isActive = true
            case .vertical:
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                separator.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
            @unknown default:
                fatalError("Unknown UIStackView axis value.")
            }
        }
    }
}
