//
//  IPMusicData.h
//  iPlayer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IPMusic;

@interface IPMusicData : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) IPMusic *music;

@end
