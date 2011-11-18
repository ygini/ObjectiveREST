//
//  RESTManager.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RESTManager.h"

@implementation RESTManager

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize modelIsObjectiveRESTReady;
@synthesize requestHTTPS;
@synthesize allowDeleteOnCollection;

+ (RESTManager*)sharedInstance {
	static RESTManager* sharedInstanceRESTManager = nil;
	if (!sharedInstanceRESTManager) sharedInstanceRESTManager = [RESTManager new];
	return sharedInstanceRESTManager;
}

@end
