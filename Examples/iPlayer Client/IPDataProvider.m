//
//  IPDataProvider.m
//  iPlayer
//
//  Created by Yoann Gini on 31/01/10.
//  Copyright 2010 iNig-Services. All rights reserved.
//

#import "IPDataProvider.h"

#import <CoreData/CoreData.h>
#import <ID3/TagAPI.h>

#import "ORNoCacheStore.h"

@implementation IPDataProvider

@synthesize managedObjectContext = ipdp_moc;

+(IPDataProvider*)sharedInstance {
	static IPDataProvider *sharedInstanceIPDataProvider = nil;
	if (!sharedInstanceIPDataProvider) sharedInstanceIPDataProvider =[[IPDataProvider alloc] init];
	return sharedInstanceIPDataProvider;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		ipdb_serverURL = [NSURL URLWithString:@"http://127.0.0.1:1988/OR-API"];
		
		ipdp_mom = nil;  
		ipdp_moc = nil;
		ipdp_storeCoordinator = nil;
	}
	return self;
}

- (NSManagedObject*)createIPMusicWithPath:(NSString*)path {
	IPMusic *music = [NSEntityDescription insertNewObjectForEntityForName:@"IPMusic" inManagedObjectContext:ipdp_moc];
	
	TagAPI *tag = [[TagAPI alloc] initWithPath:path genreDictionary:nil];
	
	if ([tag tagFound]) {
        NSFetchRequest *request = nil;
        NSArray *result = nil;
        
        NSString *artistName = [tag getArtist];
        NSString *albumName = [tag getAlbum];
        NSString *musicName = [tag getTitle];
        
        if ([musicName length] == 0) {
            musicName = [path lastPathComponent];
        }
        
		[music setValue:musicName forKey:@"title"];
        
        
        NSData *rawMusic = [NSData dataWithContentsOfFile:path];
        IPMusicData *musicData = [NSEntityDescription insertNewObjectForEntityForName:@"IPMusicData" inManagedObjectContext:ipdp_moc];
        musicData.data = rawMusic;
        music.data = musicData;

        
        IPArtist *artist = nil;
        IPAlbum *album = nil;
        
        if ([artistName length] > 0) {
            request = [NSFetchRequest fetchRequestWithEntityName:@"IPArtist"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"name like %@", artistName]];
            result = [ipdp_moc executeFetchRequest:request error:nil];
            
            if ([result count] > 0) {
                artist = [result objectAtIndex:0];
            } else {
                artist = [NSEntityDescription insertNewObjectForEntityForName:@"IPArtist" inManagedObjectContext:ipdp_moc];
                artist.name = artistName;
            }
        }
        
        if ([albumName length] > 0) {
            request = [NSFetchRequest fetchRequestWithEntityName:@"IPAlbum"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(title like %@) AND (SELF in %@)", albumName, artist.albums]];
            result = [ipdp_moc executeFetchRequest:request error:nil];
            
            if ([result count] > 0) {
                album = [result objectAtIndex:0];
            } else {
                album = [NSEntityDescription insertNewObjectForEntityForName:@"IPAlbum" inManagedObjectContext:ipdp_moc];
                album.title = albumName;
                album.artist = artist;
            }
            
            [music setValue:album forKey:@"album"];
        }
        
        NSArray *images = [tag getImage];
        if ([images count] > 0) {
            NSBitmapImageRep *bitmapRep = [[images objectAtIndex:0] valueForKey:@"Image"];
            music.cover = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
        }
        
	}
	[tag release];
	return music;
}


// MARK: Generated Methods

- (NSManagedObjectModel *)managedObjectModel {
	if (!ipdp_mom) ipdp_mom = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
	return ipdp_mom;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
	if (ipdp_storeCoordinator) return ipdp_storeCoordinator;
	
	NSManagedObjectModel *mom = [self managedObjectModel];
	if (!mom) {
		NSAssert(NO, @"Managed object model is nil");
		return nil;
	}
	
	NSError *error = nil;

	ipdp_storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
	if (![ipdp_storeCoordinator addPersistentStoreWithType:OR_NO_CACHE_STORE 
							  configuration:nil 
								    URL:ipdb_serverURL 
								options:nil 
								  error:&error]){
        
		[[NSApplication sharedApplication] presentError:error];
		[ipdp_storeCoordinator release], ipdp_storeCoordinator = nil;
		return nil;
	}    
	
	return ipdp_storeCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext {
	
	if (ipdp_moc) return ipdp_moc;
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (!coordinator) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
		[dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
		NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
		[[NSApplication sharedApplication] presentError:error];
		return nil;
	}
	ipdp_moc = [[NSManagedObjectContext alloc] init];
	[ipdp_moc setPersistentStoreCoordinator: coordinator];
	
	return ipdp_moc;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
	return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender {
	
	NSError *error = nil;
	
	if (![[self managedObjectContext] commitEditing]) {
	}
	
	if (![[self managedObjectContext] save:&error]) {
		[[NSApplication sharedApplication] presentError:error];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
	if (!ipdp_moc) return NSTerminateNow;
	
	if (![ipdp_moc commitEditing]) {
		return NSTerminateCancel;
	}
	
	if (![ipdp_moc hasChanges]) return NSTerminateNow;
	
	NSError *error = nil;
	if (![ipdp_moc save:&error]) {
                
		BOOL result = [sender presentError:error];
		if (result) return NSTerminateCancel;
		
		NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
		NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
		NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
		NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:question];
		[alert setInformativeText:info];
		[alert addButtonWithTitle:quitButton];
		[alert addButtonWithTitle:cancelButton];
		
		NSInteger answer = [alert runModal];
		[alert release];
		alert = nil;
		
		if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
	}
	
	return NSTerminateNow;
}

@end
