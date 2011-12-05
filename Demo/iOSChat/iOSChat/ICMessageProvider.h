//
//  ICMessageProvider.h
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kICMessageProviderServerUnaviable       @"kICMessageProviderServerUnaviable"

@interface ICMessageProvider : NSObject {
    NSNetService *_remoteService;
}

@property (unsafe_unretained) BOOL isServer;
@property (strong) NSString *serverName;
@property (strong) NSString *nickName;
@property (weak) NSNetService *remoteService;

@property (readonly) NSArray *messages;

+ (ICMessageProvider*)sharedInstance;

- (NSArray*)messages;
- (void)sendMessage:(NSString*)aMessage;

- (void)startServer;
- (void)stopServer;

@end
