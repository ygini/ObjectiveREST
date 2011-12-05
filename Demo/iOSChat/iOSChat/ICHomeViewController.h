//
//  ICHomeViewController.h
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICHomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    NSNetServiceBrowser *_serviceBrowser;
    NSMutableArray *_discoveredServices;
}
@property (retain, nonatomic) IBOutlet UITextField *nicknameField;
@property (retain, nonatomic) IBOutlet UITableView *nearServerTableView;

@end
