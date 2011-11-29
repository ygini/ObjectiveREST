//
//  RCAppDelegate.h
//  iOS REST Chat
//
//  Created by Yoann Gini on 28/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CHAT_NET_SERVICE_TYPE   @"_iOSRESTChat._tcp"

@interface RCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+(RCAppDelegate*)sharedInstance;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(void)sendMessage:(NSString*)stringMessage;
-(NSArray*)getMessages;

@end
