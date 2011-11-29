//
//  RESTClient.h
//  ObjectiveREST iOS
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RESTClient : NSObject

@property (assign, nonatomic) BOOL modelIsObjectiveRESTReady;
@property (assign, nonatomic) BOOL requestHTTPS;
@property (assign, nonatomic) BOOL requestAuthentication;
@property (assign, nonatomic) BOOL useDigest;

@property (retain, nonatomic) NSString *username;
@property (retain, nonatomic) NSString *password;

@property (retain, nonatomic) NSString *serverAddress;
@property (assign, nonatomic) NSInteger tcpPort;

@property (retain, nonatomic) NSArray* contentType;


+ (RESTClient*)sharedInstance;

- (NSString*)hostInfoWithServer:(NSString*)address andPort:(NSInteger)port;
- (NSString*)hostInfo;
- (NSString*)baseURL;
- (NSString*)absoluteVersionForPath:(NSString*)path;
- (NSMutableURLRequest*)baseRequestForPath:(NSString*)path;

- (NSDictionary*)postInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path;
- (NSDictionary*)postInfo:(NSDictionary*)info toPath:(NSString*)path;

- (NSDictionary*)putInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path;
- (NSDictionary*)putInfo:(NSDictionary*)info toPath:(NSString*)path;

- (void)deleteAbsolutePath:(NSString*)path;
- (void)deletePath:(NSString*)path;

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path;
- (NSMutableDictionary*)getPath:(NSString*)path;

- (NSArray*)getAllObjectOfThisEntityKind:(NSString*)path;

@end
