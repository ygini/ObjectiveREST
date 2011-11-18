//
//  RESTManager.h
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RESTManager : NSObject

@property (retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign, nonatomic) BOOL modelIsObjectiveRESTReady;
@property (assign, nonatomic) BOOL requestHTTPS;
@property (assign, nonatomic) BOOL allowDeleteOnCollection;

+ (RESTManager*)sharedInstance;

@end
