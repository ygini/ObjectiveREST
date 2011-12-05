//
//  ICAppDelegate.h
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IOSCHAT_M_DNS_TYPE      @"_iosdemo._tcp"

@interface ICAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (ICAppDelegate*)sharedInstance;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
