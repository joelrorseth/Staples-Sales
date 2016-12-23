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
    let defaults = UserDefaults.standard
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        
        return formatter
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
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
        self.subtotalLabel.addBottomBorderWithColor(color: UIColor.gray, width: 0.7)
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
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
        let tax = (Double(defaults.integer(forKey: "Tax")) / 100) + 1.00
        total *= tax
        total = Double(round(100 * total)/100)
        
        // Update labels
        self.subtotalLabel.text = "Subtotal: \(priceFormatter.string(from: NSNumber(value: subtotal))!)"
        self.totalLabel.text = "Total: \(priceFormatter.string(from: NSNumber(value: total))!)"
    }
    
    // ==========================================
    // Use this opportunity to create sale object
    // ==========================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Create the sale object in Core Data
        let saleEntity = NSEntityDescription.entity(forEntityName: "Sale", in: managedContext)
        let sale = Sale(entity: saleEntity!, insertInto: managedContext)
        
        
        // Assign sale properties, formatted string date for grouping / sorting sales
        sale.dateGrouping = dateFormatter.string(from: NSDate() as Date)
        sale.date = NSDate()
        sale.total = total as NSNumber
        
        // Obtain mutable copy of items property to add everything to sale
        let itemsSet = sale.items!.mutableCopy() as! NSMutableOrderedSet
        
        
        // Add Item object to the Sale objects items property
        for item in saleItems {
            itemsSet.add(item)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return saleItems.count
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = summaryTableView.dequeueReusableCell(withIdentifier: "SummaryCell", for: indexPath as IndexPath) as! SummaryCell
        let item = saleItems[indexPath.row]
        
        // Use priceFormatter to display prices in cell
        cell.itemLabel.text = item.name
        cell.itemPrice.text = priceFormatter.string(from: item.price!)
        
        if (saleItems[indexPath.row].sku! == 0.00) {
            cell.itemSKU.text = "000000"
        } else {
            cell.itemSKU.text = "\(item.sku!)"
        }
        
        return cell
    }
    
    // ==========================================
    // ==========================================
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Ask delegate (tech view controller) to delete 'item' through this method
            let item = saleItems[indexPath.row]
            delegate?.itemDeletedFromSale(item: item)
            
            // Remove from the local saleItems array
            saleItems.remove(at: indexPath.row)
            
            // Let the table view delete its row
            summaryTableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            
            // Update totals
            updateTotals()
            
            // If no more items after item removal, exit empty summary screen
            if (saleItems.isEmpty) {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // ==========================================
    // ==========================================
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

