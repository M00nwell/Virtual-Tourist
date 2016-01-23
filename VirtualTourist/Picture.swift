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
            let u = NSURL(fileURLWithPath: url)
            return FlickrClient.Caches.imageCache.imageWithIdentifier(u.lastPathComponent)
        }
        
        set {
            let u = NSURL(fileURLWithPath: url)
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: u.lastPathComponent!)
        }
    }
    
    override func prepareForDeletion() {
        let u = NSURL(fileURLWithPath: url)
        FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: u.lastPathComponent!)
    }
}
