//
//  RESTClient.m
//  ObjectiveREST iOS
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RESTClient.h"
#import "NSString_RESTAddition.h"
#import "RESTManager.h"

@implementation RESTClient

@synthesize modelIsObjectiveRESTReady;
@synthesize requestHTTPS;
@synthesize requestAuthentication;
@synthesize useDigest;
@synthesize username;
@synthesize password;
@synthesize serverAddress;
@synthesize tcpPort;
@synthesize contentType;

+ (RESTClient*)sharedInstance {
	static RESTClient* sharedInstanceRESTClient = nil;
	if (!sharedInstanceRESTClient) sharedInstanceRESTClient = [RESTClient new];
	return sharedInstanceRESTClient;
}

- (id)init {
    self = [super init];
    if (self) {
        [RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
        [RESTClient sharedInstance].useDigest = NO;
        [RESTClient sharedInstance].requestHTTPS = NO;
        [RESTClient sharedInstance].requestAuthentication = NO;
        [RESTClient sharedInstance].contentType = REST_SUPPORTED_CONTENT_TYPE;
    }
    return self;
}

#pragma mark - Routines
- (NSString*)hostInfoWithServer:(NSString*)address andPort:(NSInteger)port {
    return [NSString stringWithFormat:@"%@:%d", address, port];
}

- (NSString*)hostInfo {
    return [self hostInfoWithServer:self.serverAddress andPort:self.tcpPort];
}

- (NSString*)baseURL {
    return [NSString stringWithFormat:@"%@://%@",
            self.requestHTTPS ? @"https" : @"http",
            [self hostInfo]];
}

- (NSString*)absoluteVersionForPath:(NSString*)path {
    return [NSString stringWithFormat:@"%@%@", [self baseURL], path];
}

- (NSMutableURLRequest*)baseRequestForPath:(NSString*)path {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
	
	[req setValue:[self.contentType objectAtIndex:0] forHTTPHeaderField:@"Accept"];
	
	[req setValue:self.hostInfo forHTTPHeaderField:@"Host"];
		
	if (self.requestAuthentication) {
        if(self.useDigest) {
            
        } else {
            [req setValue:[NSString stringWithFormat:@"Basic %@", 
                           [[NSString stringWithFormat:@"%@:%@",
                             self.username,
                             self.password]
                            RESTbase64EncodedString]]
       forHTTPHeaderField:@"Authorization"];
        }
	}
    
    return req;
}

#pragma mark - REST Client

- (NSDictionary*)postInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"POST"];
	
	[req setHTTPBody:[RESTManager preparedResponseFromDictionary:info
                                                 withContentType:[self.contentType objectAtIndex:0]]];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[RESTManager dictionaryFromResponse:answer 
                                                     withContentType:[self.contentType objectAtIndex:0]] mutableCopy];
    
	return [dict autorelease];
}

- (NSDictionary*)postInfo:(NSDictionary*)info toPath:(NSString*)path {
    return [self postInfo:info toAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSDictionary*)putInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"PUT"];
	
	[req setHTTPBody:[RESTManager preparedResponseFromDictionary:info
                                                 withContentType:[self.contentType objectAtIndex:0]]];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[RESTManager dictionaryFromResponse:answer 
                                                     withContentType:[self.contentType objectAtIndex:0]] mutableCopy];
    
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
    
    NSURLResponse *rep = nil;
    NSError *err = nil;
    
    NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
    
    dict = [[RESTManager dictionaryFromResponse:answer 
                                withContentType:[self.contentType objectAtIndex:0]] mutableCopy];
    
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

@end
