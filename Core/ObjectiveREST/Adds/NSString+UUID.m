//
//  NSString+UUID.m
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+(NSString*)UUIDString
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *newUUID = (NSString*) CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [newUUID autorelease];
}

@end
