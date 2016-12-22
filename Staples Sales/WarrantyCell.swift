//
//  WarrantyCell.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-21.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit

// MARK: - WarrantyCellDelegate
// Create a protocol so classes that conform can be updated with methods
protocol WarrantyCellDelegate {
    func priceButtonTapped(cell: WarrantyCell)
    func priceButtonUndo(cell: WarrantyCell)
}

// MARK: - WarrantyCell
class WarrantyCell: UITableViewCell {
    
    // Create a variable for an optional delegate to our protocol
    var delegate: WarrantyCellDelegate?
    var priceAdded = false
    
    // Reference outlets for each cell
    @IBOutlet weak var planTypeLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    // ==========================================
    // ==========================================
    @IBAction func warrantySelected(sender: AnyObject) {
        
        // Determine which action to take when price is tapped
        if !priceAdded {
            
            // Let delegate handle protocol method
            delegate?.priceButtonTapped(cell: self)
            priceAdded = true
        } else {
            
            delegate?.priceButtonUndo(cell: self)
            priceAdded = false
        }
    }
}
