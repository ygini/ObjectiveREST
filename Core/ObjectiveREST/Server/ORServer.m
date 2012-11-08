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

#import "ORToolbox.h"

#import "ORServerWebSocket.h"

void ORrunOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface ORServer () {
	NSMutableArray *_webSockets;
}

@end

@implementation ORServer
@synthesize dataProvider = _dataProvider;
@synthesize externalAPIDelegate = _externalAPIDelegate;

@synthesize prefixForREST = _prefixForREST;
@synthesize prefixForWebSocket = _prefixForWebSocket;

@synthesize useSSL = _useSSL;
@synthesize useDigest = _useDigest;

@synthesize allowDeleteOnCollection = _allowDeleteOnCollection;

#pragma mark - Server API

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

- (id)initWithDataProvider:(id<ORServerDataProvider>)provider {
    self = [super init];
    if (self) {
		_dataProvider = provider;
        _prefixForREST = @"OR-API";
		_prefixForWebSocket = @"OR-WS";
        connectionClass = [ORServerConnection class];
		_webSockets = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(managedObjectContextDidSaveNotification:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:[_dataProvider managedObjectContext]];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_prefixForREST release], _prefixForREST = nil;
    [_prefixForWebSocket release], _prefixForWebSocket = nil;
	[_webSockets release];
    [super dealloc];
}

#pragma mark - Notifications

- (void)managedObjectContextDidSaveNotification:(NSNotification*)notification {
	for (ORServerWebSocket *ws in _webSockets) {
		[ws sendUpdateMessageFromNotification:notification];
	}
}

#pragma mark - WebSocket Delegate

- (void)webSocketDidOpen:(WebSocket *)ws {
	[_webSockets addObject:ws];
}

- (void)webSocket:(WebSocket *)ws didReceiveMessage:(NSString *)msg {
	
}

- (void)webSocketDidClose:(WebSocket *)ws {
	[_webSockets removeObject:ws];
}

#pragma mark - WebSocket API

- (void)sendMessageToAllWebSockets:(NSString*)message {
	for (ORServerWebSocket *ws in _webSockets) {
		[ws sendMessage:message];
	}
}

@end
