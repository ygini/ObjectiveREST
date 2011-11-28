//
//  NSString-UUID.m
//  PadAdmin
//
//  Created by Yoann GINI on 01/03/10.
//  Copyright 2010 iNig-Services. All rights reserved.
//

#import "NSString-UUID.h"


@implementation NSString (UUID)

+(NSString*)stringWithNewUUID
{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *newUUID = (NSString*) CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [newUUID autorelease];
}

@end
