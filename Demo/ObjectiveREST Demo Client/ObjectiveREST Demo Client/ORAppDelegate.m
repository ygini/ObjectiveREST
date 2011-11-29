//
//  ORAppDelegate.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ORAppDelegate.h"
#import "OROutlineKeyValueItem.h"
#import "OROutlineRelationItem.h"
#import "NSOutlineView_Additions.h"

#import <ObjectiveREST/ObjectiveREST.h>

@implementation ORAppDelegate

@synthesize window = _window;
@synthesize HTTPSCheckBox = _HTTPSCheckBox;
@synthesize AuthenticationCheckBox = _AuthenticationCheckBox;
@synthesize UsernameTextField = _UsernameTextField;
@synthesize PasswordTextField = _PasswordTextField;
@synthesize ServerAddressTextField = _ServerAddressTextField;
@synthesize TCPPortTextField = _TCPPortTextField;
@synthesize ConnectButton = _ConnectButton;
@synthesize EntitiesOutlineView = _EntitiesOutlineView;
@synthesize BPlistRadioButton = _BPlistRadioButton;
@synthesize PlistRadioButton = _PlistRadioButton;
@synthesize JSONRadioButton = _JSONRadioButton;
@synthesize ContentTypeMatrix = _ContentTypeMatrix;
@synthesize StateTextField = _StateTextField;

#pragma mark GUI

- (void)updateSateLine {
	id item = [self.EntitiesOutlineView selectedItem];
	
	if (![item isKindOfClass:[NSDictionary class]]) {
		item = [self.EntitiesOutlineView parentForItem:item];
	}
	
	self.StateTextField.stringValue = [NSString stringWithFormat:@"%@", [item valueForKey:REST_REF_KEYWORD]];
}

- (void)updateGUI{
	[_displayedContent removeAllObjects];
	[_itemKeyValueCache removeAllObjects];
	
	BOOL guiControlState = NO;
	
	self.HTTPSCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestHTTPS"] ? NSOnState : NSOffState;
	self.AuthenticationCheckBox.state = [[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestAuthentication"] ? NSOnState : NSOffState;
	self.UsernameTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerLogin"];
	self.PasswordTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerPassword"];
	self.TCPPortTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerTCPPort"];
	self.ServerAddressTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerAddress"];
	
	self.BPlistRadioButton.state = NSOffState;
	self.PlistRadioButton.state = NSOffState;
	self.JSONRadioButton.state = NSOffState;
	
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"ContentType"]) {
		case kContentTypeBPlist:
			self.BPlistRadioButton.state = NSOnState;
			break;
		case kContentTypePlist:
			self.PlistRadioButton.state = NSOnState;
			break;
		case kContentTypeJSON:
			self.JSONRadioButton.state = NSOnState;
			break;
	}
	
	if ([self isConnected]) {
		guiControlState = NO;
	} else {
		guiControlState = YES;
	}
	
	[self.HTTPSCheckBox setEnabled:guiControlState];
	[self.AuthenticationCheckBox setEnabled:guiControlState];
	[self.TCPPortTextField setEnabled:guiControlState];
	[self.UsernameTextField setEnabled:guiControlState];
	[self.PasswordTextField setEnabled:guiControlState];
	[self.ServerAddressTextField setEnabled:guiControlState];
	[self.ContentTypeMatrix setEnabled:guiControlState];
	
	[self.EntitiesOutlineView reloadData];
	[self updateSateLine];
}

