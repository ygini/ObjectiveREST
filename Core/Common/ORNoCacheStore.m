//
//  ORNoCacheStore.m
//  iPlayer Client
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORNoCacheStore.h"

#import "NSString+UUID.h"
#import "ORToolbox.h"
#import "ORNoCacheStoreNode.h"

NSString *OR_NO_CACHE_STORE = @"OR_NO_CACHE_STORE";

#define OR_SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]
#define	OR_REF_KEYWORD                          @"rest_ref"

@interface ORNoCacheStore ()
-(BOOL)checkRemoteManagedContext;
-(NSArray*)listRemoteEntities;
- (ORNoCacheStoreNode*)nodeForReferenceObject:(id)referenceObject andObjectID:(NSManagedObjectID*)objectID;
@end

@implementation ORNoCacheStore

@synthesize identifier;

#pragma mark - PersistentStore

+(void)load {
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
        [NSPersistentStoreCoordinator registerStoreClass:[ORNoCacheStore class]
                                            forStoreType:OR_NO_CACHE_STORE];
    [pool release];
}

+(NSDictionary *)metadataForPersistentStoreWithURL:(NSURL *)url error:(NSError **)error {
    NSMutableDictionary *metadata = [[[[ORToolbox sharedInstance] getAbsolutePath:[url absoluteString]] valueForKey:@"metadata"] mutableCopy];
    [metadata setValue:OR_NO_CACHE_STORE forKey:NSStoreTypeKey];
    return [metadata autorelease];
}

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL *)url options:(NSDictionary *)options {
    self = [super initWithPersistentStoreCoordinator:coordinator configurationName:configurationName URL:url options:options];
    if (self) {
        _serverURL = [url copy];
        _contentType = [OR_SUPPORTED_CONTENT_TYPE retain];
        _nodeCacheRef = [NSMutableDictionary new];
        
        [self setIdentifier:[NSString UUIDString]];
        
        [ORToolbox sharedInstanceForPersistentStore:self].serverURL = _serverURL;
        
        [self setMetadata:[ORNoCacheStore metadataForPersistentStoreWithURL:_serverURL error:nil]];
        
        if (![self checkRemoteManagedContext]) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [_serverURL release];
    [_contentType release];
    [_nodeCacheRef release];
    [super dealloc];
}

-(BOOL)load:(NSError **)error {
    NSArray *localEntities = [self.persistentStoreCoordinator.managedObjectModel entities];
    NSArray * objectList = nil;
    NSManagedObjectID *objectID = nil;
    ORNoCacheStoreNode *objectCacheNode = nil;
    
    NSMutableSet *cacheNodes = [NSMutableSet set];
    
    for (NSEntityDescription *entity in localEntities) {
        objectList = [[[ORToolbox sharedInstanceForPersistentStore:self] getPath:[entity name]] valueForKey:@"content"];
        for (NSDictionary *objectInfo in objectList) {
            objectID = [self objectIDForEntity:entity referenceObject:[objectInfo valueForKey:OR_REF_KEYWORD]];
            objectCacheNode = [self nodeForReferenceObject:objectID andObjectID:objectID];
            objectCacheNode.remoteURL = [objectInfo valueForKey:OR_REF_KEYWORD];
            [cacheNodes addObject:objectCacheNode];
        }
    }
    
    [self addCacheNodes:cacheNodes];
    
    return YES;
}

- (NSString *)type {
    return [[self metadata] valueForKey:NSStoreTypeKey];
}

-(void)setMetadata:(NSDictionary *)storeMetadata {
    NSMutableDictionary *metadata = [storeMetadata mutableCopy];
    [metadata setValue:OR_NO_CACHE_STORE forKey:NSStoreTypeKey];
    [metadata setValue:self.identifier forKey:NSStoreUUIDKey];
    [super setMetadata:metadata];
    [metadata release];
}

-(id)newReferenceObjectForManagedObject:(NSManagedObject *)managedObject {
    return [[NSString stringWithFormat:@"tmp://%@/%@", managedObject.entity.name, [NSString UUIDString]] retain];
}

-(NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject {
    NSManagedObjectID *objectID = [managedObject objectID];
    id referenceID = [self referenceObjectForObjectID:objectID];
    ORNoCacheStoreNode *objectCacheNode = [[self nodeForReferenceObject:referenceID andObjectID:objectID] retain];
    [self updateCacheNode:objectCacheNode fromManagedObject:managedObject];
    return objectCacheNode;
}

-(void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject {
    NSEntityDescription *entityDescription = managedObject.entity;
    NSString *attribute = nil;
    
    for (attribute in [entityDescription attributeKeys]) {
        [node setValue:[managedObject valueForKey:attribute] forKey:attribute];
    }
    
    NSDictionary *relationlist = [entityDescription relationshipsByName];
    NSRelationshipDescription *relationship = nil;
    NSSet *relations = nil;
    
    for (attribute in [relationlist allKeys]) {
        relationship = [relationlist valueForKey:attribute];
        if ([relationship isToMany]) {
            relations = [managedObject valueForKey:attribute];
            
            NSMutableSet *data = [NSMutableSet setWithCapacity:[relations count]];
            
            for (NSManagedObject *relatedObject in relations) {
                NSManagedObjectID *objectID = relatedObject.objectID;
                id referenceID = [self referenceObjectForObjectID:objectID];
                ORNoCacheStoreNode *objectCacheNode = [self nodeForReferenceObject:referenceID andObjectID:objectID];
                [data addObject:objectCacheNode];
            }
            [node setValue:data forKey:attribute];
        } else {
            NSManagedObject *relatedObject = [managedObject valueForKey:attribute];
            NSManagedObjectID *objectID = relatedObject.objectID;
            id referenceID = [self referenceObjectForObjectID:objectID];
            ORNoCacheStoreNode *objectCacheNode = [self nodeForReferenceObject:referenceID andObjectID:objectID];
            [node setValue:objectCacheNode forKey:attribute];
        }
    }
}

- (ORNoCacheStoreNode*)nodeForReferenceObject:(id)referenceObject andObjectID:(NSManagedObjectID*)objectID {
    if (!referenceObject) {
        return nil;
    }

    ORNoCacheStoreNode *node = [_nodeCacheRef objectForKey:referenceObject];
    if (!node) {
        node = [[[ORNoCacheStoreNode alloc] initWithObjectID:objectID] autorelease];
        [_nodeCacheRef setObject:node forKey:referenceObject];
    }
    return node;
}

-(BOOL)save:(NSError **)error {
    return [[ORToolbox sharedInstanceForPersistentStore:self] saveNodes:[self cacheNodes]];
}

#pragma mark - Routines

-(BOOL)checkRemoteManagedContext {
    NSArray *localEntities = [self.persistentStoreCoordinator.managedObjectModel entities];
    NSArray *remoteEntities = [self listRemoteEntities];
    for (NSEntityDescription *entity in localEntities) {
        if ([remoteEntities indexOfObject:[entity name]] == NSNotFound) {
            return NO;
        }
    }
    
    return YES;
}

-(NSArray*)listRemoteEntities {
    NSArray * content = [[[ORToolbox sharedInstanceForPersistentStore:self] getPath:@"/"] valueForKey:@"content"];
    NSMutableArray *remoteEntities = [NSMutableArray new];
    
    for (NSString *entitiyURL in [content valueForKeyPath:[NSString stringWithFormat:@"@unionOfObjects.%@", OR_REF_KEYWORD]]) {
        [remoteEntities addObject:[entitiyURL lastPathComponent]];
    }
    
    
    return [remoteEntities autorelease];
}

@end
