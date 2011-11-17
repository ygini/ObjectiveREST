//
//  NSManagedObject+Additions.m
//  ObjectiveREST Test App
//
//  Created by HiDeo on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "NSManagedObject+Additions.h"

@implementation NSManagedObject (Additions)

- (NSDictionary *)dictionnaryValue
{
	NSArray *a = [[[self entity] attributesByName] allKeys];
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:[a count]];
    
	for (NSString *s in a) {
		NSObject *v = [self valueForKey:s];
        
		if (v != nil)
			[d setObject:v forKey:s];
	}
    
	return d;
}

@end
