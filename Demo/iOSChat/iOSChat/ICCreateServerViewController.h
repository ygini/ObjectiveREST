//
//  ICCreateServerViewController.h
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICCreateServerViewController : UIViewController <UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITextField *serverNameLabel;

- (IBAction)createServer:(id)sender;

@end
