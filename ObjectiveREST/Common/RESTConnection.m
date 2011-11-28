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
#import "RESTManager.h"
#import "RESTManagedObject.h"
#import "RESTPrivateSettings.h"

@implementation RESTConnection

#pragma mark - LifeCycle

-(void)dealloc {
	[super dealloc];
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
		for (NSString *contentType in REST_SUPPORTED_CONTENT_TYPE) {
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
					
					return [[[HTTPDataResponse alloc] initWithData:[RESTManager preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entitiesRESTRefs autorelease], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
				} else {
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						// return the list of entry for the kind of requested entity
						
						NSArray *entries = [RESTManager managedObjectWithEntityName:selectedEntity];
						NSMutableArray *entriesRESTRefs = [NSMutableArray new];
						
						for (NSManagedObject <RESTManagedObject> *entry in entries) {						
							[entriesRESTRefs addObject:[RESTManager restLinkRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:entry]];
						}
						
						return [[[HTTPDataResponse alloc] initWithData:[RESTManager preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
						
					} else {
						// return the selected entity
                        return [[[HTTPDataResponse alloc] initWithData:[RESTManager preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[RESTManager dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:[RESTManager managedObjectWithRelativePath:path]], @"content", nil]
																							withContentType:ContentType]] 
								autorelease];
					}
				}
				
			} else if ([method isEqualToString:@"POST"]) {
                /* **** POST ***** */
				
                if (numberOfComponents == 1 && [entities indexOfObject:[pathComponents objectAtIndex:0]] != NSNotFound && [[request body] length] > 0) {   
                    NSString *entityString = [pathComponents objectAtIndex:0];
                    
                    NSManagedObject <RESTManagedObject> *newObject = [RESTManager insertNewObjectForEntityForName:entityString];
                    
                    NSDictionary *dict = [[RESTManager dictionaryFromResponse:[request body] withContentType:ContentType] valueForKey:@"content"];
					
                    [RESTManager updateManagedObject:newObject withInfo:dict];
					
					return [[[HTTPDataResponse alloc] initWithData:[RESTManager preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[RESTManager dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:newObject], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
                }
				
			} else if ([method isEqualToString:@"PUT"]) {
				/* **** PUT ***** */
				
				if ([pathComponents count] == 0) {
					// No entity name provided
					
				} else if ([[request body] length] > 0) {
					
					NSString *selectedEntity = [pathComponents objectAtIndex:0];
					
					if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) {
						// No PUT on collection, use POST instead
						
					} else {
						NSManagedObject *entry = [RESTManager managedObjectWithRelativePath:path];
						
						if (!entry && [RESTManager sharedInstance].modelIsObjectiveRESTReady) {
							entry = [RESTManager insertNewObjectForEntityForName:selectedEntity];
						}
						
						if (entry) {
							NSDictionary *dict = [[RESTManager dictionaryFromResponse:[request body] withContentType:ContentType] valueForKey:@"content"];
							
							[RESTManager updateManagedObject:entry withInfo:dict];
							
							return [[[HTTPDataResponse alloc] initWithData:[RESTManager preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[RESTManager dictionaryRepresentationWithServerAddress:[request headerField:@"Host"] forManagedObject:entry], @"content", nil]
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
							NSArray *entries = [RESTManager managedObjectWithEntityName:selectedEntity];
							
							for (NSManagedObject *entry in entries) {
								[[RESTManager sharedInstance].managedObjectContext deleteObject:entry];
							}
							[self httpReturnCode200Success];
						} else [self httpReturnCode501NotImplemented];
					} else {						
						[[RESTManager sharedInstance].managedObjectContext deleteObject:[RESTManager managedObjectWithRelativePath:path]];
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
