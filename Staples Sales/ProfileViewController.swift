//
//  ProfileViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-08-21.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - ProfileViewController
class ProfileViewController: UITableViewController {

    var managedContext: NSManagedObjectContext!
    var psc: NSPersistentStoreCoordinator!
    
    var pendingChanges = false
    var salesTotal = 0.00
    var warrantiesTotal = 0.00
    var dailySalesTotal = 0.00
    var dailyWarrantiesTotal = 0.00
    
    // Hold and update tax value and label
    var taxValue = 13 {
        didSet {
            self.taxLabel.text = "\(self.taxValue)%"
        }
    }
    
    // Hold and update name value and label
    var userName = "Your Name Here" {
        didSet {
            self.nameLabel.text = userName
        }
    }
    
    lazy var priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()
    
    @IBOutlet weak var resetDatabaseSwitch: UISwitch!
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var salesTodayLabel: UILabel!
    @IBOutlet weak var totalSalesLabel: UILabel!
    @IBOutlet weak var warrantiesTodayLabel: UILabel!
    @IBOutlet weak var totalWarrantiesLabel: UILabel!
    
    // MARK: View methods
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add button in nav bar to save settings
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(saveSettings))
        
        retrieveSettings()
        fetchSalesAndUpdate()
    }

    
    // MARK: Settings changes
    // ==========================================
    // ==========================================
    @IBAction func editName(sender: AnyObject) {
        
        // Alert will prompt user for their name
        let ac = UIAlertController(title: "Enter Your Name", message: nil, preferredStyle: .Alert)
        ac.addTextFieldWithConfigurationHandler(nil)
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { [ac] (action: UIAlertAction!) in
            
            // Store name as username locally
            let answer = ac.textFields![0] 
            self.userName = answer.text!
        }
        
        ac.addAction(submitAction)
        presentViewController(ac, animated: true, completion: nil)
        
        pendingChanges = true
    }
    
    // ==========================================
    // ==========================================
    @IBAction func taxValueChanged(sender: AnyObject) {
        
        let slider = sender as! UISlider
        
        taxValue = Int(slider.value)
        
        // Reflect a state of change in settings
        pendingChanges = true
    }
    
    // ==========================================
    // ==========================================
    @IBAction func resetSwitchTriggered(sender: AnyObject) {
        
        let msg = "Your sales record will be permanantly erased. This can not be undone."
        let ac = UIAlertController(title: "Confirm Reset", message: msg, preferredStyle: .Alert)
        
        // Alert to confirm deletion...
        ac.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction!) in
            
            // Create a batch delete request using NSFetchRequest for Sale and Item objects
            let deleteRequestSale = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Sale"))
            let deleteRequestItem = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "Item"))
            
            // Attempt to execute delete request for Sale objects
            do {
                try self.psc.executeRequest(deleteRequestSale, withContext: self.managedContext)
            } catch let error as NSError {
                print("Error: Could not execute batch delete request for Sale objects.\n\(error.localizedDescription)")
            }
            
            // Attempty to execute delete request for all Item objects
            do {
                try self.psc.executeRequest(deleteRequestItem, withContext: self.managedContext)
            } catch let error as NSError {
                print("Error: Could not execute batch delete request for Item objects.\n\(error.localizedDescription)")
            }
            
            // Reset switch and exit settings screen
            print("% Persistent store was wiped.")
            self.resetDatabaseSwitch.setOn(false, animated: true)
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        
        // Cancel deletion...
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            print("% Reset was cancelled.")
            self.resetDatabaseSwitch.setOn(false, animated: true)
        }))
        
        // Present popup
        self.presentViewController(ac, animated: true, completion: nil)
    }
    
    
    // MARK: Settings Management
    // ==========================================
    // ==========================================
    func saveSettings() {
        
        if !pendingChanges {
            print("% No changes to be saved")
            super.navigationController?.popViewControllerAnimated(true)
            return
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setInteger(taxValue, forKey: "Tax")
        defaults.setObject(userName, forKey: "Name")
        print("% Settings were saved")
        
        // No more pending changes
        pendingChanges = false
        
        // Return to Home Menu after settings are saved
        super.navigationController?.popViewControllerAnimated(true)
    }
    
    // ==========================================
    // ==========================================
    func retrieveSettings() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // Obtain name and tax, store into local variables
        userName = defaults.objectForKey("Name") as? String ?? "Your Name Here"
        taxValue = defaults.integerForKey("Tax")
        print("% Settings were retrieved")
    }
    
    // ==========================================
    // ==========================================
    func fetchSalesAndUpdate() {
        
        // Fresh numbers
        salesTotal = 0.00
        warrantiesTotal = 0.00
        dailySalesTotal = 0.00
        dailyWarrantiesTotal = 0.00
        
        let fetch = NSFetchRequest(entityName: "Sale")
        
        do {
            
            // Fetch all sales ever recorded
            let results = try managedContext.executeFetchRequest(fetch) as! [Sale]
            
            for sale in results {
                
                // If sale was made today, update daily totals
                // ++++++++++++++++++++++++++++++++++++++++++++++++
                if (NSCalendar.currentCalendar().isDate(NSDate(), inSameDayAsDate: sale.date!)) {
                    
                    dailySalesTotal += Double(sale.total!)
                    
                    // Check each item in this sale, add any warranties to daily warranty total
                    for saleItem in sale.items! {
                        if (saleItem.name?.containsString("Plan") == true) {
                            
                            let warrantyPlan = saleItem as! Item
                            dailyWarrantiesTotal += Double(warrantyPlan.price!)
                        }
                    }
                }
                
                
                // Regardless, must update the overall totals
                // ++++++++++++++++++++++++++++++++++++++++++++++++
                
                // Add the sale to the overall sales total
                salesTotal += Double(sale.total!)
                
                // Add all attached warranties in the sale to the overall warranty total
                for saleItem in sale.items! {
                    
                    
                    if (saleItem.name?.containsString("Plan") == true) {
                        
                        let warrantyPlan = saleItem as! Item
                        warrantiesTotal += Double(warrantyPlan.price!)
                    }
                }
            }
            
            
        } catch let error as NSError {
            print("Error retrieving sales from managed context. \(error.localizedDescription)")
        }
        
        // Now that fetching has finished, update UI
        totalSalesLabel.text = priceFormatter.stringFromNumber(salesTotal)
        totalWarrantiesLabel.text = priceFormatter.stringFromNumber(warrantiesTotal)
        warrantiesTodayLabel.text = priceFormatter.stringFromNumber(dailyWarrantiesTotal)
        salesTodayLabel.text = priceFormatter.stringFromNumber(dailySalesTotal)
    }
}

