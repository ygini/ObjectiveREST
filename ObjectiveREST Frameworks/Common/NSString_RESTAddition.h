//
//  NSString_RESTAddition.h
//  ObjectiveREST
//
//  Created by Yoann Gini on 28/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RESTAddition)

- (NSString *)RESTbase64EncodedString;
+(NSString*)stringWithNewUUIDForREST;

@end
