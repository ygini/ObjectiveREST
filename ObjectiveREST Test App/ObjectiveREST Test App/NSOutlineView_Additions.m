//
//  NSOutlineView_Additions.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "NSOutlineView_Additions.h"

@implementation NSOutlineView (Additions)

- (void)expandParentsOfItem:(id)item {
    while (item != nil) {
        id parent = [self parentForItem: item];
        if (![self isExpandable: parent])
            break;
        if (![self isItemExpanded: parent])
            [self expandItem: parent];
        item = parent;
    }
}

- (void)selectItem:(id)item {
    NSInteger itemIndex = [self rowForItem:item];
    if (itemIndex < 0) {
        [self expandParentsOfItem: item];
        itemIndex = [self rowForItem:item];
        if (itemIndex < 0)
            return;
    }
	
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: itemIndex] byExtendingSelection: NO];
}
@end
