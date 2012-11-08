//
//  ORToolbox.m
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORToolbox.h"

#import "ORNoCacheStoreNode.h"
#import "ORNoCacheStore.h"

@implementation ORToolbox
@synthesize serverURL = _serverURL, negociatedContentType = _negociatedContentType;

+ (ORToolbox*)sharedInstance {
    static ORToolbox* sharedInstanceORToolbox = nil;
    if (!sharedInstanceORToolbox) sharedInstanceORToolbox = [ORToolbox new];
    return sharedInstanceORToolbox;
}

+ (ORToolbox*)sharedInstanceForPersistentStore:(NSPersistentStore*)store {
    static NSMutableDictionary* sharedInstanceORToolboxList = nil;
    if (!sharedInstanceORToolboxList) sharedInstanceORToolboxList = [NSMutableDictionary new];
    
    ORToolbox *instance = [sharedInstanceORToolboxList valueForKey:[store identifier]];
    
    if (!instance) {
        instance = [[ORToolbox new] autorelease];
        instance->_associatedStore = store;
        [sharedInstanceORToolboxList setValue:instance forKey:[store identifier]];
    }
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _acceptedContentType = [OR_SUPPORTED_CONTENT_TYPE retain];
    }
    return self;
}

- (void)dealloc {
    [_acceptedContentType release];
    [super dealloc];
}

#pragma mark - Routines

- (NSString*)acceptedContentType {
    NSMutableString *str = [NSMutableString new];
    NSInteger i = [_acceptedContentType count];
    for (NSInteger j = 0; j < i; j++) {
        [str appendString:[_acceptedContentType objectAtIndex:j]];
        if (j < i - 1) [str appendString:@","];
    }
    
    return [str autorelease];
}

-(NSString *)negociatedContentType {
    if ([_negociatedContentType length] > 0) {
        return _negociatedContentType;
    }
    
    return [_acceptedContentType objectAtIndex:0];
}

- (NSString*)absoluteVersionForPath:(NSString*)path {
    return [[_serverURL URLByAppendingPathComponent:path] absoluteString];
}

- (NSMutableURLRequest*)baseRequestForPath:(NSString*)path {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
	
    [req setValue:[self acceptedContentType] forHTTPHeaderField:@"Accept"];
    
	
	[req setValue:[NSString stringWithFormat:@"%@:%@", [_serverURL host], [_serverURL port]] forHTTPHeaderField:@"Host"];
    
	/*if (self.requestAuthentication) {
     if(self.useDigest) {
     
     } else {
     [req setValue:[NSString stringWithFormat:@"Basic %@", 
     [[NSString stringWithFormat:@"%@:%@",
     self.username,
     self.password]
     RESTbase64EncodedString]]
     forHTTPHeaderField:@"Authorization"];
     }
     }*/
    
    return req;
}

#pragma mark REST Client

