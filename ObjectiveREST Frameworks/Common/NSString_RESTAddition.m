//
//  NSString_RESTAddition.m
//  ObjectiveREST
//
//  Created by Yoann Gini on 28/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "NSString_RESTAddition.h"
#import "NSDataAdditions.h"

@implementation NSString (RESTAddition)

+(NSString*)stringWithNewUUIDForREST
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *newUUID = (NSString*) CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [newUUID autorelease];
}

- (NSString *)RESTbase64EncodedString
{	
	return [[self dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
}

@end
