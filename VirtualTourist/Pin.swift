//
//  Pin.swift
//  VirtualTourist
//
//  Created by 咩咩 on 16/1/10.
//  Copyright © 2016年 Wenzhe. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Pin: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var pics: [Picture]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lon: Double, lat: Double, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = lat
        self.longitude = lon
    }
}
