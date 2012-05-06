//
//  ORServerConnection.m
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORServerConnection.h"

#import "ORServer.h"
#import "ORProtocols.h"

#import "ORHTTPDataResponse.h"

#import <CocoaHTTPServer/HTTPDataResponse.h>

@interface ORServerConnection ()
- (NSObject<HTTPResponse> *)methodGETWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents;
- (NSObject<HTTPResponse> *)methodPUTWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents;
- (NSObject<HTTPResponse> *)methodPOSTWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents;
- (NSObject<HTTPResponse> *)methodDELETEWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents;
- (HTTPDataResponse*)httpResponseWithData:(NSData*)data;
- (HTTPDataResponse*)httpResponseWithDictionary:(NSDictionary*)dict;

- (NSArray*)entities;

- (NSArray*)managedObjectWithEntityName:(NSString*)name;
- (NSManagedObject <ORManagedObject> *)managedObjectWithEntityName:(NSString*)name andRESTUUID:(NSString*)uniqueID;
- (NSManagedObject <ORManagedObject> *)managedObjectWithRelativePath:(NSString*)path;
- (NSManagedObject <ORManagedObject> *)managedObjectWithAbsolutePath:(NSString*)path;
- (void)updateManagedObject:(NSManagedObject*)object withInfo:(NSDictionary*)infos;
- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict;
- (NSDictionary*)dictionaryFromResponse:(NSData*)response;

- (NSString*)baseURLForURIWithServerAddress:(NSString*)serverAddress;
- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forEntityWithName:(NSString*)name;
- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object;
- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object onRESTReadyObjectModel:(BOOL)RESTReady;
- (NSDictionary*)restLinkRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object;
- (NSManagedObject<ORManagedObject>*)insertNewObjectForEntityForName:(NSString*)entityString;
- (NSDictionary *)dictionaryRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject *)object;
@end

@implementation ORServerConnection

#pragma mark - Memory Management

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
	if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
		NSAssert([config.server isKindOfClass:[ORServer class]],
				 @"A RoutingConnection is being used with a server that is not a ORServer");
        
		_httpServer = (ORServer *)config.server;
	}
	return self;
}


#pragma mark - Main routing method

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSObject<HTTPResponse> * returnHTTPResponse = nil;
    
    // -- Redirect request
	NSMutableArray *pathComponents = [NSMutableArray new];
	// Cleaning path for double /
	path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
    
    NSInteger numberOfComponents = [pathComponents count];
    
    BOOL requestIsForCoreData = NO;
    if ([_httpServer.prefixForREST length] > 0) {
        if (numberOfComponents > 0) {
            if ([_httpServer.prefixForREST isEqualToString:[pathComponents objectAtIndex:0]]) {
                path = [path stringByReplacingCharactersInRange:(NSRange) {0, [_httpServer.prefixForREST length]+1}
                                                     withString:@""];
                [pathComponents removeObjectAtIndex:0];
                numberOfComponents = [pathComponents count];
                requestIsForCoreData =  YES;
            } else requestIsForCoreData = NO;
        } else requestIsForCoreData = NO;
    } else requestIsForCoreData =  YES;
    // -- End Redirect request
    
    
    if (requestIsForCoreData) {
        @try {
            NSArray *acceptedContentType = [[request headerField:@"Accept"] componentsSeparatedByString:@","];
            if ([acceptedContentType count] == 0) acceptedContentType = [[request headerField:@"Content-Type"] componentsSeparatedByString:@","];
            
            
            NSMutableArray *retainedContentType = [NSMutableArray new];
            for (NSString *contentType in OR_SUPPORTED_CONTENT_TYPE) {
                if ([acceptedContentType containsObject:contentType]) [retainedContentType addObject:contentType];
            }
            
            if ([retainedContentType count] == 0) _requestedContentType = nil;
            else _requestedContentType = [retainedContentType objectAtIndex:0];
            
            retainedContentType = nil;
            
            
            if (!_requestedContentType) { 
                // Error 501
            } else {			
                
                if ([method isEqualToString:@"GET"]) {
                    returnHTTPResponse = [self methodGETWithPath:path andPathCompontents:pathComponents];
                } else if ([method isEqualToString:@"POST"]) {
                    returnHTTPResponse = [self methodPOSTWithPath:path andPathCompontents:pathComponents];
                } else if ([method isEqualToString:@"PUT"]) {
                    returnHTTPResponse = [self methodPUTWithPath:path andPathCompontents:pathComponents];
                } else if ([method isEqualToString:@"DELETE"]) {
                    returnHTTPResponse = [self methodDELETEWithPath:path andPathCompontents:pathComponents];
                } else {
                    // Unknow method
                }
                
            }		
        }
        @catch (NSException *exception) {
            // Error 500
        }

    } else if ([_httpServer.externalAPIDelegate respondsToSelector:@selector(httpResponseForMethod:URI:andHTTPRequest:)]) {
        returnHTTPResponse = [_httpServer.externalAPIDelegate httpResponseForMethod:method URI:path andHTTPRequest:request];
    }
    
    
    if (returnHTTPResponse) {
        return returnHTTPResponse;
    }
    
	return [super httpResponseForMethod:method URI:path];
}

