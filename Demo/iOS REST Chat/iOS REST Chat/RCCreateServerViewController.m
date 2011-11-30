//
//  RCCreateServerViewController.m
//  iOS REST Chat
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RCCreateServerViewController.h"

#import <ObjectiveREST.h>
#import "RCAppDelegate.h"

@implementation RCCreateServerViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void)viewDidAppear:(BOOL)animated {
    [[RESTManager sharedInstance] stopServer];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)createNewServer:(id)sender {
    [RESTManager sharedInstance].mDNSType = CHAT_NET_SERVICE_TYPE;
    [RESTManager sharedInstance].tcpPort = 0;
    [RESTManager sharedInstance].modelIsObjectiveRESTReady = NO;
    
    [RESTManager sharedInstance].managedObjectModel = [RCAppDelegate sharedInstance].managedObjectModel;
    [RESTManager sharedInstance].persistentStoreCoordinator = [RCAppDelegate sharedInstance].persistentStoreCoordinator;
    [RESTManager sharedInstance].managedObjectContext = [RCAppDelegate sharedInstance].managedObjectContext;
    
    [[RESTManager sharedInstance] startServer];
}

@end
