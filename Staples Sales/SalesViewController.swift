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
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, h:mm a"
        //formatter.dateStyle = .ShortStyle
        //formatter.timeStyle = .MediumStyle
        return formatter
    }()
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        
        return formatter
    }()
    
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    var managedContext: NSManagedObjectContext!
    
    // MARK: View methods
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.sectionIndexTrackingBackgroundColor = UIColor.yellow
        
        // Create fetch request and sort descriptor to sort by date
        let salesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Sale")
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
        let sale = fetchedResultsController.object(at: indexPath as IndexPath) as! Sale
        //let itemsSet = sale.items!.mutableCopy() as! NSMutableOrderedSet
        
        cell.titleLabel.text = "\(dateFormatter.string(from: sale.date! as Date))"
        cell.subtitleLabel.text = "\(sale.items!.count) items"
        cell.priceLabel.text = priceFormatter.string(from: sale.total!)
    }
    
    
    // MARK: Table view delegation
    // ==========================================
    // ==========================================
    override func numberOfSections(in: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    

    // ==========================================
    // ==========================================
    override func tableView(_ : UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Based on how fetched results controller sectioned results, determine # of rows in section
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "saleCell", for: indexPath as IndexPath) as! SaleCell
        
        configureCell(cell: cell, indexPath: indexPath as NSIndexPath)
        return cell
    }
    
    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // Extract section name from section array (at this passed section)
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }

    // ==========================================
    // ==========================================
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // ==========================================
    // Override to support editing the table view
    // ==========================================
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            
            // Grab sale at this index path, remove from context
            let saleToRemove = fetchedResultsController.object(at: indexPath) as! Sale
            
            for itemToRemove in saleToRemove.items! {
                print("- Removed an Item object from context")
                managedContext.delete(itemToRemove as! Item)
            }
            
            managedContext.delete(saleToRemove)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "showSaleDetail" {
            
            // Override back button that displays in detail screen
            let backItem = UIBarButtonItem()
            backItem.title = "Sales"
            navigationItem.backBarButtonItem = backItem
            
            let sdvc = segue.destination as! SaleDetailViewController
            let cell = sender as? SaleCell
            let path = tableView.indexPath(for: cell!)
            
            // IMPROTANT: Pass Sale object at path to SaleDetailViewController
            sdvc.sale = fetchedResultsController.object(at: path!) as! Sale
            sdvc.title = dateFormatter.stringFromDate(sdvc.sale.date!)
        }
    }
}



// MARK: - NSFetchedResultsControllerDelegate Extension
extension SalesViewController: NSFetchedResultsControllerDelegate {
    
    // ==========================================
    // ==========================================
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    // ==========================================
    // Will run check any time context is saved
    // ==========================================
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
            // Handle different changes to results controller's objects
        case .insert:
            print("NSFetchedResultsControllerDelegate: Object insertion detected")
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: .automatic)
            
        case .delete:
            print("NSFetchedResultsControllerDelegate: Object deletion detected")
            tableView.deleteRows(at: [indexPath! as IndexPath], with: .automatic)
            
        case .update:
            print("NSFetchedResultsControllerDelegate: Object update detected")
            let cell = tableView.cellForRow(at: indexPath! as IndexPath) as! SaleCell
            configureCell(cell: cell, indexPath: indexPath!)
            
        case .move:
            print("FNSFetchedResultsControllerDelegate: Object movement detected")
            tableView.deleteRows(at: [indexPath! as IndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath! as IndexPath], with: .automatic)
        }
    }
    
    // ==========================================
    // Fires when a section is added or deleted
    // ==========================================
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        let indexSet = NSIndexSet(index: sectionIndex)
        
        switch type {
            
        case .insert:
            tableView.insertSections(indexSet as IndexSet, with: .automatic)
            
        case .delete:
            tableView.deleteSections(indexSet as IndexSet, with: .automatic)
            print("- Section deleted")
            
        default:
            break
        }
    }
    
    // ==========================================
    // ==========================================
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