#pragma mark - Private request handling

- (NSObject<HTTPResponse> *)methodGETWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents {
    NSObject<HTTPResponse> * returnObject = nil;
    NSInteger numberOfComponents = [pathComponents count];
    if (numberOfComponents == 0) {
        // No entity name provided, return the list of entry
        
        NSMutableArray *entitiesRESTRefs = [NSMutableArray new];
        for (NSString *entity in [self entities]) {
            [entitiesRESTRefs addObject:[NSDictionary dictionaryWithObject:[self restURIWithServerAddress:[request headerField:@"Host"] forEntityWithName:entity] forKey:OR_REF_KEYWORD]];
        }
        
        NSPersistentStore *persistentStore = [[_httpServer.dataProvider persistentStoreCoordinator] persistentStoreForURL:[_httpServer.dataProvider persistentStoreURL]];
        
        returnObject = [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:entitiesRESTRefs, @"content", [persistentStore metadata], @"metadata", nil]];
        [entitiesRESTRefs release];
    } else {
        NSString *selectedEntity = [pathComponents objectAtIndex:0];
        
        if (numberOfComponents == 1 && [[self entities] indexOfObject:selectedEntity] != NSNotFound) {
            // return the list of entry for the kind of requested entity
            
            NSArray *entries = [self managedObjectWithEntityName:selectedEntity];
            NSMutableArray *entriesRESTRefs = [NSMutableArray new];
            
            for (NSManagedObject <ORManagedObject> *entry in entries) {						
                [entriesRESTRefs addObject:[self restLinkRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:entry]];
            }
            
            returnObject = [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:entriesRESTRefs, @"content", nil]];
            [entriesRESTRefs release];
        } else {
            // return the selected entity
            returnObject = [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [self dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] 
                                                                                            forManagedObject:[self managedObjectWithRelativePath:path]], @"content", nil]];
        }
    }
    
    return returnObject;
}

- (NSObject<HTTPResponse> *)methodPUTWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents {
    NSInteger numberOfComponents = [pathComponents count];
    if ([pathComponents count] == 0) {
        // No entity name provided
        return nil;
    } else if ([[request body] length] > 0) {
        
        NSString *selectedEntity = [pathComponents objectAtIndex:0];
        
        if (numberOfComponents == 1 && [[self entities] indexOfObject:selectedEntity] != NSNotFound) {
            // No PUT on collection, use POST instead
            return nil;
        } else {
            NSManagedObject *entry = [self managedObjectWithRelativePath:path];
            
            if (!entry && [_httpServer managedObjectModelIsRESTReady]) {
                entry = [self insertNewObjectForEntityForName:selectedEntity];
                // Code 201
            }
            
            if (entry) {
                NSDictionary *dict = [[self dictionaryFromResponse:[request body]] valueForKey:@"content"];
                
                [self updateManagedObject:entry withInfo:dict];
                
                // Code 200
                return [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[self dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:entry], @"content", nil]];
            } else {
                // return invalide reequest code when PUT is used to create a new object with specific ID and standard CoreData model
                // Code 501?
                return nil;
            }
        }
    }
    
    return nil;
}

