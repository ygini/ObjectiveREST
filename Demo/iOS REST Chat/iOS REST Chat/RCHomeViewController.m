//
//  RCHomeViewController.m
//  iOS REST Chat
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RCHomeViewController.h"

#import "RCAppDelegate.h"
#import "RCChatViewController.h"
#import <ObjectiveREST.h>

@implementation RCHomeViewController

@synthesize nearServerTableView;

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];   
    _discoveredServices = [NSMutableArray new]; 
    
    _serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [_serviceBrowser setDelegate:self];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    
    [_serviceBrowser release];
    _serviceBrowser = nil;
    [_discoveredServices release];
    _discoveredServices = nil;
}

-(void)viewWillAppear:(BOOL)animated {
    [_discoveredServices removeAllObjects];
    [_serviceBrowser searchForServicesOfType:CHAT_NET_SERVICE_TYPE inDomain:@""];
}

-(void)viewDidDisappear:(BOOL)animated {
    [_serviceBrowser stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - NetBrowser

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:0];
    [_discoveredServices addObject:aNetService];
    if(!moreComing) {
        [self.nearServerTableView reloadData];
    }
}

// Sent when a service disappears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    [_discoveredServices removeObject:aNetService];
    
    if(!moreComing) {
        [self.nearServerTableView reloadData];
        [self.nearServerTableView reloadData];
    }
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [_discoveredServices removeObject:sender];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender {
}

#pragma mark - UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_discoveredServices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"MyCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	// -- Unused with storyboard
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	// --
	
    NSNetService *services = [_discoveredServices objectAtIndex:[indexPath row]];
	cell.textLabel.text = [services name];
	
	return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Services";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSNetService *services = [[_discoveredServices objectAtIndex:[indexPath row]] retain];
    
    [RESTClient sharedInstance].tcpPort = 0;
    [RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
    [RESTClient sharedInstance].tcpPort = [services port];
    [RESTClient sharedInstance].serverAddress = [services hostName];
    
    [services release];
    
    [self performSegueWithIdentifier:@"goToChat" sender:self];
}
@end
