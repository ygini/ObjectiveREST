//
//  ORHTTPDataResponse.h
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "HTTPDataResponse.h"

@interface ORHTTPDataResponse : HTTPDataResponse
@property (retain, nonatomic) NSMutableDictionary *httpHeaders;
@end
