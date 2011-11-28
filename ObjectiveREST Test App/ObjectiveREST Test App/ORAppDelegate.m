//
//  ORAppDelegate.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ORAppDelegate.h"

#import <ObjectiveREST/RESTManager.h>
#import <ObjectiveREST/RESTManagedObject.h>
#import "NSOutlineView_Additions.h"

@implementation ORAppDelegate

@synthesize window = _window;

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize HTTPSCheckBox = _HTTPSCheckBox;
@synthesize AuthenticationCheckBox = _AuthenticationCheckBox;
@synthesize TCPPortTextField = _TCPPortTextField;
@synthesize StartAndStopButton = _StartAndStopButton;
@synthesize UsernameTextField = _UsernameTextField;
@synthesize PasswordTextField = _PasswordTextField;
@synthesize PatchedModelCheckBox = _PatchedModelCheckBox;
@synthesize ServerStateLabel = _ServerStateLabel;
@synthesize EntitiesOutlineView = _EntitiesOutlineView;
@synthesize EntityContentTableView = _EntityContentTableView;

#pragma mark - GUI Management

- (void)updateGUI{
	BOOL guiControlState = NO;
	
	self.HTTPSCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestHTTPS"] ? NSOnState : NSOffState;
	self.AuthenticationCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestAuthentication"] ? NSOnState : NSOffState;
	self.UsernameTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerLogin"];
	self.PasswordTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerPassword"];
	self.TCPPortTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerTCPPort"];
	
	if ([RESTManager sharedInstance].isRunning) {
		guiControlState = NO;
		
		self.ServerStateLabel.stringValue = @"Server is running";
		self.StartAndStopButton.title = @"Stop";
	} else {
		guiControlState = YES;
		
		self.ServerStateLabel.stringValue = @"Server isn't running";
		self.StartAndStopButton.title = @"Start";
	}
	
	[self.HTTPSCheckBox setEnabled:guiControlState];
	[self.AuthenticationCheckBox setEnabled:guiControlState];
	[self.TCPPortTextField setEnabled:guiControlState];
	[self.UsernameTextField setEnabled:guiControlState];
	[self.PasswordTextField setEnabled:guiControlState];
	
	[self.EntitiesOutlineView reloadData];
	[self.EntityContentTableView reloadData];
}

#pragma mark - Actions

- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)startServerAction:(id)sender {
	if ([RESTManager sharedInstance].isRunning) {
		[[RESTManager sharedInstance] stopServer];
	} else {
		[[RESTManager sharedInstance].authenticationDatabase removeAllObjects];
		[[RESTManager sharedInstance].authenticationDatabase setValue:self.PasswordTextField.stringValue forKey:self.UsernameTextField.stringValue];
		[RESTManager sharedInstance].modelIsObjectiveRESTReady = self.PatchedModelCheckBox.state == NSOnState;
		[RESTManager sharedInstance].requestHTTPS = self.HTTPSCheckBox.state == NSOnState;
		[RESTManager sharedInstance].requestAuthentication = self.AuthenticationCheckBox.state == NSOnState;
		[RESTManager sharedInstance].mDNSType = @"_http._tcp";
		[RESTManager sharedInstance].tcpPort = [self.TCPPortTextField intValue];
		
		[[RESTManager sharedInstance] startServer];
	}
	[self updateGUI];
}

- (IBAction)settingsHaveChanges:(id)sender {
	if (![RESTManager sharedInstance].isRunning) {
		[[NSUserDefaults standardUserDefaults] setBool:self.HTTPSCheckBox.state == NSOnState
												forKey:@"ServerRequestHTTPS"];
		[[NSUserDefaults standardUserDefaults] setBool:self.AuthenticationCheckBox.state == NSOnState
												forKey:@"ServerRequestAuthentication"];
		[[NSUserDefaults standardUserDefaults] setBool:self.PatchedModelCheckBox.state == NSOnState
												forKey:@"PatchedModel"];
		[[NSUserDefaults standardUserDefaults] setValue:self.UsernameTextField.stringValue
												 forKey:@"ServerLogin"];
		[[NSUserDefaults standardUserDefaults] setValue:self.PasswordTextField.stringValue
												 forKey:@"ServerPassword"];
		[[NSUserDefaults standardUserDefaults] setValue:self.TCPPortTextField.stringValue
												 forKey:@"ServerTCPPort"];
	}
	
	[self updateGUI];
}

