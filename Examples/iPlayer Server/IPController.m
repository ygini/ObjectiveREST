//
//  IPController.m
//  iPlayer
//
//  Created by Yoann Gini on 30/01/10.
//  Copyright 2010 iNig-Services. All rights reserved.
//

#import "IPController.h"

#import "IPDataProvider.h"


@interface IPController (Private)
-(void) ipc_setCurrentMusic:(IPMusic*)music;
-(void) ipc_playMusicAtIndex:(NSUInteger)index;
-(void) ipc_playMusic:(IPMusic*)music;
@end


@implementation IPController

@synthesize curentMusic = _curentMusic;
@synthesize playlistPanelIsVisible = _playlistPanelIsVisible;
@dynamic dataProvider;

- (IPDataProvider *) dataProvider {
	return [IPDataProvider sharedInstance];
}

// MARK: Action
-(IBAction)playPause:(id)sender {
	
	if (sender == tableView) [self stop:self];
	
	if (_soundPlayer && !_isSuspended) {
		[_soundPlayer pause];
		_isSuspended = YES;
	} else if (_soundPlayer && _isSuspended) {
		[_soundPlayer resume];
		_isSuspended = NO;
	} else {
		if ([[playList arrangedObjects] count] == 0) return;
		
		NSUInteger index = [playList selectionIndex];
		if (index == NSNotFound) index = 0;
		
		[self ipc_playMusicAtIndex:index];
	}
}

-(IBAction)stop:(id)sender {
	if (!_soundPlayer) return;
	
	[_soundPlayer stop];
	[_soundPlayer release];
	_soundPlayer = nil;
	
	_isSuspended = NO;
	
	[self ipc_setCurrentMusic:nil];
}


-(IBAction)nextTrack:(id)sender {
	if (!_soundPlayer) return;
	
	[self stop:self];
	
	NSInteger index = _currentIndex + 1;
	
	if (index >= [[playList arrangedObjects] count]) index = 0;
	
	[self ipc_playMusicAtIndex:index];
}

-(IBAction)previousTrack:(id)sender {
	if (!_soundPlayer) return;
	
	[self stop:self];
	
	NSInteger index = _currentIndex - 1;
	
	if (index < 0) index = [[playList arrangedObjects] count]-1;
	
	[self ipc_playMusicAtIndex:index];;
}


-(IBAction)fastForward:(id)sender {
	
}

-(IBAction)rapidReverse:(id)sender {
	
}

-(IBAction)open:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"mp3",nil]];
	[openPanel setDelegate:self];
	[openPanel setDirectoryURL:[NSURL URLWithString:[@"~/Music" stringByExpandingTildeInPath]]];
	
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            for (NSURL *fileURL in [openPanel URLs]) [[IPDataProvider sharedInstance] createIPMusicWithPath:[fileURL path]];
        }
    }];
}

-(IBAction)togglePlayList:(id)sender {
	[panel setIsVisible:![panel isVisible]];
}

- (IBAction)searchDidChange:(NSTextField*)sender {
	NSString *searchString = [sender stringValue];
	
	if ([searchString length] > 0) {
		[playList setFilterPredicate:[NSPredicate predicateWithFormat:@"(title contains[cd] %@) OR (album.title contains[cd] %@) OR (album.artist.name contains[cd] %@)", searchString, searchString, searchString]];
	} else {
		[playList setFilterPredicate:nil];
	}
}

- (IBAction)saveDataStore:(id)sender {
    [[IPDataProvider sharedInstance] saveAction:sender];
}

// MARK: Initialize

- (void) awakeFromNib {
	_soundPlayer = nil;
	_curentMusic = nil;
	
	_isSuspended = NO;
	
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(playPause:)];
}

- (void) dealloc
{
	[super dealloc];
}

// MARK: Private

-(void) ipc_setCurrentMusic:(IPMusic*)music {
	if (music != _curentMusic) {
		[self willChangeValueForKey:@"curentMusic"];
		[_curentMusic setIsPlayed:NO];
		id old = _curentMusic;
		_curentMusic = [music retain];
		[old release];
		[_curentMusic setIsPlayed:YES];
		[self didChangeValueForKey:@"curentMusic"];
	}
}

-(void) ipc_playMusicAtIndex:(NSUInteger)index {
	_currentIndex = index;
	[self ipc_playMusic:[[playList arrangedObjects] objectAtIndex:index]];
}

-(void) ipc_playMusic:(IPMusic*)music {
	[self ipc_setCurrentMusic:music];
	
    _soundPlayer = [[NSSound alloc] initWithData:_curentMusic.data.data];
	[_soundPlayer play];
	_isSuspended = NO;
}

// MARK: ApplicationDelegate

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
	return [[IPDataProvider sharedInstance] applicationShouldTerminate:sender];
}

@end
