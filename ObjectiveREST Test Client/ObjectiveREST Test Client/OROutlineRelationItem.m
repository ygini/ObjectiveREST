//
//  OROutlineRelationItem.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 27/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "OROutlineRelationItem.h"

@implementation OROutlineRelationItem

@synthesize key, value;

+(OROutlineRelationItem*)itemWithKey:(NSString*)key andValue:(id)value {
	OROutlineRelationItem *item = [OROutlineRelationItem new];
	item.key = key;
	item.value = value;
	return [item autorelease];
}

@end
