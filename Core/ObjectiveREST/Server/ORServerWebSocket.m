//
//  ORServerWebSocket.m
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 08/11/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORServerWebSocket.h"

#import "ORServer.h"

#import "ORConstants.h"

@implementation ORServerWebSocket

- (void)sendUpdateMessageFromNotification:(NSNotification*)notification {
	NSManagedObject *object;
	
	for (object in [[notification userInfo] valueForKey:NSInsertedObjectsKey]) {
		[self sendMessage:[NSString stringWithFormat:@"%@%@", OR_WS_PREFIX_INSERTED, [object.objectID.URIRepresentation absoluteString]]];
	}
	
	for (object in [[notification userInfo] valueForKey:NSUpdatedObjectsKey]) {
		[self sendMessage:[NSString stringWithFormat:@"%@%@", OR_WS_PREFIX_UPDATED, [object.objectID.URIRepresentation absoluteString]]];
	}
	
	for (object in [[notification userInfo] valueForKey:NSDeletedObjectsKey]) {
		[self sendMessage:[NSString stringWithFormat:@"%@%@", OR_WS_PREFIX_DELETED, [object.objectID.URIRepresentation absoluteString]]];
	}
}

@end