- (IBAction)refreshAction:(id)sender {
	[self updateGUI];
}

- (IBAction)addEntity:(id)sender {
	id selectedItem = [self.EntitiesOutlineView itemAtRow:[self.EntitiesOutlineView selectedRow]];
	NSEntityDescription *entityDesc = nil;
	
	if ([selectedItem isKindOfClass:[NSEntityDescription class]]) entityDesc = selectedItem;
	else entityDesc = [self.EntitiesOutlineView parentForItem:selectedItem];
	
	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDesc name]
															   inManagedObjectContext:self.managedObjectContext];
    
    // Relationships autopilot 
    NSDictionary *relationships = [[newObject entity] relationshipsByName];
    
    [relationships enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSRelationshipDescription *r = (NSRelationshipDescription *)obj;
        [newObject setValue:[NSEntityDescription insertNewObjectForEntityForName:[[r destinationEntity] name]
                                                          inManagedObjectContext:self.managedObjectContext] forKey:key];
    }];
	
	[self updateGUI];
	
	[self.EntitiesOutlineView selectItem:newObject];
}

- (IBAction)removeEntity:(id)sender {
	[self.managedObjectContext deleteObject:[self selectedEntity]];
	[self updateGUI];
}

- (NSArray*)managedObjectsWithEntityName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[self.managedObjectContext executeFetchRequest:request error:&err] sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject<RESTManagedObject>* obj1, NSManagedObject<RESTManagedObject>* obj2) {
		if ([obj1 respondsToSelector:@selector(compare:)])
			return [obj1 compare:obj2];
		return [[[[obj1 objectID] URIRepresentation] absoluteString] compare:[[[obj2 objectID] URIRepresentation] absoluteString]];
	}];
}

- (NSManagedObject*)selectedEntity {
	id selectedItem = [self.EntitiesOutlineView itemAtRow:[self.EntitiesOutlineView selectedRow]];
	if ([selectedItem isKindOfClass:[NSEntityDescription class]]) return nil;
	else return selectedItem;
}

#pragma mark - NSOutlineView

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {		// Root
		return [_entitiesList count];
	} else {				// Entity, find the total of existing entries for this kind
		return [[self managedObjectsWithEntityName:[((NSEntityDescription*)item) name]] count];
	}
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[NSEntityDescription class]] && [[self managedObjectsWithEntityName:[((NSEntityDescription*)item) name]] count] > 0;	// Only one level of expandable items for this demo
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {		// Root
		return [_entitiesList objectAtIndex:index];
	} else {				// Entity, find the total of existing entries for this kind
		return [[[self managedObjectsWithEntityName:[((NSEntityDescription*)item) name]] objectAtIndex:index] retain];
		#warning Memory leak insert here, the outline view don't retain items and we dont keep it too. It's a test applications so we can let it like that but if it's possible, a fix should be welcome
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[NSEntityDescription class]]) {
		return [((NSEntityDescription*)item) name];
	} else return [item description];
}

