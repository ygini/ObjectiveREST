//
//  ICCreateServerViewController.m
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ICCreateServerViewController.h"

#import "ICMessageProvider.h"

@implementation ICCreateServerViewController
@synthesize serverNameLabel;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    self.serverNameLabel.placeholder = [[UIDevice currentDevice] name];
}

- (void)viewDidUnload
{
    [self setServerNameLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewDidAppear:(BOOL)animated {
    self.serverNameLabel.text = [ICMessageProvider sharedInstance].serverName;
    [[ICMessageProvider sharedInstance] stopServer];
    [self.serverNameLabel becomeFirstResponder];
}

- (IBAction)createServer:(id)sender {
    [self.serverNameLabel resignFirstResponder];
    [[ICMessageProvider sharedInstance] startServer];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [ICMessageProvider sharedInstance].serverName = self.serverNameLabel.text;
    [[NSUserDefaults standardUserDefaults] setValue:self.serverNameLabel.text
                                             forKey:@"servername"];
}

@end
