//
//  FoodMenu.h
//  ObjectiveREST Test App
//
//  Created by HiDeo on 19/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FoodMenu;

@interface FoodMenu : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) NSString * rest_uuid;
@property (nonatomic, retain) FoodMenu *foodNumber;

@end
