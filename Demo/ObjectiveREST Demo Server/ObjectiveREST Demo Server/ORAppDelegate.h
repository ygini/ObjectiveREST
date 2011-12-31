//
//  ORAppDelegate.h
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

/*
 This application is made as a test server for the ObjectiveREST framework
 
 Set the server settings and fill the content in the main window application 
 then start the server to provide a REST interface to your data
 */

#import <Cocoa/Cocoa.h>
#import <ObjectiveREST/ObjectiveREST.h>

@class ORTableColumn;

@interface ORAppDelegate : NSObject <NSApplicationDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource, RESTManagerDelegate> {
	NSArray *_entitiesList;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (assign) IBOutlet NSButton *HTTPSCheckBox;
@property (assign) IBOutlet NSButton *AuthenticationCheckBox;
@property (assign) IBOutlet NSTextField *TCPPortTextField;
@property (assign) IBOutlet NSButton *StartAndStopButton;
@property (assign) IBOutlet NSTextField *UsernameTextField;
@property (assign) IBOutlet NSTextField *PasswordTextField;
@property (assign) IBOutlet NSButton *PatchedModelCheckBox;

@property (assign) IBOutlet NSTextField *ServerStateLabel;

@property (assign) IBOutlet NSOutlineView *EntitiesOutlineView;
@property (assign) IBOutlet NSTableView *EntityContentTableView;


- (IBAction)saveAction:(id)sender;

- (IBAction)startServerAction:(id)sender;

- (IBAction)settingsHaveChanges:(id)sender;

- (IBAction)refreshAction:(id)sender;

- (void)updateGUI;

- (IBAction)addEntity:(id)sender;
- (IBAction)removeEntity:(id)sender;

- (NSArray*)managedObjectsWithEntityName:(NSString*)name;
- (NSManagedObject*)selectedEntity;

@end
