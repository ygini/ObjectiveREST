//
//  IPDataProvider.h
//  iPlayer
//
//  Created by Yoann Gini on 31/01/10.
//  Copyright 2010 iNig-Services. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ObjectiveREST/ObjectiveREST.h>

#import "IPMusic.h"
#import "IPAlbum.h"
#import "IPArtist.h"
#import "IPMusicData.h"

@class NSManagedObjectContext, NSManagedObjectModel, NSPersistentStoreCoordinator;

@interface IPDataProvider : NSObject <ORServerDataProvider> {
	NSManagedObjectContext		*ipdp_moc;
	NSManagedObjectModel		*ipdp_mom;
	NSPersistentStoreCoordinator	*ipdp_storeCoordinator;
	
	NSString			*ipdb_dataFolder;
    
    ORServer *ipdb_server;
}

@property (readonly) NSManagedObjectContext *managedObjectContext;

+(IPDataProvider*)sharedInstance;

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;
- (IBAction) saveAction:(id)sender;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

- (NSManagedObject*)createIPMusicWithPath:(NSString*)path;

@end
