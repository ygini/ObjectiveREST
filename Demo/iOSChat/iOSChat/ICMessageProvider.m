//
//  ICMessageProvider.m
//  iOSChat
//
//  Created by Yoann Gini on 30/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "ICMessageProvider.h"

#import "ICAppDelegate.h"

#import <ObjectiveREST.h>

@implementation ICMessageProvider

@synthesize isServer;
@synthesize serverName;
@synthesize nickName;

@dynamic remoteService;
@dynamic messages;

+ (ICMessageProvider*)sharedInstance {
    static ICMessageProvider* sharedInstanceICMessageProvider = nil;
    if (!sharedInstanceICMessageProvider) sharedInstanceICMessageProvider = [ICMessageProvider new];
    return sharedInstanceICMessageProvider;
}

- (id)init {
    self = [super init];
    if (self) {
        self.serverName = [[NSUserDefaults standardUserDefaults] valueForKey:@"servername"];
        self.nickName = [[NSUserDefaults standardUserDefaults] valueForKey:@"nickname"];
    }
    return self;
}

-(void)setRemoteService:(NSNetService *)remoteService {
    if (_remoteService != remoteService) {
        _remoteService = remoteService;
        
        self.isServer = NO;
        
        [RESTClient sharedInstance].tcpPort = [_remoteService port];
        [RESTClient sharedInstance].serverAddress = [_remoteService hostName];
        [RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
        [RESTClient sharedInstance].contentType = REST_SUPPORTED_CONTENT_TYPE;
        
        if (!remoteService) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kICMessageProviderServerUnaviable
                                                                object:self];
        }
    }
}

-(NSNetService *)remoteService {
    return _remoteService;
}

- (NSArray*)messages {
    if (self.isServer) {
        NSError * err = nil;
        NSFetchRequest *fetchReq = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
        
        return [[ICAppDelegate sharedInstance].managedObjectContext executeFetchRequest:fetchReq
                                                                                  error:&err];
    } else {
        NSArray * restLinks = [[[RESTClient sharedInstance] getPath:@"/Message"] valueForKey:@"content"];
        NSMutableArray * newMessages = [NSMutableArray new];
        
        NSDictionary *message = nil;
        for (NSDictionary *link in restLinks) {
            message = [[[RESTClient sharedInstance] getAbsolutePath:[link valueForKey:REST_REF_KEYWORD]] valueForKey:@"content"];
            [newMessages addObject:message];
        }
        
        return [newMessages autorelease];
    }
    
    return nil;
}

- (void)sendMessage:(NSString*)aMessage {
    if (self.isServer) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Message" 
                                                                inManagedObjectContext:[ICAppDelegate sharedInstance].managedObjectContext];
        
        [object setValue:aMessage forKey:@"message"];
        [object setValue:[NSDate date] forKey:@"date"];
        [object setValue:self.nickName forKey:@"nickname"];
    } else {
        if (self.remoteService) {
            NSMutableDictionary *object = [NSMutableDictionary new];
            
            [object setValue:aMessage forKey:@"message"];
            [object setValue:[NSDate date] forKey:@"date"];
            [object setValue:self.nickName forKey:@"nickname"];
            
            [[RESTClient sharedInstance] postInfo:[NSDictionary dictionaryWithObject:object forKey:@"content"] 
                                           toPath:@"/Message"];
            [object release];
        }
    }
}


- (void)startServer {
    self.isServer = YES;
    
    [RESTManager sharedInstance].mDNSName = self.serverName;
    [RESTManager sharedInstance].mDNSType =  IOSCHAT_M_DNS_TYPE;
    
    [RESTManager sharedInstance].managedObjectModel = [ICAppDelegate sharedInstance].managedObjectModel;
    [RESTManager sharedInstance].managedObjectContext = [ICAppDelegate sharedInstance].managedObjectContext;
    [RESTManager sharedInstance].persistentStoreCoordinator = [ICAppDelegate sharedInstance].persistentStoreCoordinator;
    
    [[RESTManager sharedInstance] startServer];
}

- (void)stopServer {
    [[RESTManager sharedInstance] stopServer];
    self.isServer = NO;
}

@end
