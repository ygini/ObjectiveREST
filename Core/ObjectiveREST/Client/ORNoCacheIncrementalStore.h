//
//  ORNoCacheIncrementalStore.h
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 07/11/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <CoreData/CoreData.h>

#import <SocketRocketOSX/SRWebSocket.h>

@interface ORNoCacheIncrementalStore : NSIncrementalStore <SRWebSocketDelegate>

@end
