//
//  ICHomeViewController.m
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ICHomeViewController.h"
#import "ICMessageProvider.h"
#import "ICAppDelegate.h"

@implementation ICHomeViewController
@synthesize nicknameField;
@synthesize nearServerTableView = _nearServerTableView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];   
    _discoveredServices = [NSMutableArray new]; 
    
    _serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [_serviceBrowser setDelegate:self];
    [_serviceBrowser searchForServicesOfType:IOSCHAT_M_DNS_TYPE inDomain:@""];
    
    self.title = NSLocalizedString(@"home_label", @"Home text");
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    
    [_serviceBrowser stop];
    
    [self setNicknameField:nil];
    [self setNearServerTableView:nil];
    _serviceBrowser = nil;
    _discoveredServices = nil;
}

-(void)viewWillAppear:(BOOL)animated {
    self.nicknameField.text = [ICMessageProvider sharedInstance].nickName;
}

-(void)viewDidDisappear:(BOOL)animated {
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
    }
    
    if ([[ICMessageProvider sharedInstance].remoteService isEqual:aNetService]) {
        [ICMessageProvider sharedInstance].remoteService = nil;
    }
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [_discoveredServices removeObject:sender];
    [self.nearServerTableView reloadData];
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
    static NSString *cellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        // This part isn't use with storyboard
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }

    cell.textLabel.text = [[_discoveredServices objectAtIndex:[indexPath row]] name];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [ICMessageProvider sharedInstance].remoteService = [_discoveredServices objectAtIndex:[indexPath row]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"goToChat" sender:self];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [ICMessageProvider sharedInstance].nickName = self.nicknameField.text;
    [[NSUserDefaults standardUserDefaults] setValue:self.nicknameField.text
                                             forKey:@"nickname"];
}

@end
