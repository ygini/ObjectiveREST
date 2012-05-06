//
//  ORServerProtocols.h
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HTTPMessage.h"
#import "HTTPResponse.h"

@protocol ORServerDataProvider <NSObject>
@required
- (NSPersistentStoreCoordinator*)persistentStoreCoordinator;
- (NSManagedObjectModel*)managedObjectModel;
- (NSManagedObjectContext*)managedObjectContext;
@end

@protocol ORServerExternalAPI <NSObject>
@required
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path andHTTPRequest:(HTTPMessage*)request;
@end

@protocol ORManagedObject <NSObject>
// i.e. 6E4D3BA3-FCD3-4611-9796-583301DA30B
@required
- (NSString *)ORUniqueID;

@optional
- (NSComparisonResult)compare:(NSManagedObject<ORManagedObject>*)obj;
@end