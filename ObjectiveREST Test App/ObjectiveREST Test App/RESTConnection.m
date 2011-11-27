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
#import "RESTManagedObject.h"
#import "SBJsonParser.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

// Define chunk size used to read in data for responses
// This is how much data will be read from disk into RAM at a time
#if TARGET_OS_IPHONE
#define READ_CHUNKSIZE  (1024 * 128)
#else
#define READ_CHUNKSIZE  (1024 * 512)
#endif

// Define chunk size used to read in POST upload data
#if TARGET_OS_IPHONE
#define POST_CHUNKSIZE  (1024 * 32)
#else
#define POST_CHUNKSIZE  (1024 * 128)
#endif

// Define the various timeouts (in seconds) for various parts of the HTTP process
#define TIMEOUT_READ_FIRST_HEADER_LINE       30
#define TIMEOUT_READ_SUBSEQUENT_HEADER_LINE  30
#define TIMEOUT_READ_BODY                    -1
#define TIMEOUT_WRITE_HEAD                   30
#define TIMEOUT_WRITE_BODY                   -1
#define TIMEOUT_WRITE_ERROR                  30
#define TIMEOUT_NONCE                       300

// Define the various limits
// MAX_HEADER_LINE_LENGTH: Max length (in bytes) of any single line in a header (including \r\n)
// MAX_HEADER_LINES      : Max number of lines in a single header (including first GET line)
#define MAX_HEADER_LINE_LENGTH  8190
#define MAX_HEADER_LINES         100
// MAX_CHUNK_LINE_LENGTH : For accepting chunked transfer uploads, max length of chunk size line (including \r\n)
#define MAX_CHUNK_LINE_LENGTH    200

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST_HEADER                10
#define HTTP_REQUEST_BODY                  11
#define HTTP_REQUEST_CHUNK_SIZE            12
#define HTTP_REQUEST_CHUNK_DATA            13
#define HTTP_REQUEST_CHUNK_TRAILER         14
#define HTTP_REQUEST_CHUNK_FOOTER          15
#define HTTP_PARTIAL_RESPONSE              20
#define HTTP_PARTIAL_RESPONSE_HEADER       21
#define HTTP_PARTIAL_RESPONSE_BODY         22
#define HTTP_CHUNKED_RESPONSE_HEADER       30
#define HTTP_CHUNKED_RESPONSE_BODY         31
#define HTTP_CHUNKED_RESPONSE_FOOTER       32
#define HTTP_PARTIAL_RANGE_RESPONSE_BODY   40
#define HTTP_PARTIAL_RANGES_RESPONSE_BODY  50
#define HTTP_RESPONSE                      90
#define HTTP_FINAL_RESPONSE                91

#define SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]

#define	REST_REF_KEYWORD					@"rest_ref"

@implementation RESTConnection

#pragma mark - LifeCycle

-(void)dealloc {
	[baseURLForURI release];
	[super dealloc];
}

#pragma mark - Core Data

- (NSArray*)managedObjectWithEntityName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
}

- (NSManagedObject*)managedObjectWithEntityName:(NSString*)name andRESTUUID:(NSString*)rest_uuid {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	[req setPredicate:[NSPredicate predicateWithFormat:@"SELF.rest_uuid like %@", rest_uuid]];
	NSArray *answer = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
	if ([answer count] > 0)
		return [answer objectAtIndex:0];
	else return nil;
}

- (NSManagedObject*)managedObjectWithRelativePath:(NSString*)path {
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
		entry = [self managedObjectWithEntityName:[pathComponents objectAtIndex:0] andRESTUUID:[pathComponents objectAtIndex:1]];
	}
	
	return entry;
}

- (NSManagedObject*)managedObjectWithAbsolutePath:(NSString*)path {
	return [self managedObjectWithRelativePath:[[NSURL URLWithString:path] relativePath]];
}

- (NSString*)baseURLForURI {
	if (!baseURLForURI) {
		baseURLForURI = [[NSString stringWithFormat:@"%@://%@", [self isSecureServer] ? @"https" : @"http" , [request headerField:@"Host"]] retain];
	}
	
	return baseURLForURI;
}

- (NSString*)restURIForManagedObject:(NSManagedObject<RESTManagedObject>*)object {
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

- (NSDictionary*)restLinkRepresentationForManagedObject:(NSManagedObject<RESTManagedObject>*)object {
	return [NSDictionary dictionaryWithObject:[self restURIForManagedObject:object] forKey:REST_REF_KEYWORD];
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
					[uptodateSet addObject:[self managedObjectWithAbsolutePath:[relationInfo valueForKey:REST_REF_KEYWORD]]];
				}
				
				[object willChangeValueForKey:supportedKey];
				[object setPrimitiveValue:uptodateSet forKey:supportedKey];
				[object didChangeValueForKey:supportedKey];
				
			} else [object setValue:[self managedObjectWithAbsolutePath:[value valueForKey:REST_REF_KEYWORD]] forKey:supportedKey];
		}
	}
	
	[[RESTManager sharedInstance].managedObjectContext save:&error];
}

- (NSManagedObject<RESTManagedObject>*)insertNewObjectForEntityForName:(NSString*)entityString {
	return [NSEntityDescription insertNewObjectForEntityForName:entityString inManagedObjectContext:[[RESTManager sharedInstance] managedObjectContext]];
}

