//
//  RCHomeViewController.h
//  iOS REST Chat
//
//  Created by Yoann Gini on 29/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//



@interface RCHomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    NSNetServiceBrowser *_serviceBrowser;
    NSMutableArray *_discoveredServices;
}

@property (retain) IBOutlet UITableView *nearServerTableView;

@end
