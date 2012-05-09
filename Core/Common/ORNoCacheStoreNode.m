//
//  ORNoCacheStoreNode.m
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORNoCacheStoreNode.h"

#import "ORToolbox.h"
#import "ORNoCacheStore.h"

@implementation ORNoCacheStoreNode
@synthesize remoteURL = _remoteURL;
@synthesize ORNodeIsDirty = _ORNodeIsDirty;

-(NSMutableDictionary*)loadRemoteInfos {
    if ([_remoteURL rangeOfString:@"tmp://"].location == NSNotFound) {
        NSMutableDictionary *remoteInfos = [[[ORToolbox sharedInstanceForPersistentStore:self.objectID.persistentStore] getAbsolutePath:_remoteURL] valueForKey:@"content"];
        NSMutableDictionary *info = [NSMutableDictionary new];
        
        NSManagedObjectID *objectID = self.objectID;
        ORNoCacheStore *persistentStore = (ORNoCacheStore *)objectID.persistentStore;
        NSEntityDescription *entityDescription = objectID.entity;
        
        
        NSString *attribute = nil;
        
        for (attribute in [entityDescription attributeKeys]) {
            [info setValue:[remoteInfos valueForKey:attribute] forKey:attribute];
        }
        
        NSDictionary *relationlist = [entityDescription relationshipsByName];
        NSRelationshipDescription *relationship = nil;
        NSSet *relations = nil;
        
        for (attribute in [relationlist allKeys]) {
            relationship = [relationlist valueForKey:attribute];
            if ([relationship isToMany]) {
                relations = [remoteInfos valueForKey:attribute];
                
                NSMutableSet *data = [NSMutableSet setWithCapacity:[relations count]];
                
                for (NSDictionary *relatedLink in relations) {
                    id referenceID = [relatedLink valueForKey:OR_REF_KEYWORD];
                    NSManagedObjectID *objectID = [persistentStore objectIDForEntity:relationship.destinationEntity referenceObject:referenceID];
                    ORNoCacheStoreNode *objectCacheNode = [persistentStore nodeForReferenceObject:referenceID andObjectID:objectID];
                    objectCacheNode.remoteURL = [relatedLink valueForKey:OR_REF_KEYWORD];
                    [data addObject:objectCacheNode];
                }
                [info setValue:data forKey:attribute];
            } else {
                NSDictionary *relatedLink = [remoteInfos valueForKey:attribute];
                id referenceID = [relatedLink valueForKey:OR_REF_KEYWORD];
                NSManagedObjectID *objectID = [persistentStore objectIDForEntity:relationship.destinationEntity referenceObject:referenceID];
                ORNoCacheStoreNode *objectCacheNode = [persistentStore nodeForReferenceObject:referenceID andObjectID:objectID];
                objectCacheNode.remoteURL = [relatedLink valueForKey:OR_REF_KEYWORD];
                [info setValue:objectCacheNode forKey:attribute];
            }
        }
        
        return [info autorelease];
    }
    return [NSMutableDictionary dictionary];
}


-(id)valueForKey:(NSString *)key {
    NSMutableDictionary *cache = [self propertyCache];
    
    if ([@"ORNodeIsDirty" isEqualToString:key]) {
        return [NSNumber numberWithBool:self.ORNodeIsDirty];
    }
    
    if (!cache) {
        cache = [self loadRemoteInfos];
        [self setPropertyCache:cache];
        self.ORNodeIsDirty = NO;
    }
    return [cache valueForKey:key];
}

-(void)setValue:(id)value forKey:(NSString *)key {
    [super setValue:value forKey:key];
    
    if (!_ORNodeIsDirty) {
        NSPropertyDescription *desc = [[self.objectID.entity propertiesByName] valueForKey:key];
        if (![desc isTransient]) {
            _ORNodeIsDirty = YES;
        }
    }
}

@end
