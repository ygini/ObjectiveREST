//
//  ORNoCacheIncrementalStore.m
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 07/11/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORNoCacheIncrementalStore.h"

#import "ORToolbox.h"
#import "ORConstants.h"

@interface ORNoCacheIncrementalStore () {
@private
    NSURL *_serverURL;
    NSArray *_contentType;
    
    NSMutableDictionary *_objectIDCache;
	
	SRWebSocket *_webSocket;
}
- (NSManagedObjectID*)objectIdForObjectOfEntity:(NSEntityDescription*)entityDescription withReferenceObject:(id)ref;
@end

@implementation ORNoCacheIncrementalStore

#pragma mark Persistant Store Registering

+(void)load {
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
	[NSPersistentStoreCoordinator registerStoreClass:[ORNoCacheIncrementalStore class]
										forStoreType:OR_NO_CACHE_STORE];
    [pool release];
}

+(NSDictionary *)metadataForPersistentStoreWithURL:(NSURL *)url error:(NSError **)error {
	NSMutableDictionary *metadata = [[[[ORToolbox sharedInstance] getAbsolutePath:[url absoluteString]] valueForKey:OR_KEY_METADATA] mutableCopy];
	
	if (metadata) {
		[metadata setValue:OR_NO_CACHE_STORE forKey:NSStoreTypeKey];
	} else {
		if (error)
			*error = [NSError errorWithDomain:ORErrorDomain code:ORErrorDomainCode_SERVER_UNAVIABLE userInfo:nil];
	}
    return [metadata autorelease];
}

+ (id)identifierForNewStoreAtURL:(NSURL *)storeURL {
	NSMutableDictionary *metadata = [[[ORToolbox sharedInstance] getAbsolutePath:[storeURL absoluteString]] valueForKey:OR_KEY_METADATA];
    return [metadata valueForKey:NSStoreUUIDKey];
}

-(id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL *)url options:(NSDictionary *)options {
    self = [super initWithPersistentStoreCoordinator:coordinator configurationName:configurationName URL:url options:options];
    if (self) {
        _serverURL = [url copy];
        _contentType = [OR_SUPPORTED_CONTENT_TYPE retain];
        _objectIDCache = [NSMutableDictionary new];
                
        [ORToolbox sharedInstanceForPersistentStore:self].serverURL = _serverURL;
        
        [self setMetadata:[ORNoCacheIncrementalStore metadataForPersistentStoreWithURL:_serverURL error:nil]];
		
		NSURL *wsURL = [NSURL URLWithString:[self.metadata valueForKey:OR_KEY_WS_URL]];
		
		if (wsURL) {
			_webSocket = [[SRWebSocket alloc] initWithURL:wsURL];
			_webSocket.delegate = self;
			[_webSocket open];
		}
		
    }
    return self;
}

- (void)dealloc
{
	[_webSocket close];
    [_webSocket release], _webSocket = nil;
	[_contentType release], _contentType = nil;
	[_objectIDCache release], _objectIDCache = nil;
    [super dealloc];
}

-(BOOL)loadMetadata:(NSError **)error {
	NSDictionary * metadata = [ORNoCacheIncrementalStore metadataForPersistentStoreWithURL:_serverURL error:error];
	if (metadata) {
		[self setMetadata:metadata];
		return YES;
	} else return NO;
}

- (NSString *)type {
    return OR_NO_CACHE_STORE;
}

#pragma mark Persistant Store API

-(id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSArray * objectsRef = [[ORToolbox sharedInstanceForPersistentStore:self] getObjectsForFetchRequest:request];
	
	switch (request.resultType) {
		case NSManagedObjectIDResultType:
		case NSManagedObjectResultType: {
			NSMutableArray *objects = [NSMutableArray new];
			
			for (NSDictionary *objectRefInfo in objectsRef) {
				[objects addObject:[self objectIdForObjectOfEntity:request.entity withReferenceObject:[objectRefInfo valueForKey:OR_KEY_REF_REST]]];
			}
			
			if (request.resultType == NSManagedObjectResultType) {
				NSMutableArray *managedObjects = [NSMutableArray new];
				for (NSManagedObjectID *objectID in objects) {
					[managedObjects addObject:[context objectWithID:objectID]];
				}
				[objects release];
				return [managedObjects autorelease];
			} else {
				return [objects autorelease];
			}
		} break;
			
		case NSDictionaryResultType: {
			NSMutableArray *objects = [NSMutableArray new];
			
			for (NSDictionary *objectRefInfo in objectsRef) {
				[objects addObject:[[[ORToolbox sharedInstanceForPersistentStore:self] getAbsolutePath:[objectRefInfo valueForKey:OR_KEY_REF_REST]] valueForKey:OR_KEY_CONTENT]];
			}
			
			return [objects autorelease];
		} break;
			
		case NSCountResultType: {
			return [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[objectsRef count]]];
		} break;
			
		default: {
			if (error)
				*error = [NSError errorWithDomain:ORErrorDomain
											 code:ORErrorDomainCode_Unsupported_NSFetchRequestResultType
										 userInfo:nil];
			return nil;
		}
	}
	
	return [NSArray array];
}

-(id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)error {
	
	NSManagedObject *object;
	
	for (object in [request insertedObjects]) {
		[[ORToolbox sharedInstanceForPersistentStore:self] putInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[ORToolbox sharedInstanceForPersistentStore:self] dictionaryFromManagedObject:object], OR_KEY_CONTENT, nil]
													toAbsolutePath:[self referenceObjectForObjectID:object.objectID]];
	}
	
	for (object in [request updatedObjects]) {
		[[ORToolbox sharedInstanceForPersistentStore:self] putInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[ORToolbox sharedInstanceForPersistentStore:self] dictionaryFromManagedObject:object], OR_KEY_CONTENT, nil]
													toAbsolutePath:[self referenceObjectForObjectID:object.objectID]];
	}
	
	for (object in [request deletedObjects]) {
		[[ORToolbox sharedInstanceForPersistentStore:self] deleteAbsolutePath:[self referenceObjectForObjectID:object.objectID]];
	}
	
	return [NSArray array];
}

