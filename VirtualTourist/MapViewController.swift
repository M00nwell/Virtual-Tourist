//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by 咩咩 on 16/1/10.
//  Copyright © 2016年 Wenzhe. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController:  UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var notificationView: UIView!
    var isMapRestored: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        mapView.delegate = self
        fetchedResultsController.delegate = self
        editButton.title = "Edit"
        loadPins()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        notificationView.frame.origin.y += notificationView.frame.height
        restoreMapRegion()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    @IBAction func EditPressed(sender: AnyObject) {
        if(editButton.title == "Edit"){
            editButton.title = "Done"
            UIView.animateWithDuration(0.5, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.notificationView.frame.origin.y -= self.notificationView.frame.height
                self.mapView.frame.origin.y -= self.notificationView.frame.height
                }, completion: nil)
        }else{
            editButton.title = "Edit"
            UIView.animateWithDuration(0.5, delay: 0, options: .CurveLinear, animations: { () -> Void in
                self.notificationView.frame.origin.y += self.notificationView.frame.height
                self.mapView.frame.origin.y += self.notificationView.frame.height
            }, completion: nil)
            restoreMapRegion()
        }
    }
    
    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        if editButton.title == "Done" {
            return
        } else if sender.state == .Began {
            let touchPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let lat = coordinate.latitude as Double
            let lon = coordinate.longitude as Double
            let pinToAdd = Pin(lon: lon, lat: lat, context: sharedContext)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            getPhoto(pinToAdd)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func getPhoto(pin: Pin)
    {
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
                    pic.pin = pin
                }
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        var pinSelected: Pin!
        for pin in fetchedResultsController.fetchedObjects as! [Pin] {
            if ( pin.latitude == view.annotation?.coordinate.latitude &&
                pin.longitude == view.annotation?.coordinate.longitude)
            {
                pinSelected = pin
            }
        }
        
        if editButton.title == "Edit" {
            let picsCollectionVC = self.storyboard!.instantiateViewControllerWithIdentifier("picsCollectionVC") as! PicViewController
            picsCollectionVC.pin = pinSelected
            mapView.deselectAnnotation(view.annotation, animated: false)
            picsCollectionVC.annotation = view.annotation!
            navigationController!.pushViewController(picsCollectionVC, animated: true)
        } else {
            mapView.removeAnnotation(view.annotation!)
            sharedContext.deleteObject(pinSelected)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            switch(type){
            case .Delete:
                print("Pin deleted")
                break
            case .Insert:
                print("Pin inserted")
                break
            default:
                break
            }
    }
    
    func loadPins(){
        var annotations = [MKPointAnnotation]()
        
        for location in fetchedResultsController.fetchedObjects as! [Pin] {
            
            let lat = CLLocationDegrees(location.latitude)
            let lon = CLLocationDegrees(location.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
    }
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL!
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    // Save region with NSKeyedArchiver
    func saveMapRegion() {
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        print("SAVING : lat-\(dictionary["latitude"]!), lon-\(dictionary["longitude"]!), latDelta-\(dictionary["latitudeDelta"]!), lonDelta-\(dictionary["longitudeDelta"]!)")
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    // Restore region with NSKeyedArchiver
    func restoreMapRegion() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let region = MKCoordinateRegionMake(
                CLLocationCoordinate2DMake(regionDictionary["latitude"] as! Double,regionDictionary["longitude"] as! Double),
                MKCoordinateSpanMake(regionDictionary["latitudeDelta"] as! Double, regionDictionary["longitudeDelta"] as! Double)
            )
            print("RESTORE: lat-\(region.center.latitude), lon-\(region.center.longitude), latDelta-\(region.span.latitudeDelta), lonDelta-\(region.span.longitudeDelta)")
            mapView.setRegion(region, animated: false)
            print("SET TO : lat-\(mapView.region.center.latitude), lon-\(mapView.region.center.longitude), latDelta-\(mapView.region.span.latitudeDelta), lonDelta-\(mapView.region.span.longitudeDelta)")
        }
        isMapRestored = true
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("CHANGED: lat-\(mapView.region.center.latitude), lon-\(mapView.region.center.longitude), latDelta-\(mapView.region.span.latitudeDelta), lonDelta-\(mapView.region.span.longitudeDelta)")
        if(isMapRestored) {
            saveMapRegion()
        }
    }
    
}

