//
//  IPArtist.h
//  iPlayer
//
//  Created by Yoann Gini on 05/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface IPArtist : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *albums;
@end

@interface IPArtist (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(NSManagedObject *)value;
- (void)removeAlbumsObject:(NSManagedObject *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