#pragma mark NSOutlineView

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (!item) {
		return [_rootContent count];		
	} else {
		if ([item isKindOfClass:[NSDictionary class]]) {
			NSString *rest_ref = [((NSDictionary*)item) valueForKey:REST_REF_KEYWORD];
			if (rest_ref) {
				// We are on a dict representing a referenced
                id info = [[[RESTClient sharedInstance] getAbsolutePath:rest_ref] valueForKey:@"content"];
				
				if ([info isKindOfClass:[NSDictionary class]]) {
					// The referenced object is a object
					return [[((NSDictionary*)info) allKeys] count];
				} else if ([info isKindOfClass:[NSArray class]]) {
					// The referenced object is a collection
					return [((NSArray*)info) count];
				}
			} else {
				// We are on dict representing a loaded ManagedObject
				
				return [[((NSDictionary*)item) allKeys] count];
			}
		} else if ([item isKindOfClass:[OROutlineRelationItem class]]) {
			NSString *rest_ref = [((NSDictionary*)((OROutlineRelationItem*)item).value) valueForKey:REST_REF_KEYWORD];
			
			id info = [[[RESTClient sharedInstance] getAbsolutePath:rest_ref] valueForKey:@"content"];
			return [[((NSDictionary*)info) allKeys] count];
		} else if ([item isKindOfClass:[OROutlineKeyValueItem class]]) {
			return 0;
		} else {
			return 0;
		}
	}
	
	return 0;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	id returnValue = nil;
	if (!item) {		
		returnValue =  [_rootContent objectAtIndex:index];		
	} else {
		if ([item isKindOfClass:[NSDictionary class]]) {
			NSString *rest_ref = [((NSDictionary*)item) valueForKey:REST_REF_KEYWORD];
			if (rest_ref) {
				// We are on a dict representing a linked object
                id info = [[[RESTClient sharedInstance] getAbsolutePath:rest_ref] valueForKey:@"content"];
				
				if ([info isKindOfClass:[NSDictionary class]]) {
					// The referenced object is a object
					
					NSArray *allKeys = [[info allKeys] sortedArrayUsingSelector:@selector(compare:)];
					id value = [info valueForKey:[allKeys objectAtIndex:index]];
					
					if ([value isKindOfClass:[NSDictionary class]]) {
						// If the value is a unique relationship
						returnValue = [OROutlineRelationItem itemWithKey:[allKeys objectAtIndex:index] andValue:value];
						[_itemKeyValueCache addObject:returnValue];
					} else if ([value isKindOfClass:[NSArray class]]) {
						// If the value is a to-many relationship
						returnValue = value;
					} else {
						// If the value is a standard object
						returnValue =  [OROutlineKeyValueItem itemWithKey:[allKeys objectAtIndex:index] andValue:value];
						[_itemKeyValueCache addObject:returnValue];
						
					}
				} else if ([info isKindOfClass:[NSArray class]]) {
					// The referenced object is a collection
					returnValue =  [((NSArray*)info) objectAtIndex:index];
				}
			} else {
				// We shouldn't be here…
				returnValue = nil;
			}
		} else if ([item isKindOfClass:[OROutlineRelationItem class]]) {
			NSString *rest_ref = [((NSDictionary*)((OROutlineRelationItem*)item).value) valueForKey:REST_REF_KEYWORD];
			
			id info = [[[RESTClient sharedInstance] getAbsolutePath:rest_ref] valueForKey:@"content"];
			// The referenced object is a object
			
			NSArray *allKeys = [[info allKeys] sortedArrayUsingSelector:@selector(compare:)];
			id value = [info valueForKey:[allKeys objectAtIndex:index]];
			
			if ([value isKindOfClass:[NSDictionary class]]) {
				// If the value is a unique relationship
				returnValue = [OROutlineRelationItem itemWithKey:[allKeys objectAtIndex:index] andValue:value];
				[_itemKeyValueCache addObject:returnValue];
			} else if ([value isKindOfClass:[NSArray class]]) {
				// If the value is a to-many relationship
				returnValue = value;
			} else {
				// If the value is a standard object
				returnValue =  [OROutlineKeyValueItem itemWithKey:[allKeys objectAtIndex:index] andValue:value];
				[_itemKeyValueCache addObject:returnValue];
				
			}
		} else if ([item isKindOfClass:[OROutlineKeyValueItem class]]) {
			returnValue =  nil;
		} else {
			returnValue =  nil;
		}
	}

	return returnValue;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if ([item isKindOfClass:[NSDictionary class]]) {
		return YES;
	} else if ([item isKindOfClass:[OROutlineRelationItem class]]) {
		return YES;
	} else {
		return NO;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([item isKindOfClass:[NSDictionary class]]) {
		NSString *rest_ref = [((NSDictionary*)item) valueForKey:REST_REF_KEYWORD];
		if (rest_ref) {
			if ([[tableColumn identifier] isEqualToString:@"key"])
				return [[NSURL URLWithString:rest_ref] relativePath];
			else return nil;
		} else {
			return nil;
		}
	} else if ([item isKindOfClass:[OROutlineRelationItem class]]) {
		if ([[tableColumn identifier] isEqualToString:@"value"]) {
			NSString *rest_ref = [((NSDictionary*)((OROutlineRelationItem*)item).value) valueForKey:REST_REF_KEYWORD];
			if (rest_ref) {
				NSArray *values = [[RESTClient sharedInstance] getAllObjectOfThisEntityKind:rest_ref];
				int i = 0;
				for (NSDictionary *dict in values) {
					if ([[dict valueForKey:REST_REF_KEYWORD] isEqualToString:rest_ref]) return [NSNumber numberWithInt:i];
					else i++;
				}
			}
		} else return [item valueForKey:@"key"];
	} else if ([item isKindOfClass:[OROutlineKeyValueItem class]]) {
		return [item valueForKey:[tableColumn identifier]];
	}
	
	return nil;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return [item isKindOfClass:[OROutlineKeyValueItem class]] || [item isKindOfClass:[OROutlineRelationItem class]];
}

