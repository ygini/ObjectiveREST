//
//  ORAppDelegate.h
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	kContentTypeBPlist,
	kContentTypePlist,
	kContentTypeJSON
} kContentType;

@interface ORAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate> {
	NSMutableArray *_rootContent;
	
	NSMutableDictionary *_displayedContent;
	NSMutableArray *_itemKeyValueCache;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *HTTPSCheckBox;
@property (assign) IBOutlet NSButton *AuthenticationCheckBox;
@property (assign) IBOutlet NSTextField *UsernameTextField;
@property (assign) IBOutlet NSTextField *PasswordTextField;
@property (assign) IBOutlet NSTextField *ServerAddressTextField;
@property (assign) IBOutlet NSTextField *TCPPortTextField;
@property (assign) IBOutlet NSButton *ConnectButton;
@property (assign) IBOutlet NSOutlineView *EntitiesOutlineView;
@property (assign) IBOutlet NSButtonCell *BPlistRadioButton;
@property (assign) IBOutlet NSButtonCell *PlistRadioButton;
@property (assign) IBOutlet NSButtonCell *JSONRadioButton;
@property (assign) IBOutlet NSMatrix *ContentTypeMatrix;
@property (assign) IBOutlet NSTextField *StateTextField;

- (void)updateSateLine;
- (void)updateGUI;

- (void)updateSelectedContentTypeWithSender:(NSButtonCell*)sender;

- (IBAction)connectAction:(id)sender;
- (IBAction)deleteEntryAction:(id)sender;

- (NSString*)selectedContentType;
- (BOOL)isConnected;

- (IBAction)guiHasChange:(id)sender;


@end
