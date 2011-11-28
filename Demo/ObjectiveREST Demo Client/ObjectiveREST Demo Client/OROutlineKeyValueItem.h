//
//  OROutlineKeyValueItem.h
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OROutlineKeyValueItem : NSObject

@property (retain) NSString *key;
@property (retain) id value;

+(OROutlineKeyValueItem*)itemWithKey:(NSString*)key andValue:(id)value;

@end
