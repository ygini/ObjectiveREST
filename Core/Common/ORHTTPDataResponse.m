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

-(id)initWithData:(NSData *)aData {
    self = [super initWithData:aData];
    if (self) {
        _httpHeaders = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_httpHeaders release], _httpHeaders = nil;
    [super dealloc];
}
@end
