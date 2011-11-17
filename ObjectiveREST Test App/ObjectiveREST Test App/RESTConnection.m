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
	HTTPLogTrace();
	
	NSArray *acceptedContentType = [[request headerField:@"Accept"] componentsSeparatedByString:@","];
	NSMutableArray *retainedContentType = [NSMutableArray new];
	
	for (NSString *contentType in SUPPORTED_CONTENT_TYPE) {
		if ([acceptedContentType containsObject:contentType]) [retainedContentType addObject:contentType];
	}
	
	if ([retainedContentType count] == 0) { 
		[self handleOptionNotImplemented];		
	} else {
		
		NSString *ContentType = [[retainedContentType objectAtIndex:0] retain];
		[retainedContentType release];
		
		if ([method isEqualToString:@"GET"]) {
			
			NSArray *entities = [[[[RESTManager sharedInstance].managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)];
			NSMutableArray *pathComponents = [NSMutableArray new];
			
			for (NSString *pathCompo in [path pathComponents]) {
				if (![pathCompo isEqualToString:@"/"]) {
					[pathComponents addObject:pathCompo];
				}
			}
			
			if ([pathComponents count] == 0) {		// No entity name provided
				NSMutableArray *entitiesRESTRefs = [NSMutableArray new];
				for (NSString *entity in entities) {
					[entitiesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@%@", [[request url] absoluteString], entity] forKey:@"ref"]];
				}
				
				return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entitiesRESTRefs autorelease], @"content", nil]
																					withContentType:ContentType]] 
						autorelease];
			} else {
				NSInteger numberOfComponents = [pathComponents count];
				NSString *selectedEntity = [pathComponents objectAtIndex:0];
				
				if (numberOfComponents == 1 && [entities indexOfObject:selectedEntity] != NSNotFound) { // return the list of entry for this kind of entity
					NSArray *entries = [self instanceOfEntityWithName:selectedEntity];
					NSMutableArray *entriesRESTRefs = [NSMutableArray new];
					for (NSManagedObject *entry in entries) {
						[entriesRESTRefs addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@%@", [[request url] baseURL], [[[[entry objectID] URIRepresentation] absoluteString] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"]] forKey:@"ref"]];
					}
					
					return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entriesRESTRefs autorelease], @"content", nil]
																						withContentType:ContentType]] 
							autorelease];
				} else {
					if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
						NSString *coreDataUniqueID = [path stringByReplacingOccurrencesOfString:@"/x-coredata" withString:@"x-coredata:/"];
						
						NSManagedObject *entry =  [[RESTManager sharedInstance].managedObjectContext objectWithID:
												   [[RESTManager sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:coreDataUniqueID]]];
                        
                        return [[[HTTPDataResponse alloc] initWithData:[self preparedResponseFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[entry dictionnaryValue], @"content", nil]
                                                                                            withContentType:ContentType]] 
                                autorelease];
					}
				}
			}
		} else if ([method isEqualToString:@"POST"]) {
			
		} else if ([method isEqualToString:@"PUT"]) {
			
		} else if ([method isEqualToString:@"DELETE"]) {
			
		} else [self handleUnknownMethod:method];
		
		[ContentType release];
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
	
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	

}

@end
