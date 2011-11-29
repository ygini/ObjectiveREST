//
//  RESTManager.h
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "RESTManagedObject.h"

#define REST_SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]
#define	REST_REF_KEYWORD					@"rest_ref"

@class HTTPServer;

@interface RESTManager : NSObject {
	HTTPServer *_httpServer;
}

@property (retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (retain, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (assign, nonatomic) BOOL modelIsObjectiveRESTReady;
@property (assign, nonatomic) BOOL requestHTTPS;
@property (assign, nonatomic) BOOL allowDeleteOnCollection;
@property (assign, nonatomic) BOOL requestAuthentication;
@property (assign, nonatomic) BOOL useDigest;

@property (retain, nonatomic) NSMutableDictionary *authenticationDatabase;

@property (assign, nonatomic) NSInteger tcpPort;

@property (retain, nonatomic) NSString* mDNSType;
@property (retain, nonatomic) NSString* mDNSName;
@property (retain, nonatomic) NSString* mDNSDomain;

@property (assign, nonatomic, readonly) BOOL isRunning;

+ (RESTManager*)sharedInstance;

- (BOOL)startServer;
- (BOOL)stopServer;

+ (NSArray*)managedObjectWithEntityName:(NSString*)name;
+ (NSManagedObject*)managedObjectWithEntityName:(NSString*)name andRESTUUID:(NSString*)rest_uuid;
+ (NSManagedObject*)managedObjectWithRelativePath:(NSString*)path;
+ (NSManagedObject*)managedObjectWithAbsolutePath:(NSString*)path;
+ (void)updateManagedObject:(NSManagedObject*)object withInfo:(NSDictionary*)infos;
+ (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict withContentType:(NSString*)ContentType;
+ (NSDictionary*)dictionaryFromResponse:(NSData*)response withContentType:(NSString*)ContentType;

+ (NSString*)baseURLForURIWithServerAddress:(NSString*)serverAddress;
+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forEntityWithName:(NSString*)name;
+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object;
+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object onRESTReadyObjectModel:(BOOL)RESTReady;
+ (NSDictionary*)restLinkRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object;
+ (NSManagedObject<RESTManagedObject>*)insertNewObjectForEntityForName:(NSString*)entityString;
+ (NSDictionary *)dictionaryRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject *)object;

@end
