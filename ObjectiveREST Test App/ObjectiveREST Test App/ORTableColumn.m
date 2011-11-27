//
//  ORTableColumn.m
//  ObjectiveREST Test App
//
//  Created by HiDeo on 26/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ORTableColumn.h"
#import "ORAppDelegate.h"

@implementation ORTableColumn

-(id)dataCellForRow:(NSInteger)row
{
    id delegate = [[self tableView] delegate];
    
    SEL selector = @selector(tableView:dataCellForRow:column:);
    
    if ([delegate respondsToSelector:selector] && row >= 0) {
        id cell = nil;
        
        cell = (ORAppDelegate *)[delegate tableView:[self tableView] dataCellForRow:row column:self];
        
        if (cell) 
            return cell;
    }
    
    return [self dataCell];
}

@end
