//
//  ORHTTPDataResponse.m
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORHTTPDataResponse.h"

@implementation ORHTTPDataResponse
@synthesize httpHeaders = _httpHeaders;
@synthesize contentLength = _contentLength;

-(id)initWithData:(NSData *)aData {
    self = [super initWithData:aData];
    if (self) {
        _httpHeaders = [NSMutableDictionary new];
		_contentLength = [aData length];
    }
    return self;
}

- (void)dealloc {
    [_httpHeaders release], _httpHeaders = nil;
    [super dealloc];
}

@end
