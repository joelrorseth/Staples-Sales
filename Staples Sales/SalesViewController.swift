//
//  SalesViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-28.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - SalesViewController
class SalesViewController: UITableViewController, UISearchBarDelegate {
    
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, h:mm a"
        //formatter.dateStyle = .ShortStyle
        //formatter.timeStyle = .MediumStyle
        return formatter
    }()
    
    lazy var priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        
        return formatter
    }()
    
    
    var fetchedResultsController : NSFetchedResultsController!
    var managedContext: NSManagedObjectContext!
    
    // MARK: View methods
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.sectionIndexTrackingBackgroundColor = UIColor.yellowColor()
        
        // Create fetch request and sort descriptor to sort by date
        let salesFetch = NSFetchRequest(entityName: "Sale")
        let dateSort = NSSortDescriptor(key: "dateGrouping", ascending: false)
        salesFetch.sortDescriptors = [dateSort]
        
        // Instantiate the fetched results controller
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: salesFetch,
            managedObjectContext: managedContext,
            sectionNameKeyPath: "dateGrouping",
            cacheName: nil)
        
        // Assign the fetchedresultscontroller's delegate
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    
    // ==========================================
    // ==========================================
    func configureCell(cell: SaleCell, indexPath: NSIndexPath) {
        
        // Use index path from "cellForRow..." to look up Sale object to display
        let sale = fetchedResultsController.objectAtIndexPath(indexPath) as! Sale
        //let itemsSet = sale.items!.mutableCopy() as! NSMutableOrderedSet
        
        cell.titleLabel.text = "\(dateFormatter.stringFromDate(sale.date!))"
        cell.subtitleLabel.text = "\(sale.items!.count) items"
        cell.priceLabel.text = priceFormatter.stringFromNumber(sale.total!)
    }
    
    
    // MARK: Table view delegation
    // ==========================================
    // ==========================================
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Based on how fetched results controller sectioned results, determine # of rows in section
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("saleCell", forIndexPath: indexPath) as! SaleCell
        
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // Extract section name from section array (at this passed section)
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    // ==========================================
    // ==========================================
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // ==========================================
    // Override to support editing the table view
    // ==========================================
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            
            // Grab sale at this index path, remove from context
            let saleToRemove = fetchedResultsController.objectAtIndexPath(indexPath) as! Sale
            
            for itemToRemove in saleToRemove.items! {
                print("- Removed an Item object from context")
                managedContext.deleteObject(itemToRemove as! Item)
            }
            
            managedContext.deleteObject(saleToRemove)
            print("- Removed a Sale object from context")
            
            // Save the context now that row has been deleted
            do {
                try managedContext.save()
                print("=> Persistent store was saved")
            } catch let error as NSError {
                print("Error: Could not save: \(error)")
            }
        }
    }
    
    
    // MARK: Navigation
    // ==========================================
    // ==========================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showSaleDetail" {
            
            // Override back button that displays in detail screen
            let backItem = UIBarButtonItem()
            backItem.title = "Sales"
            navigationItem.backBarButtonItem = backItem
            
            let sdvc = segue.destinationViewController as! SaleDetailViewController
            let cell = sender as? SaleCell
            let path = tableView.indexPathForCell(cell!)
            
            // IMPROTANT: Pass Sale object at path to SaleDetailViewController
            sdvc.sale = fetchedResultsController.objectAtIndexPath(path!) as! Sale
            sdvc.title = dateFormatter.stringFromDate(sdvc.sale.date!)
        }
    }
}



// MARK: - NSFetchedResultsControllerDelegate Extension
extension SalesViewController: NSFetchedResultsControllerDelegate {
    
    // ==========================================
    // ==========================================
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    // ==========================================
    // Will run check any time context is saved
    // ==========================================
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
            // Handle different changes to results controller's objects
        case .Insert:
            print("NSFetchedResultsControllerDelegate: Object insertion detected")
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            
        case .Delete:
            print("NSFetchedResultsControllerDelegate: Object deletion detected")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            
        case .Update:
            print("NSFetchedResultsControllerDelegate: Object update detected")
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! SaleCell
            configureCell(cell, indexPath: indexPath!)
            
        case .Move:
            print("FNSFetchedResultsControllerDelegate: Object movement detected")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    // ==========================================
    // Fires when a section is added or deleted
    // ==========================================
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        let indexSet = NSIndexSet(index: sectionIndex)
        
        switch type {
            
        case .Insert:
            tableView.insertSections(indexSet, withRowAnimation: .Automatic)
            
        case .Delete:
            tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
            print("- Section deleted")
            
        default:
            break
        }
    }
    
    // ==========================================
    // ==========================================
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
