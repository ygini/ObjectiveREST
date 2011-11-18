//
//  ORAppDelegate.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ORAppDelegate.h"
#import "NSString_Addition.h"
#import "SBJsonParser.h"
#import "OROutlineKeyValueItem.h"

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


#define	REST_REF_KEYWORD					@"rest_ref"


#pragma mark GUI

- (void)updateGUI{
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
				id info = [[self getPath:[[NSURL URLWithString:rest_ref] relativePath]] valueForKey:@"content"];
				
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
				// We are on a dict representing a referenced
				id info = [[self getPath:[[NSURL URLWithString:rest_ref] relativePath]] valueForKey:@"content"];
				
				if ([info isKindOfClass:[NSDictionary class]]) {
					// The referenced object is a object
					returnValue =  [OROutlineKeyValueItem itemWithKey:[[info allKeys] objectAtIndex:index] andValue:[info valueForKey:[[info allKeys] objectAtIndex:index]]];
					[_itemKeyValueCache addObject:returnValue];
				} else if ([info isKindOfClass:[NSArray class]]) {
					// The referenced object is a collection
					returnValue =  [((NSArray*)info) objectAtIndex:index];
				}
			} else {
				// We shouldn't be here…
				NSLog(@"Eww, what are you doing here?");
				returnValue =  [OROutlineKeyValueItem itemWithKey:[[((NSDictionary*)item) allKeys] objectAtIndex:index] 
												 andValue:[((NSDictionary*)item) valueForKey:[[((NSDictionary*)item) allKeys] objectAtIndex:index]]];
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
			return @"Unmanaged 1";
		}
	} else if ([item isKindOfClass:[OROutlineKeyValueItem class]]) {
		return [item valueForKey:[tableColumn identifier]];
	} else {
		return @"Unmanaged 2";
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
	[_displayedContent removeAllObjects];
	[_rootContent removeAllObjects];
	[_itemKeyValueCache removeAllObjects];
	
	[_rootContent addObjectsFromArray:[[self getPath:@"/"] valueForKey:@"content"]];
	
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

- (NSMutableDictionary*)getPath:(NSString*)path {
	
	NSMutableDictionary *dict = [_displayedContent valueForKey:path];
	if (!dict) {
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/%@", 
																							 [[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestHTTPS"] ? @"https" : @"http",
																							 [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerAddress"],
																							 [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerTCPPort"],
																							 path]]];
		
		[req setValue:[self selectedContentType] forHTTPHeaderField:@"Accept"];
		
		[req setValue:[NSString stringWithFormat:@"%@:%@",
					   [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerAddress"],
					   [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerTCPPort"]] 
   forHTTPHeaderField:@"Host"];
		
		[req setHTTPMethod:@"GET"];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ServerRequestAuthentication"]) {
			// Only Basic authentication here, Digest need async connection, so maybe latter for this demo…
			[req setValue:[NSString stringWithFormat:@"Basic %@", 
						   [[NSString stringWithFormat:@"%@:%@",
							 [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerLogin"],
							 [[NSUserDefaults standardUserDefaults] stringForKey:@"ServerPassword"] ]
							base64EncodedString]]
	   forHTTPHeaderField:@"Authorization"];
		}
		
		NSURLResponse *rep = nil;
		NSError *err = nil;
		NSString *errString = nil;
		
		NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
		
		switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"ContentType"]) {
			case kContentTypeBPlist:
			case kContentTypePlist:
				dict = [NSPropertyListSerialization propertyListFromData:answer
														mutabilityOption:NSPropertyListMutableContainersAndLeaves
																  format:nil
														errorDescription:&errString];
				break;
			case kContentTypeJSON: {
				SBJsonParser *parser = [SBJsonParser new];
				dict = [parser objectWithData:answer];
				[parser release];
			}
				break;
		}
		
		[_displayedContent setValue:dict forKey:path];
	}
		
	return dict;
}

#pragma mark Actions

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
		
		[self updateSelectedContentTypeWithSender:self.ContentTypeMatrix.selectedCell];
	}
	[self updateGUI];
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
	
	
	[self updateGUI];
}

@end
