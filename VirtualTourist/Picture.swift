//
//  Picture.swift
//  VirtualTourist
//
//  Created by 咩咩 on 16/1/10.
//  Copyright © 2016年 Wenzhe. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Picture: NSManagedObject {
    
    @NSManaged var url: String
    @NSManaged var pin: Pin?
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(url: String, context: NSManagedObjectContext){
        let entity =  NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.url = url
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(url)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: url)
        }
    }
}
