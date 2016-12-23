//
//  HomeViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-29.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - HomeViewController
class HomeViewController: UIViewController {
    
    var managedContext: NSManagedObjectContext!
    var psc: NSPersistentStoreCoordinator!
    
    var saveRequired = false
    
    @IBOutlet weak var newSaleButton: UIButton!
    @IBOutlet weak var mySalesButton: UIButton!
    @IBOutlet weak var myProfileButton: UIButton!
    
    // MARK: View
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Upon app startup, provide 13% tax default if settings havent been modified
        let defaults = UserDefaults.standard
        if (defaults.integer(forKey: "Tax") == 0) {
            defaults.set(13, forKey: "Tax")
        }
        
        // The properties of the separators we will add to buttons
        let color = UIColor.lightGray
        let width: CGFloat = 0.7
        
        // Call extension functions to add a workaround 'separator' in between buttons
        newSaleButton.addTopBorderWithColor(color: color, width: width)
        mySalesButton.addTopBorderWithColor(color: color, width: width)
        myProfileButton.addTopBorderWithColor(color: color, width: width)
        
        setupNavigationBar()
    }
    
    // ==========================================
    // Check for lost Item objects not attached
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        var results = [Item]()
        let request: NSFetchRequest<Item>
        
        // Allow for backwards compatible fetch request
        if #available(iOS 10.0, OSX 10.12, *) {
            request = Item.fetchRequest() as! NSFetchRequest<Item>
        } else {
            request = NSFetchRequest(entityName: "Item")
        }
        
        // Find all Item objects
        do {
            results = try managedContext.fetch(request)
        } catch let error as NSError {
            print(error)
        }
        
        
        // Check each Item, if not attached to a Sale, delete from memory!
        for item in results {
            if (item.sale == nil) {
                print("=> \(item.name!) isn't attached to a sale")
                managedContext.delete(item)
                
                saveRequired = true
                print("=> Item deleted")
            }
        }
        
        
        // Make sure to save context once rogue Items are deleted
        if saveRequired {
            do {
                try managedContext.save()
                saveRequired = false
                print("=> Persistent store was saved.")
                
            } catch let error as NSError {
                print("Could not save: \(error)")
            }
        }
    }
    
    // ==========================================
    // ==========================================
    func setupNavigationBar() {
        
        // Setup nav bar itself
        let navBar = self.navigationController?.navigationBar
        navBar?.barStyle = UIBarStyle.black
        navBar?.tintColor = UIColor(red: 192, green: 208, blue: 0, alpha: 1)
        navBar?.isTranslucent = true
        
        // Put logo in nav bar
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 34, height: 26))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "staples.png")
        imageView.image = image
        navigationItem.titleView = imageView
        
    }
    
    // MARK: IBAction
    // ==========================================
    // Exited summary screen using "Done"
    // ==========================================
    @IBAction func didFinalizeOrder(segue: UIStoryboardSegue) {
        
        // Only now that order is finalized, save to persistent store
        do {
            try managedContext.save()
            print("=> Saved to persistent store.")
        } catch let error as NSError {
            print("Could not save: \(error)")
        }
    }
    
    
    // MARK: Navigation
    // ==========================================
    // ==========================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "createSale" {
            
            let tvc = segue.destination as! TechViewController
            tvc.managedContext = self.managedContext
        }
        
        if segue.identifier == "showSales" {
            
            let svc = segue.destination as! SalesViewController
            svc.managedContext = self.managedContext
        }
        
        if segue.identifier == "showProfile" {
            
            // Must pass persistent store coordinator along, used for batch delete request
            let pvc = segue.destination as! ProfileViewController
            pvc.managedContext = self.managedContext
            pvc.psc = self.psc
        }
    }    
}

// MARK: - UIView Extension
extension UIView {
    
    // ==========================================
    // ==========================================
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
        
        // Modified to also call other methods, fill sides
        self.addLeftBorderWithColor(color: color, width: width * 2)
        self.addRightBorderWithColor(color: color, width: width )
    }
    
    // ==========================================
    // ==========================================
    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    
    // ==========================================
    // ==========================================
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    // ==========================================
    // ==========================================
    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
}
