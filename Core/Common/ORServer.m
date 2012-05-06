//
//  ORServer.m
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORServer.h"

#import <CocoaHTTPServer/HTTPServer.h>
#import "ORServerConnection.h"

@implementation ORServer
@synthesize dataProvider = _dataProvider;
@synthesize externalAPIDelegate = _externalAPIDelegate;

@synthesize prefixForREST = _prefixForREST;

@synthesize useSSL = _useSSL;
@synthesize useDigest = _useDigest;

@synthesize allowDeleteOnCollection = _allowDeleteOnCollection;

#pragma mark - Server API

+ (ORServer*)sharedInstance {
    static ORServer* sharedInstanceORServer = nil;
	if (!sharedInstanceORServer) sharedInstanceORServer = [ORServer new];
	return sharedInstanceORServer;
}

- (BOOL)start {
    NSError *error = nil;
	
	if(![self start:&error]) {
		NSLog(@"Error starting HTTP Server: %@", error);
		return NO;
	}
	
	return YES;
}

- (BOOL)managedObjectModelIsRESTReady {
    return NO;
}

#pragma mark - Configuration

- (id)init {
    self = [super init];
    if (self) {
        _prefixForREST = @"OR-API";
        connectionClass = [ORServerConnection class];
    }
    return self;
}

- (void)dealloc {
    [_prefixForREST release], _prefixForREST = nil;
    [super dealloc];
}

@end
