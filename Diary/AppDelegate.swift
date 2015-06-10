//
//  AppDelegate.swift
//  Diary
//
//  Created by kevinzhow on 15/2/11.
//  Copyright (c) 2015年 kevinzhow. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate{

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        application.applicationSupportsShakeToEdit = true
        
        if let token = NSFileManager.defaultManager().ubiquityIdentityToken {
            // iCloud is available
            if let iCloudEnabled = defaults.objectForKey("defaultCloudConfig") as? Bool{
                if iCloudEnabled {
                    println("Already Enabled")
                    migrateLocalStoreToiCloudStore()
                } else {
                    println("Migrate Local To iCloud")
                    migrateLocalStoreToiCloudStore()
                }
            }
            
            defaults.setObject(true, forKey: "defaultCloudConfig")
            
        } else {
            println("No iCloud")
            
            var message = UIAlertView(title: "iCloud 未开启", message: "为了备份您的数据，请在系统设置里登录 iCloud 以免发生记录丢失", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "好的")
            message.show()
            
            defaults.setObject(false, forKey: "defaultCloudConfig")
        }
        
        defaultConfig()
        Crashlytics.startWithAPIKey("de004490005a062fa95a4d5676a7edbfbe42c582")
        
        registerForiCloudNotifications()
        return true
    }
    
    func defaultConfig() {
        
        if let config: AnyObject = defaults.objectForKey("defaultConfig") {
            println("Configed")
        }else{
            defaults.setObject(currentLanguage == "ja" ? janpan : firstFont, forKey: "defaultFont")
            
            defaults.setObject(firstFont, forKey: "firstFont")
            defaults.setObject(secondFont, forKey: "secondFont")
            defaults.setObject(janpan, forKey: "japan")
            defaults.setObject(true, forKey: "defaultConfig")
            
        }
        
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "kevinzhow.Diary" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()
    
    lazy var cloudDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "kevinzhow.Diary" in the application's documents Application Support directory.
        var teamID = "iCloud."
        var bundleID = NSBundle.mainBundle().bundleIdentifier!
        var cloudRoot = "\(teamID)\(bundleID).sync"
        let url = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("\(cloudRoot)")
        println("\(url)\(cloudRoot)")
        return url!
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Diary", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store


        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Diary.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: self.storeOptions, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "Catch.Diary.Error", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var storeOptions: [NSObject : AnyObject] = {
        return [
            NSMigratePersistentStoresAutomaticallyOption:true,
            NSInferMappingModelAutomaticallyOption: true,
            NSPersistentStoreUbiquitousContentNameKey : "CatchDiary",
            NSPersistentStoreUbiquitousPeerTokenOption: "c405d8e8a24s11e3bbec425861s862bs"]
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    func registerForiCloudNotifications() {
        var notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "storesWillChange:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: persistentStoreCoordinator)
        notificationCenter.addObserver(self, selector: "storesDidChange:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: persistentStoreCoordinator)
        notificationCenter.addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: persistentStoreCoordinator)
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(notification:NSNotification){
        var context = self.managedObjectContext!
        println("Perform icloud data 1")
        context.performBlockAndWait({
            context.mergeChangesFromContextDidSaveNotification(notification)

        })
    }
    
    func storesWillChange(notification:NSNotification) {
        println("Store Will change")
        var context:NSManagedObjectContext! = self.managedObjectContext
        context?.performBlockAndWait({
            var error:NSError?
            if (context.hasChanges) {
                var success = context.save(&error)
                
                if (!success && (error != nil)) {
                    // 执行错误处理
                    NSLog("%@",error!.localizedDescription)
                    self.showAlert()
                }
            }
            context.reset()
        })

    }
    
    func showAlert() {
        var message = UIAlertView(title: "iCloud 同步错误", message: "是否使用 iCloud 版本备份覆盖本地记录", delegate: self, cancelButtonTitle: "不要", otherButtonTitles: "好的")
        message.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:
            self.migrateLocalStoreToiCloudStore()
        case 1:
            self.migrateiCloudStoreToLocalStore()
        default:
            println("Do nothing")
        }
    }
    
    func storesDidChange(notification:NSNotification){
        println("Store did change")
        NSNotificationCenter.defaultCenter().postNotificationName("CoreDataDidUpdated", object: nil)
    }
    
    func migrateLocalStoreToiCloudStore() {
        println("Migrate local to icloud")
        
        var oldStore = persistentStoreCoordinator?.persistentStores.first as! NSPersistentStore
        var localStoreOptions = self.storeOptions
        localStoreOptions[NSPersistentStoreRemoveUbiquitousMetadataOption] = true
        var newStore = persistentStoreCoordinator?.migratePersistentStore(oldStore, toURL: cloudDirectory, options: localStoreOptions, withType: NSSQLiteStoreType, error: nil)
        
        reloadStore(newStore)
    }
    
    func migrateiCloudStoreToLocalStore() {
        println("Migrate icloud to local")
        var oldStore = persistentStoreCoordinator?.persistentStores.first as! NSPersistentStore
        var localStoreOptions = self.storeOptions
        localStoreOptions[NSPersistentStoreRemoveUbiquitousMetadataOption] = true
        var newStore = persistentStoreCoordinator?.migratePersistentStore(oldStore, toURL:  self.applicationDocumentsDirectory.URLByAppendingPathComponent("Diary.sqlite"), options: localStoreOptions, withType: NSSQLiteStoreType, error: nil)
        
        reloadStore(newStore)
    }
    
    func reloadStore(store: NSPersistentStore?) {
        if (store != nil) {
            persistentStoreCoordinator?.removePersistentStore(store!, error: nil)
        }
        
        persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.applicationDocumentsDirectory.URLByAppendingPathComponent("Diary.sqlite"), options: self.storeOptions, error: nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName("CoreDataDidUpdated", object: nil)
    }

}

