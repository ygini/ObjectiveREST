//
//  RCChatViewController.m
//  iOS REST Chat
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RCChatViewController.h"
#import "RCAppDelegate.h"

@implementation RCChatViewController
@synthesize chatRoom;
@synthesize textEntry;

- (void)updateMessage {
    NSArray *messages = [[[RCAppDelegate sharedInstance] getMessages] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [[obj1 valueForKey:@"date"] compare:[obj2 valueForKey:@"date"]];
    }];
    
    NSMutableString *display = [NSMutableString new];
    for (NSDictionary *msgInfo in messages) {
        [display appendFormat:@"User: %@\nMessage:\n%@\n\n", [msgInfo valueForKey:@"nickname"], [msgInfo valueForKey:@"message"]];
    }
    
    self.chatRoom.text = display;
    [display release];
    
    [self.chatRoom setContentOffset:CGPointMake(0, self.chatRoom.contentSize.height - self.chatRoom.frame.size.height)];
}

- (void)automaticUpdateMessage {
    [self updateMessage];
    [self performSelector:@selector(automaticUpdateMessage) withObject:nil afterDelay:3];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [self setChatRoom:nil];
    [self setTextEntry:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [chatRoom release];
    [textEntry release];
    [super dealloc];
}

-(void)viewWillAppear:(BOOL)animated {
    [self updateMessage];
}

#pragma mark - TextField

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [[RCAppDelegate sharedInstance] sendMessage:textField.text];
    textField.text = @"";
    [self updateMessage];
}

@end