#pragma mark - NSTableView

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[[self selectedEntity] entity] properties] count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	NSString *key = [[[[[[self selectedEntity] entity] propertiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:row];
	
	if ([[tableColumn identifier] isEqualToString:@"key"]) return key;
	else if ([[tableColumn identifier] isEqualToString:@"value"]) {
		id value = [[self selectedEntity] valueForKey:key];
        
        if ([value isKindOfClass:[NSManagedObject class]])
            return [NSNumber numberWithUnsignedInteger:[[self managedObjectsWithEntityName:[[value entity] name]] indexOfObject:value]];
        
		return value;
	}
	else return nil;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
	NSString *key = [[[[[[self selectedEntity] entity] propertiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:row];
    
    id value = [[self selectedEntity] valueForKey:key];
    
    if (![value isKindOfClass:[NSManagedObject class]])    
        [[self selectedEntity] setValue:object forKey:key];
    else
        [[self selectedEntity] setValue:[[self managedObjectsWithEntityName:[[value entity] name]] objectAtIndex:[object intValue]]
								 forKey:key];
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (tableColumn) {
		
		if ([[tableColumn identifier] isEqualToString:@"value"]) {
			NSString *key = [[[[[[self selectedEntity] entity] propertiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:row];
			
			id value = [[self selectedEntity] valueForKey:key];
			
			if ([value isKindOfClass:[NSManagedObject class]]) {
				NSPopUpButtonCell* cell = [[[NSPopUpButtonCell alloc] init] autorelease];
				NSMenu *menu = [[NSMenu alloc] initWithTitle:@"To-one relationship"];
				
				NSArray *values = [self managedObjectsWithEntityName:[[value entity] name]];
				
				[values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[obj description] action:nil keyEquivalent:@""];
					[menu addItem:menuItem];
					[menuItem release];
				}];
				
				[cell setMenu:menu];
				
				[menu release];
				
				return cell;
			}
		}
		
		return [tableColumn dataCellForRow:row];
	}
	
    return nil;
}

#pragma mark Notification

-(void)outlineViewDidChangeSelection:(NSNotification*)notif {
	[self.EntityContentTableView reloadData];
}

#pragma mark - Application LifeCycle

- (void)dealloc
{
	[__persistentStoreCoordinator release];
	[__managedObjectModel release];
	[__managedObjectContext release];
	
	[_entitiesList release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	// Get the list of entities and save a list ordered by entities name
	// We assume the list of entities can't change during the runtime
	_entitiesList = [[NSArray alloc] initWithArray:
					 [[[self managedObjectModel] entities] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[((NSEntityDescription*)obj1) name] compare:[((NSEntityDescription*)obj2) name]];
	}]];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:NO], @"ServerRequestHTTPS",
															 [NSNumber numberWithBool:NO], @"ServerRequestAuthentication",
															 [NSNumber numberWithBool:YES], @"PatchedModel",
															 @"alice", @"ServerLogin",
															 @"bob", @"ServerPassword",
															 @"1984", @"ServerTCPPort",
															 nil]];
	
	[RESTManager sharedInstance].persistentStoreCoordinator = self.persistentStoreCoordinator;
	[RESTManager sharedInstance].managedObjectModel = self.managedObjectModel;
	[RESTManager sharedInstance].managedObjectContext = self.managedObjectContext;
	//[RESTManager sharedInstance].modelIsObjectiveRESTReady = YES;
	[RESTManager sharedInstance].allowDeleteOnCollection = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewDidChangeSelection:)
												 name:NSOutlineViewSelectionDidChangeNotification 
											   object:self.EntitiesOutlineView];
	
	[self updateGUI];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}


#pragma mark - CoreData

/**
 Returns the directory the application uses to store the Core Data store file. This code uses a directory named "ObjectiveREST_Test_App" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
	return [libraryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Application Support/%@", [[NSBundle mainBundle] bundleIdentifier]]];
}

/**
 Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
	if (__managedObjectModel) {
		return __managedObjectModel;
	}
	
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ObjectiveREST_Server_Demo" withExtension:@"momd"];
	__managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (__persistentStoreCoordinator) {
		return __persistentStoreCoordinator;
	}
	
	NSManagedObjectModel *mom = [self managedObjectModel];
	if (!mom) {
		NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
	NSError *error = nil;
	
	NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
	if (!properties) {
		BOOL ok = NO;
		if ([error code] == NSFileReadNoSuchFileError) {
			ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
		}
		if (!ok) {
			[[NSApplication sharedApplication] presentError:error];
			return nil;
		}
	}
	else {
		if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
			// Customize and localize this error.
			NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
			
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
			error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
			
			[[NSApplication sharedApplication] presentError:error];
			return nil;
		}
	}
	
	NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"ObjectiveREST_Test_App.storedata"];
	NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
	if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
		[[NSApplication sharedApplication] presentError:error];
		return nil;
	}
	__persistentStoreCoordinator = [coordinator retain];
	
	return __persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
	if (__managedObjectContext) {
		return __managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (!coordinator) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
		[dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
		NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
		[[NSApplication sharedApplication] presentError:error];
		return nil;
	}
	__managedObjectContext = [[NSManagedObjectContext alloc] init];
	[__managedObjectContext setPersistentStoreCoordinator:coordinator];
	
	return __managedObjectContext;
}

/**
 Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
	return [[self managedObjectContext] undoManager];
}



@end