#pragma mark - Data Conversion

- (NSDictionary *)dictionaryRepresentationForManagedObject:(NSManagedObject *)object 
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
            
            NSMutableSet *objectsSet = [NSMutableSet setWithCapacity:[objects count]];
            
            for (NSManagedObject *relation in objects)
                [objectsSet addObject:[self restLinkRepresentationForManagedObject:(NSManagedObject<RESTManagedObject>*)relation]];
            
            [d setObject:objectsSet forKey:relationship];
        }
        else if ([value isKindOfClass:[NSManagedObject class]]) { // To-one
            NSManagedObject *o = (NSManagedObject *)value;
            
            [d setObject:[self restLinkRepresentationForManagedObject:(NSManagedObject<RESTManagedObject>*)o] forKey:relationship];
        }
    }
    
	return d;
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

#pragma mark - HTTP Return code

- (void)httpReturnCode200Success {
	HTTPLogInfo(@"HTTP Server: OK 200 - Success (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:200 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode201Created {
	HTTPLogInfo(@"HTTP Server: OK 201 - Created (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:201 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode202Accepted {
	HTTPLogInfo(@"HTTP Server: OK 202 - Accepted (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:202 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode400BadRequest {
	HTTPLogInfo(@"HTTP Server: Error 400 - Bad Request (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:400 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode404NotFound {
	HTTPLogInfo(@"HTTP Server: Error 404 - Not Found (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:404 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode415UnsupportedMediaType {
	HTTPLogInfo(@"HTTP Server: Error 415 - Unsupported Media Type (%@ %@)", [request headerField:@"Accept"], [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:415 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode500InternalServerError {
	HTTPLogInfo(@"HTTP Server: Error 500 - Internal Server Error (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:501 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode501NotImplemented {
	HTTPLogInfo(@"HTTP Server: Error 501 - Not Implemented (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:501 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

- (void)httpReturnCode503ServiceUnavailable {
	HTTPLogInfo(@"HTTP Server: Error 503 - Service Unavailable (%@)", [self requestURI]);
	
	HTTPMessage *response = [[HTTPMessage alloc] initResponseWithStatusCode:503 description:nil version:HTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:HTTP_FINAL_RESPONSE];
	
	[response release];
}

#pragma mark - HTTP Session

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
	
	return [RESTManager sharedInstance].useDigest;
}

- (NSString *)passwordForUser:(NSString *)username
{
	HTTPLogTrace();
	
	return [[RESTManager sharedInstance].authenticationDatabase valueForKey:username];
}

#pragma mark - Main method

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
			[self httpReturnCode501NotImplemented];		
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
						
						NSArray *entries = [self managedObjectWithEntityName:selectedEntity];
						NSMutableArray *entriesRESTRefs = [NSMutableArray new];
						
						for (NSManagedObject <RESTManagedObject> *entry in entries) {						
							[entriesRESTRefs addObject:[self restLinkRepresentationForManagedObject:entry]];
						}
						
						return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
						
					} else {
						// return the selected entity
                        return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[self dictionaryRepresentationForManagedObject:[self managedObjectWithRelativePath:path]], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
					}
				}
				
			} else if ([method isEqualToString:@"POST"]) {
                /* **** POST ***** */
				
                if (numberOfComponents == 1 && [entities indexOfObject:[pathComponents objectAtIndex:0]] != NSNotFound && [[request body] length] > 0) {   
                    NSString *entityString = [pathComponents objectAtIndex:0];
                    NSString *errString = nil;
                    
                    NSManagedObject <RESTManagedObject> *newObject = [self insertNewObjectForEntityForName:entityString];
                    
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
					
                    [self updateManagedObject:newObject withInfo:dict];
					
					return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[self dictionaryRepresentationForManagedObject:newObject], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
                }
				
			} else if ([method isEqualToString:@"PUT"]) {
				/* **** PUT ***** */
				
				if ([pathComponents count] == 0) {
					// No entity name provided
					
				} else if ([[request body] length] > 0) {
					
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					NSString *errString = nil;
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						// No PUT on collection, use POST instead
						
					} else {
						NSManagedObject *entry = [self managedObjectWithRelativePath:path];
						
						if (!entry && [RESTManager sharedInstance].modelIsObjectiveRESTReady) {
							entry = [self insertNewObjectForEntityForName:selectedEntity];
						}
						
						if (entry) {
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
							
							[self updateManagedObject:entry withInfo:dict];
							
							return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[self dictionaryRepresentationForManagedObject:entry], @"content", nil]
																								withContentType:ContentType]] 
									autorelease];
						} else {
							// return invalide reequest code when PUT is used to create a new object with specific ID and standard CoreData model
							[self handleInvalidRequest:nil];
						}
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
							NSArray *entries = [self managedObjectWithEntityName:selectedEntity];
							
							for (NSManagedObject *entry in entries) {
								[[RESTManager sharedInstance].managedObjectContext deleteObject:entry];
							}
							[self httpReturnCode200Success];
						} else [self httpReturnCode501NotImplemented];
					} else {						
						[[RESTManager sharedInstance].managedObjectContext deleteObject:[self managedObjectWithRelativePath:path]];
						[self httpReturnCode200Success];
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

@end
