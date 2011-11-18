//
//  RESTConnection.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RESTConnection.h"
#import "HTTPLogging.h"
#import "HTTPDataResponse.h"
#import "HTTPMessage.h"
#import "GCDAsyncSocket.h"
#import "NSObject+SBJson.h"
#import "RESTManager.h"
#import "NSManagedObject+Additions.h"
#import "RESTManagedObject.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

#define TIMEOUT_WRITE_ERROR					30
#define HTTP_FINAL_RESPONSE					91

#define SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]

@implementation RESTConnection


- (NSArray*)instanceOfEntityWithName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
}

- (NSManagedObject*)instanceOfEntityWithName:(NSString*)name andRESTUUID:(NSString*)rest_uuid {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	[req setPredicate:[NSPredicate predicateWithFormat:@"SELF.rest_uuid like %@", rest_uuid]];
	return [[[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err] objectAtIndex:0];
}


- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict withContentType:(NSString*)ContentType {
	NSString *errorString = nil;
	
	if ([ContentType isEqualToString:@"application/x-bplist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	else if ([ContentType isEqualToString:@"application/x-plist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	else if ([ContentType isEqualToString:@"application/json"]) 
		return [[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
	else
		return nil;
}

/**
 * Called if the client ask for a unavaiable content type
 **/
- (void)handleOptionNotImplemented
{
	// Override me for custom error handling of 404 not found responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	HTTPLogInfo(@"HTTP Server: Error 501 - Not Implemented (%@)", [self requestURI]);
	
	// Status Code 404 - Not Found
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:501 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	if ([method isEqualToString:@"GET"])
		return YES;
	if ([method isEqualToString:@"POST"])
		return YES;
	if ([method isEqualToString:@"PUT"])
		return YES;
	if ([method isEqualToString:@"DELETE"])
		return YES;
	
	return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	if([method isEqualToString:@"POST"])
		return YES;
	if ([method isEqualToString:@"PUT"])
		return YES;
	
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSMutableArray *pathComponents = [NSMutableArray new];
	NSString *ContentType = nil;
	NSArray *entities = nil;
	
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
	
	NSInteger numberOfComponents = [pathComponents count];
	
	@try {
		HTTPLogTrace();
		NSError *error = nil;
		NSArray *acceptedContentType = [[request headerField:@"Accept"] componentsSeparatedByString:@","];
		
		entities = [[[[RESTManager sharedInstance].managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
		
		NSMutableArray *retainedContentType = [NSMutableArray new];
		for (NSString *contentType in SUPPORTED_CONTENT_TYPE) {
			if ([acceptedContentType containsObject:contentType]) [retainedContentType addObject:contentType];
		}
		
		if ([retainedContentType count] == 0) ContentType = nil;
		else ContentType = [[retainedContentType objectAtIndex:0] retain];
		
		[retainedContentType release], retainedContentType = nil;
		
		
		if (!ContentType) { 
			[self handleOptionNotImplemented];		
		} else {			
			
			/* **** GET ***** */
			if ([method isEqualToString:@"GET"]) {
				
				// No entity name provided, return the list of entry
				if (numberOfComponents == 0) {
					NSMutableArray *entitiesRESTRefs = [NSMutableArray new];
					for (NSString *entity in entities) {
						[entitiesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@%@", [[request url] absoluteString], entity] forKey:@"ref"]];
					}
					
					return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entitiesRESTRefs autorelease], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
				} else {
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					// return the list of entry for the kind of requested entity
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						NSArray *entries = [self instanceOfEntityWithName:selectedEntity];
						NSMutableArray *entriesRESTRefs = [NSMutableArray new];
						
						if ([RESTManager sharedInstance].modelIsObjectiveRESTReady) {
							// If the data model has been patched, we use dedicated UUID to make URI
							
							for (NSManagedObject <RESTManagedObject> *entry in entries) {						
								[entriesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@/%@", [[request url] absoluteString], [entry rest_uuid]] forKey:@"ref"]];
							}
							
						} else {
							// If the data model isn't patched to be compatible with ObjectiveREST, we fall back on CoreData ID…
							[[RESTManager sharedInstance].managedObjectContext obtainPermanentIDsForObjects:entries error:&error];
							
							for (NSManagedObject *entry in entries) {						
								[entriesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@%@", [[request url] baseURL], [[[[entry objectID] URIRepresentation] absoluteString] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"]] forKey:@"ref"]];
							}
						}
						
						return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
						
						// return the selected entity
					} else {
						// return the selected entity from the CoreData URI
						if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
							NSString *coreDataUniqueID = [path stringByReplacingOccurrencesOfString:@"/x-coredata" withString:@"x-coredata:/"];
							
							NSManagedObject *entry =  [[RESTManager sharedInstance].managedObjectContext objectWithID:
													   [[RESTManager sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:coreDataUniqueID]]];
                            
                            if (![entry isFault]) {
                                return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entry dictionnaryValue], @"content", nil]
                                                                                                    withContentType:ContentType]] 
                                        autorelease];
                            }
                            
                            NSFetchRequest *r = [[[NSFetchRequest alloc] init] autorelease];
                            [r setEntity:[entry entity]];
                            
                            NSPredicate *p = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] 
                                                                                rightExpression:[NSExpression expressionForConstantValue:entry]
                                                                                       modifier:NSDirectPredicateModifier
                                                                                           type:NSEqualToPredicateOperatorType 
                                                                                        options:0];
                            [r setPredicate:p];
                            
                            NSArray *results = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:r error:&error];
                            if ([results count] > 0) {   
                                return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[[results objectAtIndex:0] dictionnaryValue], @"content", nil]
                                                                                                    withContentType:ContentType]] 
                                        autorelease];
                            }
							
							// return the selected entity from the REST UUID
						} else if ([entities indexOfObject:selectedEntity] != NSNotFound) {
							NSManagedObject *entry = [self instanceOfEntityWithName:selectedEntity andRESTUUID:[pathComponents objectAtIndex:1]];
							
							return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entry dictionnaryValue], @"content", nil]
																								withContentType:ContentType]] 
									autorelease];
						}
					}
				}
				
				/* **** POST ***** */
			} else if ([method isEqualToString:@"POST"]) {
                
                if (numberOfComponents == 1 && [entities indexOfObject:[pathComponents objectAtIndex:0]] != NSNotFound && [[request body] length] > 0) {   
                    NSString *entityString = [pathComponents objectAtIndex:0];
                    
                    NSString *requestBody = [[NSString alloc] initWithBytes:[[request body] bytes] 
                                                                     length:[[request body] length] 
                                                                   encoding:NSUTF8StringEncoding];
                    
                    NSManagedObject <RESTManagedObject> *newObject = [NSEntityDescription insertNewObjectForEntityForName:entityString
																								   inManagedObjectContext:[[RESTManager sharedInstance] managedObjectContext]];
                    
                    // Time to parse the body :)
                    NSMutableDictionary *parameters = [NSMutableDictionary new];
                    for (NSString *p in [requestBody componentsSeparatedByString:@"&"]) {
                        NSArray *keyValue = [p componentsSeparatedByString:@"="];
                        [parameters setObject:[keyValue objectAtIndex:1] forKey:[keyValue objectAtIndex:0]];
                    }
                    
                    // Fetch the entity attributes
                    NSDictionary *attributes = [[newObject entity] attributesByName];
					
                    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        if ([newObject respondsToSelector:NSSelectorFromString(key)]) {
                            
                            NSAttributeDescription *a = [attributes objectForKey:key];
                            
                            if ([a attributeType] == NSFloatAttributeType || 
                                [a attributeType] == NSInteger16AttributeType || 
                                [a attributeType] == NSInteger32AttributeType || 
                                [a attributeType] == NSInteger64AttributeType || 
                                [a attributeType] == NSDecimalAttributeType || 
                                [a attributeType] == NSDoubleAttributeType || 
                                [a attributeType] == NSBooleanAttributeType) 
                            {
                                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                                [f setNumberStyle:NSNumberFormatterDecimalStyle];                                
                                [newObject setValue:[f numberFromString:obj] forKey:key];   
                                [f release];
                            } else {
                                [newObject setValue:obj forKey:key];   
                            }
                        }
                    }];
                    
                    [[RESTManager sharedInstance].managedObjectContext save:&error];
                    
                    NSArray *entityRef;
                    
                    if ([RESTManager sharedInstance].modelIsObjectiveRESTReady)
                        entityRef = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@/%@", [[request url] absoluteString], [newObject rest_uuid]] forKey:@"ref"]];
                    else
                        entityRef = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[[NSString stringWithFormat:@"%@%@", [[request url] baseURL], [[[newObject objectID] URIRepresentation] absoluteString]] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"] forKey:@"ref"]];
                    
					[parameters release];
					
                    return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:entityRef, @"content", nil]
                                                                                        withContentType:ContentType]] 
                            autorelease];
                }
				
				/* **** PUT ***** */
			} else if ([method isEqualToString:@"PUT"]) {
				
				
				
				/* **** DELETE ***** */
			} else if ([method isEqualToString:@"DELETE"]) {
				if ([pathComponents count] == 0) {		// No entity name provided
					
				} else {
					
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) { // Delete all entities ?
						
					} else {
						if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
							
						} else if ([entities indexOfObject:selectedEntity] != NSNotFound) {
							
						}
					}
				}
				
			} else [self handleUnknownMethod:method];
			
		}		
	}
	@catch (NSException *exception) {
		[self handleResourceNotFound];
	} @finally {		
		[pathComponents release], pathComponents = nil;
		[ContentType release], ContentType = nil;
		[entities release], entities = nil;
		
	}
	
	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
    
    [request appendData:postDataChunk];
}

@end