-(id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)error {
	
	switch (request.requestType) {
		case NSFetchRequestType: {
			return [self executeFetchRequest:(NSFetchRequest *)request withContext:context error:error];
		} break;
			
		case NSSaveRequestType: {
			return [self executeSaveRequest:(NSSaveChangesRequest *)request withContext:context error:error];
		} break;
				
		default: {
			
			if (error)
				*error = [NSError errorWithDomain:ORErrorDomain
											 code:ORErrorDomainCode_Unsupported_NSFetchRequestType
										 userInfo:nil];
			return nil;
		}
	}
	
	return [NSArray array];
}

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSDictionary *remoteInfos = [[[ORToolbox sharedInstanceForPersistentStore:self] getAbsolutePath:[self referenceObjectForObjectID:objectID]] valueForKey:OR_KEY_CONTENT];
	
	
	NSMutableDictionary *object = [NSMutableDictionary new];
	
	
	NSString *attribute = nil;
	
	for (attribute in [objectID.entity attributeKeys]) {
		[object setValue:[remoteInfos valueForKey:attribute] forKey:attribute];
	}
	
	NSDictionary *relationlist = [objectID.entity relationshipsByName];
	NSRelationshipDescription *relationship = nil;
	
	for (attribute in [relationlist allKeys]) {
		relationship = [relationlist valueForKey:attribute];
		if (![relationship isToMany]) {
			NSDictionary *relatedLink = [remoteInfos valueForKey:attribute];
			if (relatedLink) {
				NSManagedObjectID *objectID = [self objectIdForObjectOfEntity:relationship.destinationEntity withReferenceObject:[relatedLink valueForKey:OR_KEY_REF_REST]];
				[object setValue:objectID forKey:attribute];
			}
		}
	}
	
	return [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
												  withValues:[object autorelease]
													 version:0];
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)error {
	NSDictionary *remoteInfos = [[[ORToolbox sharedInstanceForPersistentStore:self] getAbsolutePath:[self referenceObjectForObjectID:objectID]] valueForKey:OR_KEY_CONTENT];

	if ([relationship isToMany]) {
		NSArray *relations = [remoteInfos valueForKey:relationship.name];
		
		NSMutableSet *data = [NSMutableSet new];
		
		for (NSDictionary *relatedLink in relations) {
			id referenceID = [relatedLink valueForKey:OR_KEY_REF_REST];
			NSManagedObjectID *objectID = [self objectIdForObjectOfEntity:relationship.destinationEntity withReferenceObject:referenceID];
			[data addObject:objectID];
		}
		return data;
	} else {
		NSDictionary *relatedLink = [remoteInfos valueForKey:relationship.name];
		id referenceID = [relatedLink valueForKey:OR_KEY_REF_REST];
		NSManagedObjectID *objectID = [self objectIdForObjectOfEntity:relationship.destinationEntity withReferenceObject:referenceID];
		return [objectID retain];
	}
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError **)error {
	NSMutableArray *permanentIDs = [NSMutableArray new];
	
	NSDictionary * answer;
	for (NSManagedObject *object in array) {
		answer = [[[ORToolbox sharedInstanceForPersistentStore:self] postInfo:[NSDictionary dictionary] toPath:object.entity.name] valueForKey:OR_KEY_METADATA];
		[permanentIDs addObject:[self objectIdForObjectOfEntity:object.entity withReferenceObject:[answer valueForKey:OR_KEY_REF_REST]]];
	}
	
	return [permanentIDs autorelease];
}

#pragma mark Internal Routines

- (NSManagedObjectID*)objectIdForObjectOfEntity:(NSEntityDescription*)entityDescription withReferenceObject:(id)ref {
    NSManagedObjectID *objectId = [_objectIDCache valueForKey:ref];
	if (!objectId) {
		objectId = [[self newObjectIDForEntity:entityDescription referenceObject:ref] autorelease];
	}
    if (objectId) [_objectIDCache setObject:objectId forKey:ref];
    return objectId;
}

#pragma mark - WebSocket

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString*)message {
	BOOL delete = NO;
	message = [message stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:[NSString stringWithFormat:@"%@/%@", [_serverURL absoluteString], @"x-coredata"]];
	
	if ([message rangeOfString:OR_WS_PREFIX_INSERTED].location == 0) {
		message = [message stringByReplacingCharactersInRange:NSMakeRange(0, [OR_WS_PREFIX_INSERTED length])
												   withString:@""];
	} else if ([message rangeOfString:OR_WS_PREFIX_UPDATED].location == 0) {
		message = [message stringByReplacingCharactersInRange:NSMakeRange(0, [OR_WS_PREFIX_UPDATED length])
												   withString:@""];
	} else if ([message rangeOfString:OR_WS_PREFIX_DELETED].location == 0) {
		message = [message stringByReplacingCharactersInRange:NSMakeRange(0, [OR_WS_PREFIX_DELETED length])
												   withString:@""];
		delete = YES;
	}
	
//	NSArray *pathComonents = [message pathComponents];
//	if ([pathComonents count] > 1) {
//		NSString *entityName = [pathComonents objectAtIndex:[pathComonents count] - 2];
//		[self objectIdForObjectOfEntity:[NSEntityDescription entityForName:entityName
//													inManagedObjectContext:<#(NSManagedObjectContext *)#>] withReferenceObject:<#(id)#>]
//	}
}

@end
