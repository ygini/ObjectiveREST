//
//  OROutlineRelationItem.h
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 27/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OROutlineKeyValueItem.h"

@interface OROutlineRelationItem : NSObject
@property (retain) NSString *key;
@property (retain) id value;

+(OROutlineRelationItem*)itemWithKey:(NSString*)key andValue:(id)value;
@end
