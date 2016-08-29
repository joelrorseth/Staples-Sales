//
//  Sale+CoreDataProperties.swift
//  Staples Sales
//
//  Created by Joel Rorseth on 2016-08-24.
//  Copyright © 2016 Joel Rorseth. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Sale {

    @NSManaged var date: NSDate?
    @NSManaged var total: NSNumber?
    @NSManaged var dateGrouping: String?
    @NSManaged var items: NSOrderedSet?

}
