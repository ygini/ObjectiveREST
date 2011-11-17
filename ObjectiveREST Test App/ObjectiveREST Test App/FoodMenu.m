//
//  FoodMenu.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "FoodMenu.h"
#import "NSString-UUID.h"

@implementation FoodMenu

@dynamic content;
@dynamic name;
@dynamic price;
@dynamic rest_uuid;

- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self != nil) {
        if (!self.rest_uuid) self.rest_uuid = [NSString stringWithNewUUID];
    }
    return self;
}

@end