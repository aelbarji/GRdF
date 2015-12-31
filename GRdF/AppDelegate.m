//
//  AppDelegate.m
//  GRdF
//
//  Created by Jean-Philippe BEAUFILS on 18/11/2014.
//  Copyright (c) 2014 Onatys. All rights reserved.
//
// -- controllers definition
#import "MainViewController.h"
#import "SynchroViewController.h"
#import "SettingsViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"

@interface AppDelegate()
{
}
// -- UIView controllers
@property (retain, nonatomic) SynchroViewController     *synchroController;
@property (retain, nonatomic) SettingsViewController    *settingsController;
@property (retain, nonatomic) MainViewController        *mainController;

// -- UINavigation controller
@property (retain, nonatomic) UINavigationController    *navigationController;

@end

@implementation AppDelegate

@synthesize managedObjectContext        = _managedObjectContext;
@synthesize managedObjectModel          = _managedObjectModel;
@synthesize persistentStoreCoordinator  = _persistentStoreCoordinator;


#pragma mark - public methods
- (void) launchSynchro
{
    DLog(@"-> start");
    
    [[self synchroViewController] setModalPresentationStyle:UIModalPresentationFullScreen];


    self.window.rootViewController = _synchroController;
    
    DLog(@"-> stop");
}

#pragma mark - Synchro notification
- (void) closeSynchro
{
    DLog(@"-> start");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GRdF_SYNCHRO_CLOSE_NOTIFICATION
                                                  object:nil];
    
    //    self.window.rootViewController = nil;
    self.window.rootViewController = _navigationController;
    
    //    self.synchroController  = nil;
    
    DLog(@"-> stop");
}


#pragma mark - facility private methods
- (void) initOLGps
{
    NSUserDefaults *defaults        = [NSUserDefaults standardUserDefaults];
    [defaults setObject : kNsdKeyLocationMethodUpdate
                  forKey:kNsdKeyLocationMethods];  // kNsdKeyLocationMethodChange
    [defaults setDouble : 200       forKey:kNsdKeyThreshold];
    [defaults setDouble : 0         forKey:kNsdKeyAccuracy];
    [defaults setBool   : NO        forKey:kNsdKeyAssessAccuracy];
    [defaults setBool   : NO        forKey:kNsdKeyAssessDistance];
    [defaults synchronize];
    
    _olGps = [[OLGps alloc] initWithUserDefaults];
}


- (void) initApplicationComponents
{
    
    // -- olGPS initialization
    [self initOLGps];
    
    // -- decimal sep
    if (!_decimalSeparator)
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init] ;

        self.decimalSeparator = [formatter decimalSeparator];
        
        MF_COCOA_RELEASE(formatter);
    }
    
    // -- init mainView controller
    MainViewController *mainVC      = [[MainViewController alloc]
                                       initWithNibName:@"MainViewController"
                                       bundle:nil];
    self.mainController             = mainVC;
    [mainVC release];
    
    
    // -- init main navigation controller
    UINavigationController *navC    = [[UINavigationController alloc]
                                       initWithRootViewController:_mainController];
    navC.delegate                   = (id) _mainController;
    
    self.navigationController       = navC;
    [navC   release];
}


- (SynchroViewController *) synchroViewController
{
    if (! self.synchroController)
    {
        
        SynchroViewController *syncVC = [[SynchroViewController alloc] initWithNibName:@"SynchroViewController" bundle:nil];
        self.synchroController          = syncVC;
        [syncVC release];

    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeSynchro)
                                                 name:GRdF_SYNCHRO_CLOSE_NOTIFICATION
                                               object:nil];
    
    return self.synchroController;
}


- (SettingsViewController *) settingsViewController
{
    if (! self.settingsController)
    {
        
        SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
        self.settingsController          = settingsVC;
        [settingsVC release];
    }
    
    return self.settingsController;
}


#pragma mark - application lifecycle management
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    
    //FABRIC
    [[Fabric sharedSDK] setDebug: YES];
    [Fabric with:@[[Crashlytics class]]];

    // Copy data base
    [ self initDataBase];
    
    // init main application components
    [self initApplicationComponents];
    
    // -- start application with synchronization
    self.window.rootViewController  = [self synchroViewController];
    [self.window makeKeyAndVisible];

    [_olGps startMonitor];
    
    // Initialise path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // Initialise directory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    DLog(@"documentsDirectory:%@", documentsDirectory);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    exit(1);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)dealloc
{
    DLog(@"-> deallocating");
    
    self.decimalSeparator       = nil;
    self.olGps                  = nil;
    
    // release controllers
    MF_COCOA_RELEASE(_settingsController);
    MF_COCOA_RELEASE(_synchroController);
    MF_COCOA_RELEASE(_mainController);
    
    
    // finalize release
    [_window                        release];
    [_managedObjectContext          release];
    [_managedObjectModel            release];
    [_persistentStoreCoordinator    release];
    
    [super                          dealloc];
}



- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (BOOL) initDataBase{
    
    //check if writable Database existe
    BOOL			success;
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSError			*error;
    
    // LOG
    DLog(@"-> begin");
    
    // Initialise path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // Initialise directory
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Add DB_NAME to path
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:OMBS_DATABASE_FILE];
    
    // Check if data base already exists
    success = [fileManager fileExistsAtPath:dbPath];
    
    // Data base already exists
    if (success) {
        DLog(@"DB already exists");
        return TRUE;
    }
    
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:OMBS_DATABASE_FILE];
    
    // LOG
    DLog(@"defaultDBPath : %@.", defaultDBPath);
    
    // Copy data base
    success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
    if (!success) {
        // LOG
        DLog(@"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        return FALSE;
    }
    else {
        // LOG
        DLog(@"Writable database created with success.");
    }
    
    // LOG
    DLog(@"-> end");
    
    return TRUE;
}

#pragma mark - Core Data stack
// -- save notification management
- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    DLog(@"moc saved notification");
    
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (_managedObjectContext == savedContext)
    {
        return;
    }
    
    if (_managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
/*
    [_managedObjectContext.persistentStoreCoordinator lock];
    [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    [_managedObjectContext.persistentStoreCoordinator unlock];
*/
    //Synchrone
    [_managedObjectContext performBlockAndWait:^{
         [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        
        // subscribe to change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"iPadData" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL         = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"iPadData.sqlite"];
    NSDictionary *options   = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                               [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                               @{@"journal_mode" : @"DELETE"}, NSSQLitePragmasOption ,nil];
    //                               @{@"journal_mode" : @"DELETE"}, NSSQLitePragmasOption,nil]
    // to prevent use of sqlite wal mode (write ahead logging)
    NSError *error          = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
