//
//  ORServerWebSocket.h
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 08/11/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <CocoaHTTPServer/WebSocket.h>

@interface ORServerWebSocket : WebSocket

- (void)sendUpdateMessageFromNotification:(NSNotification*)notification;

@end
