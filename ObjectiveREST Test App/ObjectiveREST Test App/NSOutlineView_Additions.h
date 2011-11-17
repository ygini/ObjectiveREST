//
//  NSOutlineView_Additions.h
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOutlineView (Additions)
- (void)expandParentsOfItem:(id)item;
- (void)selectItem:(id)item;
@end
