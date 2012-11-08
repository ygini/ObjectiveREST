//
//  ORServer.h
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CocoaHTTPServer/HTTPServer.h>
#import <CocoaHTTPServer/WebSocket.h>
#import "ORProtocols.h"

void ORrunOnMainQueueWithoutDeadlocking(void (^block)(void));

@interface ORServer : HTTPServer <WebSocketDelegate>
@property (readonly, nonatomic) id<ORServerDataProvider> dataProvider;
@property (assign, nonatomic) id<ORServerExternalAPI> externalAPIDelegate;

@property (retain, nonatomic) NSString *prefixForREST;

@property (retain, nonatomic) NSString *prefixForWebSocket;

@property (assign, nonatomic) BOOL useSSL;
@property (assign, nonatomic) BOOL useDigest;

@property (assign, nonatomic) BOOL allowDeleteOnCollection;

- (id)initWithDataProvider:(id<ORServerDataProvider>)provider;

- (BOOL)start;

- (BOOL)managedObjectModelIsRESTReady;

- (void)sendMessageToAllWebSockets:(NSString*)message;

@end