- (NSObject<HTTPResponse> *)methodPOSTWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents {
    NSInteger numberOfComponents = [pathComponents count];
    if (numberOfComponents == 1 && [[self entities] indexOfObject:[pathComponents objectAtIndex:0]] != NSNotFound && [[request body] length] > 0) {   
        // Normal POST method, the entity is specified in the URL.
        NSString *entityString = [pathComponents objectAtIndex:0];
        
        NSManagedObject <ORManagedObject> *newObject = [self insertNewObjectForEntityForName:entityString];
        
        NSDictionary *dict = [[self dictionaryFromResponse:[request body]] valueForKey:@"content"];
        
        [self updateManagedObject:newObject withInfo:dict];
        // 201
        
        return [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[self dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:newObject], @"content", nil]];
    } else {
        // Special kind of POST method for bunch creation of new object.
        
        /*
         The content look like:
         content:entityA:tmpObjectLink:{infos}
         object link for new object are tmp://Entity/UUID
         */
        
        NSDictionary *bashUpdatesOrCreations = [[self dictionaryFromResponse:[request body]] valueForKey:@"content"];
        NSDictionary *infos = nil;
        NSMutableDictionary *cache = [NSMutableDictionary new];
        NSMutableDictionary *operations = [NSMutableDictionary new];
        NSManagedObject <ORManagedObject> *object = nil;
        
        for (NSString *entityString in [bashUpdatesOrCreations allKeys]) {
            infos = [bashUpdatesOrCreations valueForKey:entityString];
            for (NSString *objectURLString in [infos allKeys]) {
                if ([objectURLString rangeOfString:@"tmp://"].location == 0) {
                    // New object
                    object = [self insertNewObjectForEntityForName:entityString];
                } else {
                    // Existing object
                    object = [self managedObjectWithAbsolutePath:objectURLString];
                }
                [cache setValue:object forKey:objectURLString];
                [operations setValue:[infos valueForKey:objectURLString] forKey:objectURLString];
            }
        }
        
        for (NSString *objectURLString in cache) {
            object = [cache valueForKey:objectURLString];
            infos = [operations valueForKey:objectURLString];
            
            
            id value = nil;
            for (NSString *supportedKey in [[[object entity] attributesByName] allKeys]) {
                value = [infos valueForKey:supportedKey];
                if (value) [object setValue:value forKey:supportedKey];
            }
            
            NSRelationshipDescription *relation = nil;
            for (NSString *supportedKey in [[[object entity] relationshipsByName] allKeys]) {
                if (value) {
                    value = [infos valueForKey:supportedKey];
                    relation = [[[object entity] relationshipsByName] valueForKey:supportedKey];
                    
                    if ([relation isToMany]) {
                        NSSet *representedSet = value;
                        
                        NSMutableSet *uptodateSet = [NSMutableSet setWithCapacity:[representedSet count]];
                        
                        for (NSDictionary *relationInfo in representedSet) {
                            [uptodateSet addObject:[cache valueForKey:[relationInfo valueForKey:OR_REF_KEYWORD]]];
                        }
                        
                        [object willChangeValueForKey:supportedKey];
                        [object setPrimitiveValue:uptodateSet forKey:supportedKey];
                        [object didChangeValueForKey:supportedKey];
                        
                    } else [object setValue:[cache valueForKey:[value valueForKey:OR_REF_KEYWORD]] forKey:supportedKey];
                }
            }
        }
        
        NSMutableArray *entriesRESTRefs = [NSMutableArray new];
        
        for (NSManagedObject <ORManagedObject> *entry in [cache allValues]) {						
            [entriesRESTRefs addObject:[self restLinkRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:entry]];
        }
        
        [cache release];
        [operations release];
        
        return [self httpResponseWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]];
    }
    return nil;
}

- (NSObject<HTTPResponse> *)methodDELETEWithPath:(NSString*)path andPathCompontents:(NSArray*)pathComponents {
    NSInteger numberOfComponents = [pathComponents count];
    if ([pathComponents count] == 0) {
        // No entity name provided
        
    } else {
        
        NSString *selectedEntity = [pathComponents objectAtIndex:0];
        
        if (numberOfComponents == 1 && [[self entities] indexOfObject:selectedEntity] != NSNotFound) {
            // Delete all entities ?
            if (_httpServer.allowDeleteOnCollection) {
                NSString *selectedEntity = [pathComponents objectAtIndex:0];
                NSArray *entries = [self managedObjectWithEntityName:selectedEntity];
                
                for (NSManagedObject *entry in entries) {
                    [_httpServer.dataProvider.managedObjectContext deleteObject:entry];
                }
                // 200
            } else {
                // 501
            }
        } else {						
            [_httpServer.dataProvider.managedObjectContext deleteObject:[self managedObjectWithRelativePath:path]];
            // 201
        }
    }
    return nil;
}

- (HTTPDataResponse*)httpResponseWithData:(NSData*)data {
    ORHTTPDataResponse *response = [[ORHTTPDataResponse alloc] initWithData:data];
    [[response httpHeaders] setValue:_requestedContentType forKey:@"Content-Type"];
    return [response autorelease];
}

- (HTTPDataResponse*)httpResponseWithDictionary:(NSDictionary*)dict {
    return [self httpResponseWithData:[self preparedResponseFromDictionary:dict]];
}

#pragma mark - CoreData