-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    
    NSDictionary *info = [[RESTClient sharedInstance] getAbsolutePath:self.StateTextField.stringValue];
    
	if ([item isKindOfClass:[OROutlineKeyValueItem class]]) {
		
		[[info valueForKey:@"content"] setValue:object forKey:((OROutlineKeyValueItem*)item).key];
		[[RESTClient sharedInstance] putInfo:info toAbsolutePath:self.StateTextField.stringValue];
		[self updateGUI];
	} else if ([item isKindOfClass:[OROutlineRelationItem class]]) {
		NSString *rest_ref = [((NSDictionary*)((OROutlineRelationItem*)item).value) valueForKey:REST_REF_KEYWORD];
		int i = [object intValue];
		NSString *newRef = [[[[RESTClient sharedInstance] getAllObjectOfThisEntityKind:rest_ref] objectAtIndex:i] valueForKey:REST_REF_KEYWORD];
				
		[[info valueForKey:@"content"] setValue:[NSDictionary dictionaryWithObject:newRef forKey:REST_REF_KEYWORD] forKey:((OROutlineRelationItem*)item).key];
        [[RESTClient sharedInstance] putInfo:info toAbsolutePath:self.StateTextField.stringValue];
		[self updateGUI];
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if (tableColumn) {
		
		if ([item isKindOfClass:[OROutlineRelationItem class]]) {
			if ([[tableColumn identifier] isEqualToString:@"value"]) {
				NSString *rest_ref = [((NSDictionary*)((OROutlineRelationItem*)item).value) valueForKey:REST_REF_KEYWORD];
				
				if (rest_ref) {
					NSPopUpButtonCell* cell = [[[NSPopUpButtonCell alloc] init] autorelease];
					NSMenu *menu = [[NSMenu alloc] initWithTitle:@"To-one relationship"];
					
					NSArray *values = [[RESTClient sharedInstance] getAllObjectOfThisEntityKind:rest_ref];

					[values enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
						NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[[NSURL URLWithString:[obj valueForKey:REST_REF_KEYWORD]] relativePath] action:nil keyEquivalent:@""];
						[menu addItem:menuItem];
						[menuItem release];
					}];
					
					[cell setMenu:menu];
					
					[menu release];
					
					return cell;
				}
			}
		}
		
		return [tableColumn dataCellForRow:[outlineView rowForItem:item]];
	}
	
	return nil;
}


#pragma mark Internal

- (void)updateSelectedContentTypeWithSender:(NSButtonCell*)sender {
	if (self.BPlistRadioButton == sender) [[NSUserDefaults standardUserDefaults] setInteger:kContentTypeBPlist forKey:@"ContentType"];
	else if (self.PlistRadioButton == sender) [[NSUserDefaults standardUserDefaults] setInteger:kContentTypePlist forKey:@"ContentType"];
	else if (self.JSONRadioButton == sender) [[NSUserDefaults standardUserDefaults] setInteger:kContentTypeJSON forKey:@"ContentType"];
}

