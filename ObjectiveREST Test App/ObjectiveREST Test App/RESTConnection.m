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
#import "SBJsonParser.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

#define TIMEOUT_WRITE_ERROR					30
#define HTTP_FINAL_RESPONSE					91

#define SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]

#define	REST_REF_KEYWORD					@"rest_ref"

@implementation RESTConnection

#pragma mark - LifeCycle

-(void)dealloc {
	[baseURLForURI release];
	[super dealloc];
}

#pragma mark - Core Data

- (NSArray*)instanceOfEntityWithName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
}

- (NSManagedObject*)instanceOfEntityWithName:(NSString*)name andRESTUUID:(NSString*)rest_uuid {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	[req setPredicate:[NSPredicate predicateWithFormat:@"SELF.rest_uuid like %@", rest_uuid]];
	NSArray *answer = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
	if ([answer count] > 0)
		return [answer objectAtIndex:0];
	else return nil;
}

- (NSManagedObject*)entityWithPath:(NSString*)path {
	NSManagedObject *entry = nil;
	NSError *error = nil;
	NSMutableArray *pathComponents = [NSMutableArray new];
	NSArray *entities = [[[[[RESTManager sharedInstance].managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
	
	// Cleaning path for double /
	path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
	
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
	
	NSString *selectedEntity = [pathComponents objectAtIndex:0];
		
	if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
		// Update entity from CoreData URI
		NSString *coreDataUniqueID = [path stringByReplacingOccurrencesOfString:@"/x-coredata" withString:@"x-coredata:/"];
		
		entry =  [[RESTManager sharedInstance].managedObjectContext objectWithID:
				  [[RESTManager sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:coreDataUniqueID]]];
		
		if ([entry isFault]) {
			
			
			NSFetchRequest *validityRequest = [[NSFetchRequest alloc] init];
			[validityRequest setEntity:[entry entity]];
			
			[validityRequest setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] 
																			 rightExpression:[NSExpression expressionForConstantValue:entry]
																					modifier:NSDirectPredicateModifier
																						type:NSEqualToPredicateOperatorType 
																					 options:0]];
			
			NSArray *results = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:validityRequest error:&error];
			[validityRequest release];
			
			if ([results count] > 0) {   
				entry = [results objectAtIndex:0];
			}
		}							
	} else if ([entities indexOfObject:selectedEntity] != NSNotFound) {
		// Update entity from REST UUID
		entry = [self instanceOfEntityWithName:[pathComponents objectAtIndex:0] andRESTUUID:[pathComponents objectAtIndex:1]];
	}
	
	return entry;
}

- (NSString*)baseURLForURI {
	if (!baseURLForURI) {
		baseURLForURI = [[NSString stringWithFormat:@"%@://%@", [self isSecureServer] ? @"https" : @"http" , [request headerField:@"Host"]] retain];
	}
	
	return baseURLForURI;
}

