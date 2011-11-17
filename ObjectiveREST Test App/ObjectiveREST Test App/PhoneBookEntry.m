//
//  PhoneBookEntry.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "PhoneBookEntry.h"
#import "NSString-UUID.h"


@implementation PhoneBookEntry

@dynamic internal;
@dynamic name;
@dynamic number;
@dynamic rest_uuid;

- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self != nil) {
        if (!self.rest_uuid) self.rest_uuid = [NSString stringWithNewUUID];    }
    return self;
}

@end