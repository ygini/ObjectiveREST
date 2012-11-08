//
//  ORToolbox.h
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORToolbox : NSObject {
    NSArray *_acceptedContentType;
    NSIncrementalStore *_associatedStore;
}

@property (retain, nonatomic) NSURL *serverURL;
@property (retain, nonatomic) NSString *negociatedContentType;

+ (ORToolbox*)sharedInstance;
+ (ORToolbox*)sharedInstanceForPersistentStore:(NSIncrementalStore*)store;

- (NSString*)acceptedContentType;

- (NSString*)absoluteVersionForPath:(NSString*)path;
- (NSMutableURLRequest*)baseRequestForPath:(NSString*)path;

- (NSDictionary*)postInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path;
- (NSDictionary*)postInfo:(NSDictionary*)info toPath:(NSString*)path;

- (NSDictionary*)putInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path;
- (NSDictionary*)putInfo:(NSDictionary*)info toPath:(NSString*)path;
- (void)deleteAbsolutePath:(NSString*)path;
- (void)deletePath:(NSString*)path;

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path;
- (NSMutableDictionary*)getAbsolutePath:(NSString*)path withHTTPHeader:(NSDictionary*)headers;
- (NSMutableDictionary*)getPath:(NSString*)path;
- (NSArray*)getAllObjectOfThisEntityKind:(NSString*)path;
- (NSArray*)getObjectsForFetchRequest:(NSFetchRequest*)request;

- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict;
- (NSDictionary*)dictionaryFromResponse:(NSData*)response;

- (NSMutableDictionary*)dictionaryFromManagedObject:(NSManagedObject*)object;

@end