- (NSString*)restURIForEntity:(NSManagedObject<RESTManagedObject>*)object {
	NSError *error = nil;
	if ([RESTManager sharedInstance].modelIsObjectiveRESTReady) {
		// If the data model has been patched, we use dedicated UUID to make URI
			return [NSString stringWithFormat:@"%@/%@/%@", [self baseURLForURI], [[object entity] name], [object rest_uuid]];
	} else {
		// If the data model isn't patched to be compatible with ObjectiveREST, we fall back on CoreData ID…
		if ([[object objectID] isTemporaryID])
			[[RESTManager sharedInstance].managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:object] error:&error];
		
		return [NSString stringWithFormat:@"%@/%@", [self baseURLForURI], [[[[object objectID] URIRepresentation] absoluteString] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"]];
	}
}

#pragma mark - Data Conversion

- (NSDictionary*)convertInDictionaryTheManagedObject:(NSManagedObject*)object {
#warning Ici Hideoo
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


#pragma mark - HTTP Session

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

- (void)handleMethodOK
{
	// Override me for custom error handling of 404 not found responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	HTTPLogInfo(@"HTTP Server: OK 200 - Success (%@)", [self requestURI]);
	
	// Status Code 404 - Not Found
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:200 description:nil version:HTTPVersion1_1];
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
		
	// Cleaning path for double /
	path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
	
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
	
	NSInteger numberOfComponents = [pathComponents count];
	
	NSString *baseURLString = [NSString stringWithFormat:@"%@://%@", [self isSecureServer] ? @"https" : @"http" , [request headerField:@"Host"]];
	
	@try {
		HTTPLogTrace();
		NSError *error = nil;
		NSArray *acceptedContentType = [[request headerField:@"Accept"] componentsSeparatedByString:@","];
		
		entities = [[[[[RESTManager sharedInstance].managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
		
		
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
			
			if ([method isEqualToString:@"GET"]) {
				/* **** GET ***** */
				
				if (numberOfComponents == 0) {
					// No entity name provided, return the list of entry
					
					NSMutableArray *entitiesRESTRefs = [NSMutableArray new];
					for (NSString *entity in entities) {
						[entitiesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@/%@", baseURLString, entity] forKey:REST_REF_KEYWORD]];
					}
					
					return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entitiesRESTRefs autorelease], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
				} else {
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						// return the list of entry for the kind of requested entity
						
						NSArray *entries = [self instanceOfEntityWithName:selectedEntity];
						NSMutableArray *entriesRESTRefs = [NSMutableArray new];
						
						for (NSManagedObject <RESTManagedObject> *entry in entries) {						
							[entriesRESTRefs addObject:[NSDictionary dictionaryWithObject:[self restURIForEntity:entry] forKey:REST_REF_KEYWORD]];
						}
						
						return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];

					} else {
						// return the selected entity
						return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[[self entityWithPath:path] dictionnaryValue], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
					}
				}
				
			} else if ([method isEqualToString:@"POST"]) {
                /* **** POST ***** */
				
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
                        entityRef = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@/%@", [[request url] absoluteString], [newObject rest_uuid]] forKey:REST_REF_KEYWORD]];
                    else
                        entityRef = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[[NSString stringWithFormat:@"%@%@", [[request url] baseURL], [[[newObject objectID] URIRepresentation] absoluteString]] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"] forKey:REST_REF_KEYWORD]];
                    
					[parameters release];
					
                    return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:entityRef, @"content", nil]
                                                                                        withContentType:ContentType]] 
                            autorelease];
                }
				
			} else if ([method isEqualToString:@"PUT"]) {
				/* **** PUT ***** */
				
				if ([pathComponents count] == 0) {
					// No entity name provided
					
				} else {
					
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					NSString *errString = nil;
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						// No PUT on collection, use POST instead
						
					} else {
						NSManagedObject *entry = [self entityWithPath:path];
						
						if (!entry && [RESTManager sharedInstance].modelIsObjectiveRESTReady) {
							entry = [NSEntityDescription insertNewObjectForEntityForName:selectedEntity
																  inManagedObjectContext:[[RESTManager sharedInstance] managedObjectContext]];
						}
						
						NSDictionary *dict = nil;
						if ([ContentType isEqualToString:@"application/x-bplist"] || [ContentType isEqualToString:@"application/x-plist"]) 
							dict = [NSPropertyListSerialization propertyListFromData:[request body]
																	mutabilityOption:NSPropertyListMutableContainersAndLeaves
																			  format:nil
																	errorDescription:&errString];
						
						else if ([ContentType isEqualToString:@"application/json"]) {
							SBJsonParser *parser = [SBJsonParser new];
							dict = [parser objectWithData:[request body]];
							[parser release];
						}
						
						dict = [dict valueForKey:@"content"];
						
						id value = nil;
						for (NSString *supportedKey in [[[entry entity] attributesByName] allKeys]) {
							value = [dict valueForKey:supportedKey];
							if (value) [entry setValue:value forKey:supportedKey];
						}
						
						[[RESTManager sharedInstance].managedObjectContext save:&error];
						
						return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entry dictionnaryValue], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
					}
				}
				
			} else if ([method isEqualToString:@"DELETE"]) {
				/* **** DELETE ***** */
				
				if ([pathComponents count] == 0) {
					// No entity name provided

				} else {
					
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
					// Delete all entities ?
						if ([RESTManager sharedInstance].allowDeleteOnCollection) {
							NSString *selectedEntity = [pathComponents objectAtIndex:0];
							NSArray *entries = [self instanceOfEntityWithName:selectedEntity];
							
							for (NSManagedObject *entry in entries) {
								[[RESTManager sharedInstance].managedObjectContext deleteObject:entry];
							}
							[self handleMethodOK];
						} else [self handleOptionNotImplemented];
					} else {						
						[[RESTManager sharedInstance].managedObjectContext deleteObject:[self entityWithPath:path]];
						[self handleMethodOK];
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

#pragma mark - SSL

/**
 * Overrides HTTPConnection's method
 **/
- (BOOL)isSecureServer
{
	HTTPLogTrace();
	
	// Create an HTTPS server (all connections will be secured via SSL/TLS)
	return [RESTManager sharedInstance].requestHTTPS;
}

/**
 * Overrides HTTPConnection's method
 * 
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
 **/
- (NSArray *)sslIdentityAndCertificates
{
	HTTPLogTrace();
	/*
	NSArray *result = [DDKeychain SSLIdentityAndCertificates];
	if([result count] == 0)
	{
		[DDKeychain createNewIdentity];
		return [DDKeychain SSLIdentityAndCertificates];
	}*/
	return nil;
}

#pragma mark - Password

- (BOOL)isPasswordProtected:(NSString *)path
{
	return [RESTManager sharedInstance].requestAuthentication;
}

- (BOOL)useDigestAccessAuthentication
{
	HTTPLogTrace();
	
	// Digest access authentication is the default setting.
	// Notice in Safari that when you're prompted for your password,
	// Safari tells you "Your login information will be sent securely."
	// 
	// If you return NO in this method, the HTTP server will use
	// basic authentication. Try it and you'll see that Safari
	// will tell you "Your password will be sent unencrypted",
	// which is strongly discouraged.
	
	return [RESTManager sharedInstance].useDigest;
}

- (NSString *)passwordForUser:(NSString *)username
{
	HTTPLogTrace();
	
	// You can do all kinds of cool stuff here.
	// For simplicity, we're not going to check the username, only the password.
	
	return [[RESTManager sharedInstance].authenticationDatabase valueForKey:username];
}

@end