- (NSArray*)entities {
    return [[[_httpServer.dataProvider.managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray*)managedObjectWithEntityName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[_httpServer.dataProvider.managedObjectContext executeFetchRequest:fetchRequest error:&err] sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject<ORManagedObject>* obj1, NSManagedObject<ORManagedObject>* obj2) {
		if ([obj1 respondsToSelector:@selector(compare:)])
			return [obj1 compare:obj2];
		return [[[[obj1 objectID] URIRepresentation] absoluteString] compare:[[[obj2 objectID] URIRepresentation] absoluteString]];
	}];
}

- (NSManagedObject <ORManagedObject> *)managedObjectWithEntityName:(NSString*)name andRESTUUID:(NSString*)uniqueID {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	[req setPredicate:[NSPredicate predicateWithFormat:@"SELF.ORUniqueID like %@", uniqueID]];
	NSArray *answer = [_httpServer.dataProvider.managedObjectContext executeFetchRequest:req error:&err];
	if ([answer count] > 0)
		return [answer objectAtIndex:0];
	else return nil;
}

- (NSManagedObject <ORManagedObject> *)managedObjectWithRelativePath:(NSString*)path {
	NSManagedObject <ORManagedObject> *entry = nil;
	NSError *error = nil;
	NSMutableArray *pathComponents = [NSMutableArray new];
	NSArray *entities = [[[_httpServer.dataProvider.managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	// Cleaning path for double /
	path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
	
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
	
	NSString *selectedEntity = [pathComponents objectAtIndex:0];
	
	//if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
    if ([selectedEntity isEqualToString:@"x-coredata"]) {
		// Update entity from CoreData URI
		NSString *coreDataUniqueID = [path stringByReplacingOccurrencesOfString:@"/x-coredata" withString:@"x-coredata:/"];
		
		entry =  (NSManagedObject <ORManagedObject> *)[_httpServer.dataProvider.managedObjectContext objectWithID:
                  [_httpServer.dataProvider.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:coreDataUniqueID]]];
		
		if ([entry isFault]) {
			
			
			NSFetchRequest *validityRequest = [[NSFetchRequest alloc] init];
			[validityRequest setEntity:[entry entity]];
			
			[validityRequest setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] 
                                                                             rightExpression:[NSExpression expressionForConstantValue:entry]
                                                                                    modifier:NSDirectPredicateModifier
                                                                                        type:NSEqualToPredicateOperatorType 
                                                                                     options:0]];
			
			NSArray *results = [_httpServer.dataProvider.managedObjectContext executeFetchRequest:validityRequest error:&error];
			[validityRequest release];
            
			if ([results count] > 0) {   
				entry = [results objectAtIndex:0];
			}
		}							
	} else if ([entities indexOfObject:selectedEntity] != NSNotFound) {
		// Update entity from REST UUID
		entry = [self managedObjectWithEntityName:[pathComponents objectAtIndex:0] andRESTUUID:[pathComponents objectAtIndex:1]];
	}
    [pathComponents release];
	return entry;
}

- (NSManagedObject <ORManagedObject> *)managedObjectWithAbsolutePath:(NSString*)path {
	return [self managedObjectWithRelativePath:[[NSURL URLWithString:path] relativePath]];
}

- (void)updateManagedObject:(NSManagedObject*)object withInfo:(NSDictionary*)infos {
	id value = nil;
	NSError *error = nil;
	for (NSString *supportedKey in [[[object entity] attributesByName] allKeys]) {
		value = [infos valueForKey:supportedKey];
		if (value) [object setValue:value forKey:supportedKey];
	}
	
	NSRelationshipDescription *relation = nil;
	for (NSString *supportedKey in [[[object entity] relationshipsByName] allKeys]) {
		if (value) {
			value = [infos valueForKey:supportedKey];
			relation = [[[object entity] relationshipsByName] valueForKey:supportedKey];
			
			if ([relation isToMany]) {
				NSSet *representedSet = value;
				
				NSMutableSet *uptodateSet = [NSMutableSet setWithCapacity:[representedSet count]];
				
				for (NSDictionary *relationInfo in representedSet) {
					[uptodateSet addObject:[self managedObjectWithAbsolutePath:[relationInfo valueForKey:OR_REF_KEYWORD]]];
				}
				
				[object willChangeValueForKey:supportedKey];
				[object setPrimitiveValue:uptodateSet forKey:supportedKey];
				[object didChangeValueForKey:supportedKey];
				
			} else [object setValue:[self managedObjectWithAbsolutePath:[value valueForKey:OR_REF_KEYWORD]] forKey:supportedKey];
		}
	}
	
	[_httpServer.dataProvider.managedObjectContext save:&error];
}


- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict {
	NSString *errorString = nil;
	NSError *error = nil;
    NSData *returnData = nil;
	
	if ([_requestedContentType isEqualToString:@"application/x-bplist"]) 
		returnData = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	else if ([_requestedContentType isEqualToString:@"application/x-plist"]) 
		returnData = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	else if ([_requestedContentType isEqualToString:@"application/json"]) 
        returnData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];

    return returnData;
}

- (NSDictionary*)dictionaryFromResponse:(NSData*)response {
	NSDictionary *dict = nil;
	NSString *errString = nil;
	if ([_requestedContentType isEqualToString:@"application/x-bplist"] || [_requestedContentType isEqualToString:@"application/x-plist"]) 
		dict = [NSPropertyListSerialization propertyListFromData:response
                                                mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                          format:nil
                                                errorDescription:&errString];
	
	else if ([_requestedContentType isEqualToString:@"application/json"]) {
        dict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
	}
	
	return dict;
}

- (NSString*)baseURLForURIWithServerAddress:(NSString*)serverAddress {
    if ([_httpServer.prefixForREST length] > 0) {
        return [NSString stringWithFormat:@"%@://%@/%@", _httpServer.useSSL ? @"https" : @"http" , serverAddress, _httpServer.prefixForREST];
    }
    return [NSString stringWithFormat:@"%@://%@", _httpServer.useSSL ? @"https" : @"http" , serverAddress];
}

- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forEntityWithName:(NSString*)name {
    return [NSString stringWithFormat:@"%@/%@", [self baseURLForURIWithServerAddress:serverAddress], name];
}

- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object {
    return [self restURIWithServerAddress:serverAddress forManagedObject:object onRESTReadyObjectModel:[_httpServer managedObjectModelIsRESTReady]];
}

- (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object onRESTReadyObjectModel:(BOOL)RESTReady {
	NSError *error = nil;
	if (RESTReady) {
		// If the data model has been patched, we use dedicated UUID to make URI
		return [NSString stringWithFormat:@"%@/%@/%@", [self baseURLForURIWithServerAddress:serverAddress], [[object entity] name], [object ORUniqueID]];
	} else {
		// If the data model isn't patched to be compatible with ObjectiveREST, we fall back on CoreData ID…
		if ([[object objectID] isTemporaryID]) {
			[_httpServer.dataProvider.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:object] error:&error];
		}
        
		return [NSString stringWithFormat:@"%@/%@", [self baseURLForURIWithServerAddress:serverAddress], [[[[object objectID] URIRepresentation] absoluteString] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"]];
	}
}

- (NSDictionary*)restLinkRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<ORManagedObject>*)object {
	return [NSDictionary dictionaryWithObject:[self restURIWithServerAddress:serverAddress 
                                                            forManagedObject:object] 
                                       forKey:OR_REF_KEYWORD];
}

- (NSManagedObject<ORManagedObject>*)insertNewObjectForEntityForName:(NSString*)entityString {
	return [NSEntityDescription insertNewObjectForEntityForName:entityString inManagedObjectContext:[_httpServer.dataProvider managedObjectContext]];
}

#pragma mark - Data Conversion

- (NSDictionary *)dictionaryRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject *)object 
{
	NSArray *attributes = [[[object entity] attributesByName] allKeys];
	NSArray *relationships = [[[object entity] relationshipsByName] allKeys];
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:[attributes count]  + [relationships count]];
	
	for (NSString *attribute in attributes) {
		NSObject *v = [object valueForKey:attribute];
		
		if (v != nil)
			[d setObject:v forKey:attribute];
	}
	
	for (NSString *relationship in relationships) {
		NSObject *value = [object valueForKey:relationship];
		
		if ([value isKindOfClass:[NSSet class]]) { // To-many
			NSSet *objects = (NSSet *)value;
			
			NSMutableArray *objectsSet = [NSMutableArray arrayWithCapacity:[objects count]];
			
			for (NSManagedObject *relation in objects)
				[objectsSet addObject:[self restLinkRepresentationWithServerAddress:serverAddress 
                                                                   forManagedObject:(NSManagedObject<ORManagedObject>*)relation]];
			
			[d setObject:objectsSet forKey:relationship];
		}
		else if ([value isKindOfClass:[NSManagedObject class]]) { // To-one
			NSManagedObject *o = (NSManagedObject *)value;
			
			[d setObject:[self restLinkRepresentationWithServerAddress:serverAddress 
                                                      forManagedObject:(NSManagedObject<ORManagedObject>*)o] forKey:relationship];
		}
	}
	
	return d;
}

@end
