//
//  SummaryViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-23.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - ItemDeletionDelegate
protocol ItemDeletionDelegate {
    func itemDeletedFromSale(item: Item)
}


// MARK: - SummaryViewController
class SummaryViewController: UIViewController {
    
    var total = 0.00
    var subtotal = 0.0
    var saleItems = [Item]()
    
    // Create delegate property for ItemDeletionDelegate
    var delegate: ItemDeletionDelegate?
    var managedContext: NSManagedObjectContext!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy var priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()
    
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        return formatter
    }()
    
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    // MARK: View methods
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTotals()

        summaryTableView.delegate = self
        summaryTableView.dataSource = self
        summaryTableView.allowsSelection = false
        
        // Add 'separator' between the buttons
        self.subtotalLabel.addBottomBorderWithColor(UIColor.grayColor(), width: 0.7)
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(animated: Bool) {
        updateTotals()
    }
    
    // MARK: Additional methods
    // ==========================================
    // ==========================================
    func updateTotals() {
        
        // Reset subtotal
        subtotal = 0.00
        
        // Recalculate subtotal
        for item in saleItems {
            subtotal += Double(item.price!)
        }
        
        // Calculate total after tax, round to two decimal places
        total = subtotal
        let tax = (Double(defaults.integerForKey("Tax")) / 100) + 1.00
        total *= tax
        total = Double(round(100 * total)/100)
        
        // Update labels
        self.subtotalLabel.text = "Subtotal: \(priceFormatter.stringFromNumber(subtotal)!)"
        self.totalLabel.text = "Total: \(priceFormatter.stringFromNumber(total)!)"
    }
    
    // ==========================================
    // Use this opportunity to create sale object
    // ==========================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Create the sale object in Core Data
        let saleEntity = NSEntityDescription.entityForName("Sale", inManagedObjectContext: managedContext)
        let sale = Sale(entity: saleEntity!, insertIntoManagedObjectContext: managedContext)
        
        
        // Assign sale properties, formatted string date for grouping / sorting sales
        sale.dateGrouping = dateFormatter.stringFromDate(NSDate())
        sale.date = NSDate()
        sale.total = total as NSNumber
        
        // Obtain mutable copy of items property to add everything to sale
        let itemsSet = sale.items!.mutableCopy() as! NSMutableOrderedSet
        
        
        // Add Item object to the Sale objects items property
        for item in saleItems {
            itemsSet.addObject(item)
            print("=> Item added to sale: \(item.name!), $\(item.price!)")
        }
        
        // IMPORTANT: Save ordered set copy back to this Sale object's [Item]
        sale.items = itemsSet.copy() as? NSOrderedSet
        
        print("=> Sale finalized with \(itemsSet.count) items")
    }
}


// MARK: - Table View Delegation Extension
extension SummaryViewController: UITableViewDelegate, UITableViewDataSource {
    
    // ==========================================
    // ==========================================
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return saleItems.count
    }
    
    // ==========================================
    // ==========================================
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = summaryTableView.dequeueReusableCellWithIdentifier("SummaryCell", forIndexPath: indexPath) as! SummaryCell
        let item = saleItems[indexPath.row]
        
        // Use priceFormatter to display prices in cell
        cell.itemLabel.text = item.name
        cell.itemPrice.text = priceFormatter.stringFromNumber(item.price!)
        
        if (saleItems[indexPath.row].sku! == 0.00) {
            cell.itemSKU.text = "000000"
        } else {
            cell.itemSKU.text = "\(item.sku!)"
        }
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            // Ask delegate (tech view controller) to delete 'item' through this method
            let item = saleItems[indexPath.row]
            delegate?.itemDeletedFromSale(item)
            
            // Remove from the local saleItems array
            saleItems.removeAtIndex(indexPath.row)
            
            // Let the table view delete its row
            summaryTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            // Update totals
            updateTotals()
            
            // If no more items after item removal, exit empty summary screen
            if (saleItems.isEmpty) {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    // ==========================================
    // ==========================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}

