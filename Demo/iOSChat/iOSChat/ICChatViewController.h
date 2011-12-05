//
//  ICChatViewController.h
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICChatViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate> {
    BOOL _continueAutomaticRefresh;
    BOOL _updateOffset;
}

@property (retain, nonatomic) IBOutlet UITextView *roomTextView;
@property (retain, nonatomic) IBOutlet UITextField *messageTextField;
@property (retain, nonatomic) IBOutlet UIView *contentView;

@end
