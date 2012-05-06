//
//  IPMusic.h
//  iPlayer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IPAlbum, IPMusicData;

@interface IPMusic : NSManagedObject

@property (nonatomic) BOOL isPlayed;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) IPAlbum *album;
@property (nonatomic, retain) IPMusicData *data;
@property (nonatomic, retain) NSData * cover;

@end
