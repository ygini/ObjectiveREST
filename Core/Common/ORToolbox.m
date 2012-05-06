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
	
	[req setHTTPBody:[self preparedResponseFromDictionary:info]];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
	
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
	
	[req setHTTPBody:[self preparedResponseFromDictionary:info]];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
	
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
	NSMutableDictionary *dict = nil;
	NSMutableURLRequest *req = [self baseRequestForPath:path];
    
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

#pragma mark - NSAtomicStore

- (NSMutableDictionary*)saveOperationForNode:(ORNoCacheStoreNode*)node needBashMode:(BOOL*)bash{
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
                relationNode = [node valueForKey:relationName];
                referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
                if ([referenceID rangeOfString:@"tmp://"].location == 0) {
                    [newNodeList setValue:relationNode forKey:referenceID];
                }
                [relationsLink addObject:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD]];
            }
        } else {
            relationNode = [node valueForKey:relationName];
            referenceID = [persistentStore referenceObjectForObjectID:relationNode.objectID];
            if ([referenceID rangeOfString:@"tmp://"].location == 0) {
                [newNodeList setValue:relationNode forKey:referenceID];
            }
            [returnDict setValue:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD] forKey:relationName];
        }
    }
    
    for (NSString *attribute in [attributeList allKeys]) {
		value = [node valueForKey:attribute];
		if (value)
			[returnDict setObject:value forKey:attribute];
	}
    
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
            nestedSaveInfo = [self saveOperationForNode:relationNode needBashMode:&bashAgain];
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

- (void)saveNode:(ORNoCacheStoreNode*)node {
    BOOL bash = NO;
    NSDictionary *dict = [self saveOperationForNode:node needBashMode:&bash];
    
    if (bash) {
        [self postInfo:dict toPath:@"/"];
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

@end
