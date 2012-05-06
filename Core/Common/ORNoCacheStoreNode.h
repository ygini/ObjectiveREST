//
//  ORNoCacheStoreNode.h
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ORNoCacheStoreNode : NSAtomicStoreCacheNode
@property (retain) NSString *remoteURL;
@property (assign) BOOL ORNodeIsDirty;
@end
