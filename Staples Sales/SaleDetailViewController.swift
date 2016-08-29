//
//  SaleDetailViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-08-07.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit


// MARK: - SaleDetailViewController
class SaleDetailViewController: UIViewController  {
    
    // Property for the sale being displayed
    var sale: Sale!

    // Add computed properties to hold and update totals
    var saleSubtotal: Double = 0.00 {
        didSet {
            self.subtotalLabel.text = "Subtotal: \(priceFormatter.stringFromNumber(saleSubtotal)!)"
        }
    }
    
    var saleTotal: Double = 0.00 {
        didSet {
            self.totalLabel.text = "Total: \(priceFormatter.stringFromNumber(saleTotal)!)"
        }
    }
    
    lazy var priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()

    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        summaryTableView.dataSource = self
        summaryTableView.delegate = self
        
        // Add 'separator' between the buttons
        self.subtotalLabel.addBottomBorderWithColor(UIColor.grayColor(), width: 0.7)
        
        self.summaryTableView.allowsSelection = false
        
        // Update the totalLabel to hold sale total
        saleTotal = Double(sale.total!)
    }
}

// MARK: - Table View Delegation Extension
extension SaleDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    // ==========================================
    // ==========================================
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = summaryTableView.dequeueReusableCellWithIdentifier("SummaryCell", forIndexPath: indexPath) as! SummaryCell
        let item = sale.items![indexPath.row] as! Item

        cell.itemLabel.text = "\(item.name!)"
        cell.itemPrice.text = priceFormatter.stringFromNumber(item.price!)
        
        if (item.sku == 0.00) {
            cell.itemSKU.text = "000000"
        } else {
            cell.itemSKU.text = "\(item.sku!)"
        }
        
        saleSubtotal += Double(item.price!)        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sale.items!.count
    }
}
