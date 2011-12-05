//
//  ICChatViewController.m
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ICChatViewController.h"

#import "ICMessageProvider.h"

@implementation ICChatViewController
@synthesize roomTextView;
@synthesize messageTextField;
@synthesize contentView;

- (void)updateMessages {
    
    NSArray *messages = [[ICMessageProvider sharedInstance].messages sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 valueForKey:@"date"] compare:[obj2 valueForKey:@"date"]];
    }];
    
    
    NSMutableString *display = [NSMutableString new];
    
    NSString *nickname, *dateString, *message;
    NSDate *date;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    for (id messageInfo in messages) {
        nickname = [messageInfo valueForKey:@"nickname"];
        date = [messageInfo valueForKey:@"date"];
        message = [messageInfo valueForKey:@"message"];
        
        dateString = [dateFormatter stringFromDate:date];
        
        // En <nick> HH:MM: message
        // FR [HH:MM] nick: message
        [display appendFormat:NSLocalizedString(@"format", @""), nickname, dateString, message];
    }
    
    [dateFormatter release];
    
    if (!_updateOffset) 
        _updateOffset = 
        (self.roomTextView.contentOffset.y == self.roomTextView.contentSize.height - self.roomTextView.frame.size.height)
        || self.roomTextView.contentSize.height < self.roomTextView.frame.size.height;
    
    self.roomTextView.text = display;
    
    [display release];
    
    if (_updateOffset) [self.roomTextView setContentOffset:CGPointMake(0, self.roomTextView.contentSize.height - self.roomTextView.frame.size.height) 
                                                 animated:NO];
    
    _updateOffset = NO;
}

- (void)automaticUpdateMessages {
    [self updateMessages];
    
    if (_continueAutomaticRefresh) [self performSelector:@selector(automaticUpdateMessages) 
                                              withObject:nil 
                                              afterDelay:3];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {_updateOffset = YES;
    [[ICMessageProvider sharedInstance] sendMessage:self.messageTextField.text];
    self.messageTextField.text = @"";
    [self updateMessages];
}





- (void)keyboardWillShow:(NSNotification *)notif {
    
    [UIView beginAnimations:@"Keyboard" context:nil];
    
    NSValue *endFrame = [[notif userInfo] valueForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect contentFrame = self.contentView.frame;
    
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft ||
        [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        contentFrame.size.height -= [endFrame CGRectValue].size.width;
    } else {
        contentFrame.size.height -= [endFrame CGRectValue].size.height;
    }
    
    
    
    self.contentView.frame = contentFrame;
    
    [UIView commitAnimations];
       
    CGPoint contentOffset = self.roomTextView.contentOffset;
    contentOffset.y += [endFrame CGRectValue].size.height;
    [self.roomTextView setContentOffset:contentOffset animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notif {
    
    
    [UIView beginAnimations:@"Keyboard" context:nil];
    
    NSValue *endFrame = [[notif userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey];
    
    CGRect contentFrame = self.contentView.frame;
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft ||
        [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        contentFrame.size.height += [endFrame CGRectValue].size.width;
    } else {
        contentFrame.size.height += [endFrame CGRectValue].size.height;
    }
    
    self.contentView.frame = contentFrame;
    
    [UIView commitAnimations];
    
    
    CGPoint contentOffset = self.roomTextView.contentOffset;
    contentOffset.y -= [endFrame CGRectValue].size.height;
    [self.roomTextView setContentOffset:contentOffset animated:YES];
}

- (void)serverUnavaiable:(NSNotification *)notif {
    UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:@"Erreur" 
                                                     message:@"Serveur indisponible" 
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil] autorelease];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    _continueAutomaticRefresh = YES;
    _updateOffset = YES;
    [self automaticUpdateMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:self.view.window]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:self.view.window]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(serverUnavaiable:) 
                                                 name:kICMessageProviderServerUnaviable 
                                               object:self.view.window]; 
}

-(void)viewDidDisappear:(BOOL)animated {
    _continueAutomaticRefresh = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillShowNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:kICMessageProviderServerUnaviable 
                                                  object:nil];
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
    [self setRoomTextView:nil];
    [self setMessageTextField:nil];
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