- (IBAction)connectAction:(id)sender {	
	[_rootContent removeAllObjects];
    
    [RESTClient sharedInstance].requestHTTPS = self.HTTPSCheckBox.state == NSOnState;
    [RESTClient sharedInstance].requestAuthentication = self.AuthenticationCheckBox.state == NSOnState;
    [RESTClient sharedInstance].tcpPort = self.TCPPortTextField.integerValue;
    [RESTClient sharedInstance].serverAddress = self.ServerAddressTextField.stringValue;
    [RESTClient sharedInstance].username = self.UsernameTextField.stringValue;
    [RESTClient sharedInstance].password = self.PasswordTextField.stringValue;
    [RESTClient sharedInstance].contentType = [NSArray arrayWithObject:[self selectedContentType]];
	[_rootContent addObjectsFromArray:[[[RESTClient sharedInstance] getPath:@"/"] valueForKey:@"content"]];
	
	[self updateGUI];
}

- (NSString*)selectedContentType {
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"ContentType"]) {
		case kContentTypeBPlist:
			return @"application/x-bplist";
			break;
		case kContentTypePlist:
			return @"application/x-plist";
			break;
		case kContentTypeJSON:
		default:
			return @"application/json";
			break;
	}
}

- (BOOL)isConnected {
	return self.ConnectButton.state == NSOnState;
}

#pragma mark Actions

- (IBAction)deleteEntryAction:(id)sender {
    [[RESTClient sharedInstance] deleteAbsolutePath:self.StateTextField.stringValue];
	[self updateGUI];
}

- (IBAction)guiHasChange:(id)sender {
	if (![self isConnected]) {
		[[NSUserDefaults standardUserDefaults] setBool:self.HTTPSCheckBox.state == NSOnState
												forKey:@"ServerRequestHTTPS"];
		[[NSUserDefaults standardUserDefaults] setBool:self.AuthenticationCheckBox.state == NSOnState
												forKey:@"ServerRequestAuthentication"];
		[[NSUserDefaults standardUserDefaults] setValue:self.UsernameTextField.stringValue
												 forKey:@"ServerLogin"];
		[[NSUserDefaults standardUserDefaults] setValue:self.PasswordTextField.stringValue
												 forKey:@"ServerPassword"];
		[[NSUserDefaults standardUserDefaults] setValue:self.TCPPortTextField.stringValue
												 forKey:@"ServerTCPPort"];
		[[NSUserDefaults standardUserDefaults] setValue:self.ServerAddressTextField.stringValue
												 forKey:@"ServerAddress"];
		
		[self updateSelectedContentTypeWithSender:self.ContentTypeMatrix.selectedCell];
	}
	[self updateGUI];
}

#pragma mark Notification

-(void)outlineViewDidChangeSelection:(NSNotification*)notif {
	[self updateSateLine];
}

#pragma mark Application LifeCycle

- (void)dealloc {
	[_rootContent release], _rootContent = nil;
	[_displayedContent release], _displayedContent = nil;
	[_itemKeyValueCache release], _itemKeyValueCache = nil;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	_displayedContent = [NSMutableDictionary new];
	_rootContent = [NSMutableArray new];
	_itemKeyValueCache = [NSMutableArray new];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:NO], @"ServerRequestHTTPS",
															 [NSNumber numberWithBool:NO], @"ServerRequestAuthentication",
															 [NSNumber numberWithInt:kContentTypeBPlist], @"ContentType",
															 @"alice", @"ServerLogin",
															 @"bob", @"ServerPassword",
															 @"1984", @"ServerTCPPort",
															 @"127.0.0.1", @"ServerAddress",
															 nil]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewDidChangeSelection:)
												 name:NSOutlineViewSelectionDidChangeNotification 
											   object:self.EntitiesOutlineView];
	
	[self updateGUI];
}

@end