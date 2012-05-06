//
//  IPAlbum.h
//  iPlayer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IPArtist, IPMusic;

@interface IPAlbum : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) IPArtist *artist;
@property (nonatomic, retain) NSSet *musics;

@end