- (NSDictionary*)postInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
    
	[req setHTTPMethod:@"POST"];
	
    NSData *body = [self preparedResponseFromDictionary:info];
    
	[req setHTTPBody:body];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
    [req setValue:[[NSNumber numberWithUnsignedInteger:[body length]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSDictionary*)postInfo:(NSDictionary*)info toPath:(NSString*)path {
    return [self postInfo:info toAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSDictionary*)putInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"PUT"];
	
    NSData *body = [self preparedResponseFromDictionary:info];
    
	[req setHTTPBody:body];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
    [req setValue:[[NSNumber numberWithUnsignedInteger:[body length]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSDictionary*)putInfo:(NSDictionary*)info toPath:(NSString*)path {
    return [self putInfo:info toAbsolutePath:[self absoluteVersionForPath:path]];
}

- (void)deleteAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"DELETE"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	[NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
}

- (void)deletePath:(NSString*)path {
    [self deleteAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path {
	return [self getAbsolutePath:path withHTTPHeader:nil];
}

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path withHTTPHeader:(NSDictionary*)headers {
	NSMutableDictionary *dict = nil;
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	for (NSString *key in headers) {
		[req setValue:[headers valueForKey:key] forHTTPHeaderField:key];
	}
    
    [req setHTTPMethod:@"GET"];

    NSHTTPURLResponse *rep = nil;
    NSError *err = nil;
    
    NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
    self.negociatedContentType = [[rep allHeaderFields] valueForKey:@"content-type"];
    
    dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSMutableDictionary*)getPath:(NSString*)path {
	return [self getAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSArray*)getAllObjectOfThisEntityKind:(NSString*)path {
	if ([path rangeOfString:@"x-coredata"].location == NSNotFound) {
		// REST Ready database
		return [[self getAbsolutePath:[path stringByDeletingLastPathComponent]] valueForKey:@"content"];
	} else {
		// Standard database
		NSArray *compo = [path pathComponents];
        
		return [[self getPath:[NSString stringWithFormat:@"/%@", [compo objectAtIndex:[compo count] -2]]] valueForKey:@"content"];
	}
	return nil;
}

- (NSArray*)getObjectsForFetchRequest:(NSFetchRequest*)request {
	NSDictionary *headers = nil;
	if ([request.predicate predicateFormat]) {
		headers = [NSDictionary dictionaryWithObject:[request.predicate predicateFormat]
											  forKey:@"NSPredicate"];
	}
	return [[self getAbsolutePath:[self absoluteVersionForPath:request.entityName]
				   withHTTPHeader:headers]
			valueForKey:@"content"];
}

#pragma mark - NSDictionary for REST

- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict {
	NSString *errorString = nil;
	
	if ([[self negociatedContentType] isEqualToString:@"application/x-bplist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	else if ([[self negociatedContentType] isEqualToString:@"application/x-plist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	else if ([[self negociatedContentType] isEqualToString:@"application/json"]) 
        return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
	else
		return nil;
}

- (NSDictionary*)dictionaryFromResponse:(NSData*)response {
	NSDictionary *dict = nil;
	NSString *errString = nil;
	if ([[self negociatedContentType] isEqualToString:@"application/x-bplist"] || [[self negociatedContentType] isEqualToString:@"application/x-plist"]) 
		dict = [NSPropertyListSerialization propertyListFromData:response
                                                mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                          format:nil
                                                errorDescription:&errString];
	
	else if ([[self negociatedContentType] isEqualToString:@"application/json"]) {
        dict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
	}
	
	return dict;
}

#pragma mark - NSManagedObject / NSDictionary

- (NSMutableDictionary*)dictionaryFromManagedObject:(NSManagedObject*)object {
    
    NSManagedObjectID *objectID = object.objectID;
    NSEntityDescription *entityDescription = objectID.entity;
    
    NSDictionary *relationList = [entityDescription relationshipsByName];
    NSDictionary *attributeList = [entityDescription attributesByName];
    
    NSRelationshipDescription *relation = nil;
    NSSet *relations;
    NSMutableArray *relationsLink;
    NSManagedObject *relationObject = nil;
    NSString *referenceID;
    
    id value;
    
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionaryWithCapacity:[attributeList count]  + [relationList count]];
    
    for (NSString *relationName in [relationList allKeys]) {
        relation = [relationList valueForKey:relationName];
        
        if ([relation isToMany]) {
            relations = [object valueForKey:relationName];
            relationsLink = [NSMutableArray arrayWithCapacity:[relations count]];
            for (relationObject in relations) {
                referenceID = [_associatedStore referenceObjectForObjectID:relationObject.objectID];
                [relationsLink addObject:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD]];
            }
            [returnDict setValue:relationsLink forKey:relationName];
        } else {
            relationObject = [object valueForKey:relationName];
            referenceID = [_associatedStore referenceObjectForObjectID:relationObject.objectID];
            [returnDict setValue:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD] forKey:relationName];
        }
    }
    
    for (NSString *attribute in [attributeList allKeys]) {
		value = [object valueForKey:attribute];
		if (value)
			[returnDict setObject:value forKey:attribute];
	}
    
    return returnDict;
}

#pragma mark - NSAtomicStore

- (NSMutableDictionary*)saveOperationForNode:(ORNoCacheStoreNode*)node needBashMode:(BOOL*)bash sharedNewNodeList:(NSMutableDictionary**)sharedNewNodeList{
    if (!node.ORNodeIsDirty) {
        return nil;
    }
    
    NSMutableDictionary *newNodeList = [NSMutableDictionary new];
    NSManagedObjectID *objectID = node.objectID;
    ORNoCacheStore *persistentStore = (ORNoCacheStore *)objectID.persistentStore;
    NSEntityDescription *entityDescription = objectID.entity;
    
    NSDictionary *relationList = [entityDescription relationshipsByName];
    NSDictionary *attributeList = [entityDescription attributesByName];
    
    NSRelationshipDescription *relation = nil;
    NSSet *relations;
    NSMutableArray *relationsLink;
    ORNoCacheStoreNode *relationNode = nil;
    NSString *referenceID;
    
    id value;
    
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionaryWithCapacity:[attributeList count]  + [relationList count]];
    
    for (NSString *relationName in [relationList allKeys]) {
        relation = [relationList valueForKey:relationName];
        
        if ([relation isToMany]) {
            relations = [node valueForKey:relationName];
            relationsLink = [NSMutableArray arrayWithCapacity:[relations count]];
            for (relationNode in relations) {
                referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
                if ([referenceID rangeOfString:@"tmp://"].location == 0) {
                    if (![*sharedNewNodeList valueForKey:referenceID]) {
                        [*sharedNewNodeList setValue:relationNode forKey:referenceID];
                        [newNodeList setValue:relationNode forKey:referenceID];
                    }
                }
                [relationsLink addObject:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD]];
            }
        } else {
            relationNode = [node valueForKey:relationName];
            referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
            if ([referenceID rangeOfString:@"tmp://"].location == 0) {
                if (![*sharedNewNodeList valueForKey:referenceID]) {
                    [*sharedNewNodeList setValue:relationNode forKey:referenceID];
                    [newNodeList setValue:relationNode forKey:referenceID];
                }
            }
            [returnDict setValue:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD] forKey:relationName];
        }
    }
    
    for (NSString *attribute in [attributeList allKeys]) {
		value = [node valueForKey:attribute];
		if (value)
			[returnDict setObject:value forKey:attribute];
	}
    
    relationNode.ORNodeIsDirty = NO;
    
    if ([newNodeList count] > 0) {
        *bash = YES;
        // Special kind of POST method for bunch creation of new object.
        
        /*
         The content look like:
         entityA:tmpObjectLink:{infos}
         object link for new object are tmp://Entity/UUID
         */
        
        NSMutableDictionary *dictForSelectedEntity, *nestedSaveInfo;
        NSMutableDictionary *originalDict = returnDict;
        
        BOOL bashAgain = NO;
        
        returnDict = [NSMutableDictionary dictionary];
        
        for (NSString *objectURLString in [newNodeList allKeys]) {
            bashAgain = NO;
            relationNode = [newNodeList valueForKey:objectURLString];
            nestedSaveInfo = [self saveOperationForNode:relationNode needBashMode:&bashAgain sharedNewNodeList:sharedNewNodeList];
            if (nestedSaveInfo) {
                if (bashAgain) {
                    
                    for (NSString *nestedEntityString in [nestedSaveInfo allKeys]) {
                        dictForSelectedEntity = [returnDict valueForKey:nestedEntityString];
                        if (!dictForSelectedEntity) {
                            dictForSelectedEntity = [NSMutableDictionary dictionary];
                            [returnDict setValue:dictForSelectedEntity forKey:nestedEntityString];
                        }
                        [dictForSelectedEntity addEntriesFromDictionary:[nestedSaveInfo valueForKey:nestedEntityString]];
                    }
                    
                    
                } else {
                    dictForSelectedEntity = [returnDict valueForKey:relationNode.objectID.entity.name];
                    if (!dictForSelectedEntity) {
                        dictForSelectedEntity = [NSMutableDictionary dictionary];
                        [returnDict setValue:dictForSelectedEntity forKey:relationNode.objectID.entity.name];
                    }
                    [dictForSelectedEntity setValue:nestedSaveInfo forKey:[persistentStore referenceObjectForObjectID:objectID]];
                }
            }
        }
        
        
        dictForSelectedEntity = [returnDict valueForKey:objectID.entity.name];
        if (!dictForSelectedEntity) {
            dictForSelectedEntity = [NSMutableDictionary dictionary];
            [returnDict setValue:dictForSelectedEntity forKey:objectID.entity.name];
        }
        [dictForSelectedEntity setValue:originalDict forKey:[persistentStore referenceObjectForObjectID:objectID]];
    } else {
        *bash = NO;
    }
    
    [newNodeList release];
    
    return returnDict;
}


- (NSMutableDictionary*)saveOperationForNode:(ORNoCacheStoreNode*)node {
    if (!node.ORNodeIsDirty) {
        return nil;
    }
    
    NSManagedObjectID *objectID = node.objectID;
    ORNoCacheStore *persistentStore = (ORNoCacheStore *)objectID.persistentStore;
    NSEntityDescription *entityDescription = objectID.entity;
    
    NSDictionary *relationList = [entityDescription relationshipsByName];
    NSDictionary *attributeList = [entityDescription attributesByName];
    
    NSRelationshipDescription *relation = nil;
    NSSet *relations;
    NSMutableArray *relationsLink;
    ORNoCacheStoreNode *relationNode = nil;
    NSString *referenceID;
    
    id value;
    
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionaryWithCapacity:[attributeList count]  + [relationList count]];
    
    for (NSString *relationName in [relationList allKeys]) {
        relation = [relationList valueForKey:relationName];
        
        if ([relation isToMany]) {
            relations = [node valueForKey:relationName];
            relationsLink = [NSMutableArray arrayWithCapacity:[relations count]];
            for (relationNode in relations) {
                referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
                [relationsLink addObject:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD]];
            }
            [returnDict setValue:relationsLink forKey:relationName];
        } else {
            relationNode = [node valueForKey:relationName];
            referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
            [returnDict setValue:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD] forKey:relationName];
        }
    }
    
    for (NSString *attribute in [attributeList allKeys]) {
		value = [node valueForKey:attribute];
		if (value)
			[returnDict setObject:value forKey:attribute];
	}
    
    return returnDict;
}


