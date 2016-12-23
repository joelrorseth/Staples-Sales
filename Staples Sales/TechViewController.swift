//
//  TechViewController.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-07-21.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//

import UIKit
import CoreData


// MARK: - TechViewController
class TechViewController: UIViewController {
    
    var managedContext: NSManagedObjectContext!
    
    // Properties
    var runningTotal = 0.00
    var selectedItems = [Item]()
    var categoryPicker = UIPickerView()
    var products = ["Laptop", "Desktop", "iMac", "Tablet", "iPad", "Printer",
                    "Macbook Pro 15\"/17\"", "Macbook Under 15\"", "Mac Mini",
                    "MP3 Player", "Shredder", "Camera", "Landline Phone", "Calculator", "Other"]
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        
        return formatter
    }()
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var summaryTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var attachWarrantyButton: UIButton!
    @IBOutlet weak var checkoutButton: UIButton!
    
    // MARK: View methods
    // ==========================================
    // ==========================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "New Sale"
        
        // Add 'separator' between the buttons
        let color = UIColor.gray
        self.attachWarrantyButton.addBottomBorderWithColor(color: color, width: 0.7)
        
        // Set up picker
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        
        // Set up textfields
        nameTextField.returnKeyType = UIReturnKeyType.done
        categoryTextField.inputView = categoryPicker
        categoryTextField.placeholder = "Printer"
        priceTextField.delegate = self
        nameTextField.delegate = self
        
        // Set up gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TechViewController.dismissKeyboard(gesture:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    // ==========================================
    // ==========================================
    override func viewDidAppear(_ animated: Bool) {
        
        // Recalculate totals every time and update title with price
        updateTotals()
    }
    
    
    // MARK: Segue
    // ==========================================
    // ==========================================
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SelectWarranty" {
            
            // Override the ugly back button that would appear when selecting warranties
            let backItem = UIBarButtonItem()
            backItem.title = "Sale"
            navigationItem.backBarButtonItem = backItem

            // Set Warranty VC to use current price for user info
            let wvc = segue.destination as! WarrantyViewController
            wvc.managedContext = self.managedContext
            
            wvc.inputPrice = (priceTextField.text!.isEmpty) ? 0.00 : Double(priceTextField.text!)!
            wvc.inputCategory = (categoryTextField.text!.isEmpty) ? "Other" : categoryTextField.text!
            
            
            // When there is already items on the sale, show the total with new item on warranty screen
            let addedSubtotal = runningTotal + Double(priceTextField.text!)!
            wvc.inputPriceString = (runningTotal == 0.00) ? (Double(priceTextField.text!)!).format(f: priceTextField.text!) : addedSubtotal.format(f: "\(addedSubtotal)")

        }
        
        if segue.identifier == "ShowSummary" {
            
            // Override the ugly back button that would appear when selecting warranties
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
            
            // If an item has been added last minute without a warranty, add to sale
            // Item must have price AND category specified
            if (priceTextField.text != "" && categoryTextField.text != "") {
                
                // Create and add CURRENT ITEM to persistent store, update running total
                let entityDesc = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)
                let currentItem = Item(entity: entityDesc!, insertInto: managedContext)
                
                
                // Set the price from text field
                currentItem.price = NSDecimalNumber(string: priceTextField.text!)
                
                // Determine the name from our name text field
                if (nameTextField.text!.isEmpty) {
                    currentItem.name = nameTextField.placeholder!
                } else {
                    currentItem.name = nameTextField.text!
                }
                
                print("+ Created Item object onto managed object context.")
                
                // Add item itself to selectedItems and add price to subtotal
                self.selectedItems.append(currentItem)
                runningTotal += Double(priceTextField.text!)!
            }
            
            // Important: Pass along managed context and subtotal to summary view controller
            let svc = segue.destination as! SummaryViewController
            svc.managedContext = self.managedContext
            //svc.subtotal = runningTotal
            
            // IMPORTANT: Set this view controller to be delegate for object deletion protocol
            svc.delegate = self
            
            
            // Important: Pass along ALL selected items to summary view controller
            for item in selectedItems {    
                svc.saleItems.append(item)
            }
            
            
            // Before leaving, take care of updating screen before segueing
            self.title = "Subtotal: \(priceFormatter.string(from: NSNumber(value: runningTotal))!)"
            
            // Reset text fields on this controller
            self.categoryTextField.text = ""
            self.nameTextField.text = ""
            self.priceTextField.text = ""
            self.nameTextField.placeholder = "HP Pavilion"
        
        }
    }
    
    
    // ==========================================
    // Determine whether segue should launch
    // ==========================================
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        // Check if fields are entered to proceed to next step
        if identifier == "SelectWarranty" {
            
            // If nothing is entered to add warranty to, prevent segue
            if (priceTextField.text == "" || categoryTextField.text == "") {
                
                let message = "Please start by specifying the type of item and its price."
                let ac = UIAlertController(title: "Missing Fields", message: message, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
                
                return false
                
            } else {
                // Otherwise, allow
                return true
            }
        }
        
        // Determine if items are present for checkout screen
        if identifier == "ShowSummary" {
            
            // If no price or no category specified...
            if (priceTextField.text == "" || categoryTextField.text == "") {
                
                
                if (selectedItems.isEmpty) {
                    // No items on the sale, nothing to checkout
                    let message = "Please start by specifying the type of item and its price."
                    let ac = UIAlertController(title: "Nothing to Checkout", message: message, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(ac, animated: true, completion: nil)
                    
                    return false
                } else {
                    // Even though fields are empty, there are items on sale so allow checkout
                    return true
                }
                
                
            } else {
                // Price and category filled out, allow segue without warranty
                // This action is handled in prepareForSegue: by creating Item object using price and category
                return true
            }
        }
        
        else {
            return true
        }
        
    }
    
    // ==========================================
    // Exiting warranty screen
    // ==========================================
    @IBAction func exitingWarranties(segue: UIStoryboardSegue) {
        
        let wvc = segue.source as! WarrantyViewController
        
        // If any warranties were selected in warranty menu, create their items
        if wvc.selectedRows.isEmpty {
            print("+ Exited without selecting any warranties")
        } else {
            
            // Create and add EACH WARRANTY to persistent store 
            for row in wvc.selectedRows {
                let selectedWarranty = wvc.warrantyOptions[row]
                
                let entityDesc = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)
                let item = Item(entity: entityDesc!, insertInto: managedContext)
                
                // Set warranty item's properties
                item.name = "\(selectedWarranty.type.rawValue) Plan"
                item.price = NSDecimalNumber(value: selectedWarranty.price!)
                item.sku = selectedWarranty.sku as NSNumber?
                
                print("+ Created Item object onto managed object context.")
                
                // Add selected warranty to our list
                self.selectedItems.append(item)
                
            }
        }
        
        // Create and add CURRENT ITEM to persistent store, update running total
        let entityDesc = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)
        let currentItem = Item(entity: entityDesc!, insertInto: managedContext)
        
        // Set the price from text field
        currentItem.price = NSDecimalNumber(string: priceTextField.text!)
        
        // Determine the name from our name text field
        if (nameTextField.text!.isEmpty) {
            currentItem.name = nameTextField.placeholder!
        } else {
            currentItem.name = nameTextField.text!
        }
        
        print("+ Created Item object onto managed object context.")
        
        // Add item itself to selectedItems and add price to subtotal
        self.selectedItems.append(currentItem)
        runningTotal += Double(priceTextField.text!)!
        
        // Add warranties to subtotal
        runningTotal += wvc.warrantiesTotal
        
        self.title = "Subtotal: \(priceFormatter.string(from: NSNumber(value: runningTotal)))"
        
        // Reset values
        self.categoryTextField.text = ""
        self.nameTextField.text = ""
        self.priceTextField.text = ""
        self.nameTextField.placeholder = "HP Pavilion"
    }
    
    
    // MARK: Additional Methods
    // ==========================================
    // ==========================================
    func dismissKeyboard(gesture: UITapGestureRecognizer) {
        priceTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        
        updateTitles()
    }
    
    // ==========================================
    // ==========================================
    func updateTotals() {
        
        // Reset price
        runningTotal = 0.00
        
        // Recalculate the subtotal using all added items
        for item in selectedItems {
            runningTotal += Double(item.price!)
        }
        
        // Also fix price in title
        updateTitles()
    }
    
    
    // ==========================================
    // ==========================================
    func updateTitles() {
        
        // If price is specified...
        if (!priceTextField.text!.isEmpty) {
            
            // If running total is 0, display just new item price
            if (runningTotal == 0.00) {
                self.title = "Subtotal: $\(priceTextField.text!)"
            } else {
                self.title = "\(priceFormatter.string(from: NSNumber(value: runningTotal))!) + $\(priceTextField.text!)"
            }
            
        } else {
            
            // Price not entered, display running total if it exists
            if (runningTotal != 0.00) {
                self.title = "Subtotal: \(priceFormatter.string(from: NSNumber(value: runningTotal))!)"
            } else {
                self.title = "New Sale"
            }
        }
    }
}



