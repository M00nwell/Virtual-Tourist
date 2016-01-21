//
//  PicViewController.swift
//  VirtualTourist
//
//  Created by 咩咩 on 16/1/10.
//  Copyright © 2016年 Wenzhe. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PicViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var annotation: MKAnnotation!
    
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        fetchedResultsController.delegate = self
        
        let region = MKCoordinateRegionMake(annotation!.coordinate,MKCoordinateSpanMake(0.1,0.1))
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(annotation!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 3)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor(self.collectionView.frame.size.width/3-6)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    // MARK: - Fetched Results Controller Delegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        let n = sectionInfo.numberOfObjects
        if(n == 0){
            let label = UILabel(frame: CGRectMake(0, 0, 200, 21))
            label.center = view.center
            label.textAlignment = NSTextAlignment.Center
            label.text = "This pin has no images"
            view.addSubview(label)
        }
        return n
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("picCell", forIndexPath: indexPath) as! PictureCell
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        configureCell(cell, pic: picture, index: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PictureCell
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, pic: picture, index: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    func configureCell(cell: PictureCell, pic: Picture, index: NSIndexPath){
        
        if let localImage = pic.image {
            cell.imageView.image = localImage
        }else {
            let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0, 50, 50)) as UIActivityIndicatorView
            activityIndicator.center = CGPoint(x: (cell.frame.width)/2, y: (cell.frame.height)/3)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            activityIndicator.color = UIColor.grayColor()
            cell.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            
            let task = FlickrClient.sharedInstance().getDataFromUrl(NSURL(string: pic.url)!) { (imageData, response, error) -> Void in
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        pic.image = image
                        cell.imageView.image = image
                        activityIndicator.stopAnimating()
                    }
                }
                else{
                    print("error getting image")
                }
            }
            
            cell.taskToCancelifCellIsReused = task
        }
        
        if let _ = selectedIndexes.indexOf(index) {
            cell.imageView.alpha = 0.05
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    @IBAction func bottomButtonPressed(sender: UIBarButtonItem) {
        if selectedIndexes.count > 0 {
            for index in selectedIndexes{
                let pic = fetchedResultsController.objectAtIndexPath(index) as! Picture
                sharedContext.deleteObject(pic)
            }
            selectedIndexes = [NSIndexPath]()
            bottomButton.title = "New Collection"
            CoreDataStackManager.sharedInstance().saveContext()
        } else {
            for pic in fetchedResultsController.fetchedObjects as! [Picture] {
                sharedContext.deleteObject(pic)
            }
            
            FlickrClient.sharedInstance().searchPhotos(pin.latitude, lon: pin.longitude){ url, error in
                if (error != nil || url == nil){
                    print("error in search photos")
                    let alert = UIAlertController(title: "Alert", message: "Please check Internet connection", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                        alert.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                }else{
                    for element in url! {
                        let pic = Picture(url: element, context: self.sharedContext)
                        pic.pin = self.pin
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
}

class PictureCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}