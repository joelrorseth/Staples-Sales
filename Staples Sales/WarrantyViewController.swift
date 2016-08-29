//
//  WarrantyViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-21.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - WarrantyViewController
class WarrantyViewController: UITableViewController, WarrantyCellDelegate {
    
    var managedContext: NSManagedObjectContext!
    
    // Hold the applicable warranties
    var warrantyOptions = [Warranty]()
    var selectedRows = [Int]()
    let types = ["Repair", "Replacement", "Accidental", "AppleCare"]
    
    var warrantiesTotal: Double = 0.00 {
        didSet {
            if warrantiesTotal != 0.00 {
                UIView.animateWithDuration(0.4, animations: {
                    self.title = "$\(self.inputPriceString) + \(self.priceFormatter.stringFromNumber(self.warrantiesTotal)!)"
                })
            } else {
                UIView.animateWithDuration(0.4, animations: {
                    self.title = "Subtotal: $\(self.inputPriceString)"
                })
            }
        }
    }
    
    lazy var priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()
    
    // Variables concerning information about chosen product
    var inputPrice: Double!
    var inputPriceString: String!
    var inputCategory: String!
    
    // Outlet to footer view, a placeholder to make table view appear to end
    @IBOutlet weak var footerView: UIView!
    
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup table view
        tableView.allowsSelection = false
        tableView.contentInset.top = 20
        tableView.backgroundColor = UIColor(red: 231/255, green: 231/255, blue: 231/255, alpha: 1.0)
        self.footerView = UIView()
        
        self.title = "Subtotal: $\(self.inputPriceString)"
        
        loadJSON()
    }
    
    
    // MARK: Table View
    // ==========================================
    // ==========================================
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return warrantyOptions.count
    }
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }

    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // IMPORTANT: Dequeue a WarrantyCell, set the WarrantyCell's delegate
        self.tableView.registerNib(UINib(nibName: "WarrantyCell", bundle: nil), forCellReuseIdentifier: "WarrantyCell")
        let cell = tableView.dequeueReusableCellWithIdentifier("WarrantyCell", forIndexPath: indexPath) as! WarrantyCell
        cell.delegate = self
        
        // Configure the custom cell using appropriate warranty
        cell.planTypeLabel.text = "\(warrantyOptions[indexPath.row].type) Plan"
        cell.detailLabel.text = "\(warrantyOptions[indexPath.row].period) Year"
        
        // Set the price button to reflect warranty price
        let priceText = priceFormatter.stringFromNumber(warrantyOptions[indexPath.row].price)
        cell.priceButton.setTitle(priceText, forState: .Normal)
        cell.priceButton.layer.cornerRadius = 3.3
        
        return cell
    }
    
    
    // MARK: JSON Handling
    // ==========================================
    // ==========================================
    func loadJSON() {
        
        // Get the url and create an NSData object with it
        let url = NSBundle.mainBundle().URLForResource("warranties", withExtension: "json")
        if let data = NSData(contentsOfURL: url!) {
            
            do {
                let object = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                
                // Cast the JSON object to dictionary
                if let dictionary = object as? [String: AnyObject] {
                    parseJSON(dictionary)
                }
                
            } catch {
                print("# Error: \(error)")
            }
        }
    }
    
    // ==========================================
    // ==========================================
    func parseJSON(object: [String: AnyObject]) {
        
        for type in types {
            
            let plans = object[type] as? [[String: AnyObject]]
            
            for plan in plans! {
                
                // Extract neccessary information to check
                let low = plan["low"] as! Double
                let high = plan["high"] as! Double
                let category = plan["category"] as! String

                // Find the warranties that are applicable based on price and category
                if (low <= inputPrice && high >= inputPrice) {
                    if (category == inputCategory) {
                        
                        // Extract relevevant data from json to piece together Warranty object
                        let pr = plan["price"] as! Double
                        let pd = plan["period"] as! Int
                        let sku = plan["sku"] as! Int
                        
                        let cat = Warranty.ProductType(rawValue: category)
                        let plan = Warranty.PlanType(rawValue: type)
                        
                        // Add to current warranties!
                        let current = Warranty(type: plan!, price: pr, period: pd, sku: sku, category: cat!)
                        warrantyOptions.append(current)
                        
                    }
                }
                
                tableView.reloadData()
            }
        }
    }
    
    // MARK: WarrantyCellDelegate
    // ==========================================
    // ==========================================
    func priceButtonTapped(cell: WarrantyCell) {
        
        // Update warranty total, remove this index from selected list
        let path = tableView.indexPathForCell(cell)
        
        warrantiesTotal += warrantyOptions[(path?.row)!].price
        selectedRows.append((path?.row)!)
        
        // Animate selection
        UIView.animateWithDuration(0.5, animations: {
            cell.priceButton.backgroundColor = UIColor.grayColor()
        })
    }
    
    // ==========================================
    // ==========================================
    func priceButtonUndo(cell: WarrantyCell) {
        
        // Get the index in selectedRows of the previosuly selected row
        let deselectedPath = tableView.indexPathForCell(cell)
        let index = selectedRows.indexOf(deselectedPath!.row)
        
        // Delete the selected row from selected rows
        selectedRows.removeAtIndex(index!)
        
        //  Update warranty total
        if selectedRows.isEmpty {
            warrantiesTotal = 0.00
        } else {
            warrantiesTotal -= warrantyOptions[(deselectedPath?.row)!].price
        }
        
        UIView.animateWithDuration(0.5, animations: {
            cell.priceButton.backgroundColor = UIColor.darkGrayColor()
        })
    }
}