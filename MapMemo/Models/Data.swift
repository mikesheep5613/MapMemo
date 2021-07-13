//
//  Data.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/6.
//

import Foundation
class ItemListHelper {
    
    private let itemsJson = """
        [
            {
                "date":"2016-07-27",
                "title":"家",
                "text":"永遠的避風港",
                "image":"F85B004A-3D1C-4F5A-A2CC-4911A1F549C4_1_105_c.jpeg",
                "latitude":24.132409,
                "longitude":120.701480,
                "type":"other"
            },
            {
                "date":"2012-09-07",
                "title":"士林",
                "text":"台北漂泊所住的地方",
                "image":"1DD0D4B5-62D2-4728-829F-9F9B9AC4B35A_1_105_c.jpeg",
                "latitude":25.090222,
                "longitude":121.523486,
                "type":"mountain"
            },
            {
                "date":"2020-10-16",
                "title":"南田",
                "text":"良好的海邊營地，無敵星空海景",
                "image":"o552c6aa9090bab0ba7c372087f873b47_4620693218540018323_210707.jpg",
                "latitude":22.279205159143846,
                "longitude":120.896236455391,
                "type":"camping"
            }
        ]
        """.data(using: .utf8)!
    
    
}
