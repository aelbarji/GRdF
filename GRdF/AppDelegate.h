//
//  AppDelegate.h
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//



#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

// UI components
@property (strong, nonatomic) UIWindow *window;

// location management
@property (strong, nonatomic)           OLGps   *olGps;

// number management
@property (strong, nonatomic)           NSString *decimalSeparator;


// coredata stack
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// public methods
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void) launchSynchro;

@end
