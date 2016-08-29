//
//  Warranty.swift
//  Staples Sales
//
//  Warranty represents a single warranty plan 
//
//  Created by Joel Rorseth on 2016-07-21.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit

class Warranty {
    
    enum ProductType: String {
        case Laptop = "Laptop"
        case Desktop = "Desktop" 
        case HomePhone = "Landline Phone"
        case Camera = "Camera"
        case MP3 = "MP3 Player"
        case Printer = "Printer"
        case Shredder = "Shredder"
        case Tablet = "Tablet"
        case Calculator = "Calculator"
        case Other = "Other"
        case MacbookPro1517 = "Macbook Pro 15\"/17\""
        case MacbookUnder15 = "Macbook Under 15\""
        case iMac = "iMac"
        case iPad = "iPad"
        case MacMini = "Mac Mini"
        //case eReader = "eReader"
        //case Server = "Server"
        
        init?(raw: String) {
            self.init(rawValue: raw)
        }   
    }
    
    enum PlanType: String {
        case Repair = "Repair"
        case Replacement = "Replacement"
        case Accidental = "Accidental"
        case AppleCare = "AppleCare"
        
        init?(raw: String) {
            print("PlanType init called")
            self.init(rawValue: raw)
        }
    }
    
    var type: PlanType!
    var category: ProductType!
    var period: Int
    var sku: Int?
    var image: UIImage? = nil
    var price: Double!
    
    // ======================================
    // ======================================
    init(type: PlanType, price: Double, period: Int, sku: Int, category: ProductType = .Other) {
        
        self.type = type
        self.price = price
        self.period = period
        self.sku = sku
        self.category = category
        self.image = UIImage(named: "\(self.category.rawValue)")
    }
}