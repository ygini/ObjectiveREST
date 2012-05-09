//
//  ORToolbox.h
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OR_SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]
#define	OR_REF_KEYWORD                          @"rest_ref"

@class ORNoCacheStoreNode;

@interface ORToolbox : NSObject {
    NSArray *_acceptedContentType;
    NSPersistentStore *_associatedStore;
}

@property (retain, nonatomic) NSURL *serverURL;
@property (retain, nonatomic) NSString *negociatedContentType;

+ (ORToolbox*)sharedInstance;
+ (ORToolbox*)sharedInstanceForPersistentStore:(NSPersistentStore*)store;

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
- (NSMutableDictionary*)getPath:(NSString*)path;
- (NSArray*)getAllObjectOfThisEntityKind:(NSString*)path;

- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict;
- (NSDictionary*)dictionaryFromResponse:(NSData*)response;

- (BOOL)saveNode:(ORNoCacheStoreNode*)node;
- (BOOL)saveNodes:(NSSet*)nodes;
@end