// MARK: - ItemDeletionDelegate Extension
extension TechViewController: ItemDeletionDelegate {
    
    // ==========================================
    // ==========================================
    func itemDeletedFromSale(item: Item) {
        
        let i = selectedItems.index(of: item)
        
        // Remove from selected items
        self.selectedItems.remove(at: i!)
        
        // IMPORTANT: Delete the Item object passed from summary view controller from context
        managedContext.delete(item)
        print("- Deleted Item object from managed object context.")
    }
}



// MARK: - Picker View Delegate Extension
extension TechViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    // ==========================================
    // ==========================================
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    
    // ==========================================
    // ==========================================
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return products.count
    }
    
    // ==========================================
    // ==========================================
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // Show name in corresponding text field, then also put as placeholder in name field
        categoryTextField.text = products[row]
        nameTextField.placeholder = products[row]
    }
    
    // ==========================================
    // ==========================================
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return products[row]
    }
}



// MARK: - Text Field Delegate Extension
extension TechViewController: UITextFieldDelegate {
    
    // ==========================================
    // Decide when to prevent user from typing
    // ==========================================
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (textField == priceTextField) {
            let numParts = textField.text!.components(separatedBy: ".")
            
            // If user adds 2nd decimal when fractional part already exists, deny by returning false
            if (numParts.count > 1 && string == ".")
            {
                return false
            }
                
                // If user enters over 2 numbers...
            else if (numParts.count > 1 && (numParts[1].characters.count >= 2)) {
                
                // If just backspacing, allow editing
                if (string == "") {
                    return true
                    
                    // Otherwise block attempt to add additional decimal places
                } else {
                    return false
                }
            }
            
            return string == "" || (string == "." || Float(string) != nil)
        } else {
            return true
        }
    }
    
    // ==========================================
    // Before editing ends, cleanup prices
    // ==========================================
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if (textField == priceTextField) {
            let numParts = textField.text!.components(separatedBy: ".")
            
            // Add zeros and/or decimal to fix format to xxx.xx
            if (numParts.count == 1) {
                
                // Check to make sure field isnt empty either
                if (textField.text == "") {
                    return
                } else {
                    textField.text = textField.text! + ".00"
                }
                
                
            } else if (numParts[1].characters.count == 1) {
                textField.text = textField.text! + "0"
            } else if (numParts[1].characters.count == 0) {
                textField.text = textField.text! + "00"
            }
            
            updateTitles()
        }
    }
    
    // ==========================================
    // When called, add Done button to number pad
    // ==========================================
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        // Add done button to numeric pad keyboard
        let toolbarDone = UIToolbar.init()
        toolbarDone.sizeToFit()
        let barBtnDone = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: textField, action: #selector(UITextField.resignFirstResponder))
        
        toolbarDone.items = [barBtnDone]
        priceTextField.inputAccessoryView = toolbarDone
        
        return true
        
    }
    
    // ==========================================
    // Handles action when return button pressed
    // ==========================================
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Get rid of the keyboard entirely
        self.nameTextField.resignFirstResponder()
        
        return false
    }
}



// MARK: - Double extension
extension Double {
    
    // ==========================================
    // ==========================================
    func format(f: String) -> String {
        return NSString(format: "%.2f", self) as String
    }

}
