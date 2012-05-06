//
//  ORServerConnection.h
//  ORDemoServer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "HTTPConnection.h"

@class ORServer;

#define OR_SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]
#define	OR_REF_KEYWORD                          @"rest_ref"

@interface ORServerConnection : HTTPConnection {
    ORServer *_httpServer;
    NSString *_requestedContentType;
}

@end
