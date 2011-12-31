//
//  RESTManagerDelegate.h
//  ObjectiveREST OS X
//
//  Created by Yoann Gini on 08/12/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RESTManager, HTTPMessage;

@protocol RESTManagerDelegate <NSObject>

- (NSString*)manager:(RESTManager*)manager withRequest:(HTTPMessage*)request requestPasswordForUser:(NSString*)userName;
- (NSData*)manager:(RESTManager*)manager withRequest:(HTTPMessage*)request externalCommandForMethod:(NSString*)method withURI:(NSString*)path;

@end
