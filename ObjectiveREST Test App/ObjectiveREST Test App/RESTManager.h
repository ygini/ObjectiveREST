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

+ (RESTManager*)sharedInstance;

@end
