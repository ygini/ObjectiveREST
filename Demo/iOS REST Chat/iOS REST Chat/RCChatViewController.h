//
//  RCChatViewController.h
//  iOS REST Chat
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCChatViewController : UIViewController <UITextFieldDelegate> {
    BOOL _continueAutoRefresh;
}

@property (retain, nonatomic) IBOutlet UITextView *chatRoom;
@property (retain, nonatomic) IBOutlet UITextField *textEntry;

@end