- (BOOL)saveNode:(ORNoCacheStoreNode*)node {
    BOOL bash = NO;
    NSMutableDictionary *sharedNewNodeList = [NSMutableDictionary new];
    NSDictionary *dict = [self saveOperationForNode:node needBashMode:&bash sharedNewNodeList:&sharedNewNodeList];
    if (dict) {
        if (bash) {
            [self postInfo:dict toPath:@""];
        } else {
            ORNoCacheStore *persistentStore = (ORNoCacheStore *)node.objectID.persistentStore;
            NSString *referenceID = [persistentStore referenceObjectForObjectID:node.objectID];
            if ([referenceID rangeOfString:@"tmp://"].location == 0) {
                [self postInfo:dict toPath:node.objectID.entity.name];
            } else {
                [self putInfo:dict toAbsolutePath:referenceID];
            }
        }
    }
    
    [sharedNewNodeList release];
    return YES;
}

- (BOOL)saveNodes:(NSSet*)nodes {
    
    NSMutableDictionary *postInfo = [NSMutableDictionary new];
    NSMutableDictionary *nodeList = [NSMutableDictionary new];
    ORNoCacheStore *persistentStore = nil;
    NSString *referenceID = nil;
    
    NSSet *filteredNodes = [nodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.ORNodeIsDirty == TRUE"]];
    
    for (ORNoCacheStoreNode *node in filteredNodes) {
        persistentStore = (ORNoCacheStore *)node.objectID.persistentStore;
        referenceID = [persistentStore referenceObjectForObjectID:node.objectID];
        if (![postInfo valueForKey:referenceID]) {
            [nodeList setValue:node forKey:referenceID];
            [postInfo setValue:[self saveOperationForNode:node] forKey:referenceID];
        }
    }
    
    NSDictionary *answer = [self postInfo:[NSDictionary dictionaryWithObject:postInfo forKey:@"content"] toPath:@""];
    NSString *objectServerID;
    for (NSString *objectClientID in [[answer valueForKey:@"content"] allKeys]) {
        objectServerID = [[answer valueForKey:@"content"] valueForKey:objectClientID];
        ((ORNoCacheStoreNode*)[nodeList valueForKey:objectClientID]).remoteURL = objectServerID;
        ((ORNoCacheStoreNode*)[nodeList valueForKey:objectClientID]).ORNodeIsDirty = NO;
    }
	
	[postInfo release];
	[nodeList release];
    
    return YES;
}

@end
