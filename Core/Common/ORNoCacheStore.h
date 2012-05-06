//
//  ORNoCacheStore.h
//  iPlayer Client
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString *OR_NO_CACHE_STORE;

@class ORNoCacheStoreNode;

@interface ORNoCacheStore : NSAtomicStore {
    @private
    NSURL *_serverURL;
    NSArray *_contentType;
    
    NSMutableDictionary *_nodeCacheRef;
}

@property (retain, nonatomic) NSString *identifier;

- (ORNoCacheStoreNode*)nodeForReferenceObject:(id)referenceObject andObjectID:(NSManagedObjectID*)objectID;

@end
