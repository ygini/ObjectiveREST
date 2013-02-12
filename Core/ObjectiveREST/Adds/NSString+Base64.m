//
//  NSString+Base64.m
//  StarDAV
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "NSString+Base64.h"

#import "NSDataAdditions.h"

@implementation NSString (Base64)

- (NSString *)base64EncodedString
{	
	return [[self dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
}

@end
