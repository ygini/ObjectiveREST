//
//  ORServer.h
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HTTPServer.h"
#import "ORServerProtocols.h"


@interface ORServer : HTTPServer
@property (assign, nonatomic) id<ORServerDataProvider> dataProvider;
@property (assign, nonatomic) id<ORServerExternalAPI> externalAPIDelegate;

@property (retain, nonatomic) NSString *prefixForREST;

@property (assign, nonatomic) BOOL useSSL;
@property (assign, nonatomic) BOOL useDigest;

@property (assign, nonatomic) BOOL allowDeleteOnCollection;

+ (ORServer*)sharedInstance;

- (BOOL)start;

- (BOOL)managedObjectModelIsRESTReady;

@end
