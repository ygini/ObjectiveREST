//
//  OROutlineKeyValueItem.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "OROutlineKeyValueItem.h"

@implementation OROutlineKeyValueItem

@synthesize key, value;

+(OROutlineKeyValueItem*)itemWithKey:(NSString*)key andValue:(id)value {
	OROutlineKeyValueItem *item = [OROutlineKeyValueItem new];
	item.key = key;
	item.value = value;
	return [item autorelease];
}

@end
