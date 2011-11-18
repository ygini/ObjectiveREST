//
//  NSString_Addition.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "NSString_Addition.h"
#import "NSDataAdditions.h"

@implementation NSString (Addition)


- (NSString *)base64EncodedString
{	
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
}
@end
