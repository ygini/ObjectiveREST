//
//  RESTManager.m
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "RESTManager.h"

#import "HTTPServer.h"
#import "RESTConnection.h"
#import "RESTPrivateSettings.h"
#import "SBJsonParser.h"
#import "NSObject+SBJson.h"
#import "NSString_RESTAddition.h"

@implementation RESTManager

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize modelIsObjectiveRESTReady;
@synthesize requestHTTPS;
@synthesize allowDeleteOnCollection;
@synthesize requestAuthentication;
@synthesize useDigest;

@synthesize authenticationDatabase;

@synthesize tcpPort;

@synthesize mDNSType;
@synthesize mDNSName;
@synthesize mDNSDomain;

@synthesize isRunning;

#pragma mark - Aplication LifeCycle

+ (RESTManager*)sharedInstance {
	static RESTManager* sharedInstanceRESTManager = nil;
	if (!sharedInstanceRESTManager) sharedInstanceRESTManager = [RESTManager new];
	return sharedInstanceRESTManager;
}

-(id)init {
	self = [super init];
	if (self) {
		self.authenticationDatabase = [[NSMutableDictionary new] autorelease];
        self.tcpPort = 0;       // The system choose the port.
        self.mDNSDomain = @"";  // Use network default domain or local. if no domain is provied by DNS server.
        self.mDNSName = @"";    // Use computer name by default.
        self.mDNSType = @"_rest._tcp";  // We need to publish in mDNS to find service with automatic discovered port. Set to nil to hide service.
	}
	return self;
}

- (void)dealloc {
    self.authenticationDatabase = nil;
    [super dealloc];
}

#pragma mark - Server Commands

- (BOOL)startServer {
	if (_httpServer) [self stopServer];

	_httpServer = [HTTPServer new];
	[_httpServer setConnectionClass:[RESTConnection class]];
	[_httpServer setType:self.mDNSType];
	[_httpServer setName:self.mDNSName];
	[_httpServer setDomain:self.mDNSDomain];
	[_httpServer setPort:self.tcpPort];
	
	NSError *error = nil;
	
	if(![_httpServer start:&error]) {
		NSLog(@"Error starting HTTP Server: %@", error);
		[self stopServer];
		return NO;
	}
	
	return YES;
}

- (BOOL)stopServer {
	[_httpServer stop];
	[_httpServer release];
	_httpServer = nil;
	
	return YES;
}

-(BOOL)isRunning {
	return _httpServer != nil;
}

#pragma mark - CoreData Manipulations


+ (NSArray*)managedObjectWithEntityName:(NSString*)name {
	NSError *err = nil;
	
	NSFetchRequest * fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
	return [[[RESTManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&err] sortedArrayUsingComparator:^NSComparisonResult(NSManagedObject<RESTManagedObject>* obj1, NSManagedObject<RESTManagedObject>* obj2) {
		if ([obj1 respondsToSelector:@selector(compare:)])
			return [obj1 compare:obj2];
		return [[[[obj1 objectID] URIRepresentation] absoluteString] compare:[[[obj2 objectID] URIRepresentation] absoluteString]];
	}];
}

+ (NSManagedObject*)managedObjectWithEntityName:(NSString*)name andRESTUUID:(NSString*)rest_uuid {
	NSError *err = nil;
	
	NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:name];
	[req setPredicate:[NSPredicate predicateWithFormat:@"SELF.rest_uuid like %@", rest_uuid]];
	NSArray *answer = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:req error:&err];
	if ([answer count] > 0)
		return [answer objectAtIndex:0];
	else return nil;
}

+ (NSManagedObject*)managedObjectWithRelativePath:(NSString*)path {
	NSManagedObject *entry = nil;
	NSError *error = nil;
	NSMutableArray *pathComponents = [NSMutableArray new];
	NSArray *entities = [[[[[RESTManager sharedInstance].managedObjectModel entitiesByName] allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
	
	// Cleaning path for double /
	path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
	
	
	for (NSString *pathCompo in [path pathComponents]) {
		if (![pathCompo isEqualToString:@"/"]) {
			[pathComponents addObject:pathCompo];
		}
	}
	
	NSString *selectedEntity = [pathComponents objectAtIndex:0];
	
	if ([path rangeOfString:@"x-coredata"].location != NSNotFound) {
		// Update entity from CoreData URI
		NSString *coreDataUniqueID = [path stringByReplacingOccurrencesOfString:@"/x-coredata" withString:@"x-coredata:/"];
		
		entry =  [[RESTManager sharedInstance].managedObjectContext objectWithID:
			  [[RESTManager sharedInstance].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:coreDataUniqueID]]];
		
		if ([entry isFault]) {
			
			
			NSFetchRequest *validityRequest = [[NSFetchRequest alloc] init];
			[validityRequest setEntity:[entry entity]];
			
			[validityRequest setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] 
											 rightExpression:[NSExpression expressionForConstantValue:entry]
												modifier:NSDirectPredicateModifier
												    type:NSEqualToPredicateOperatorType 
												 options:0]];
			
			NSArray *results = [[RESTManager sharedInstance].managedObjectContext executeFetchRequest:validityRequest error:&error];
			[validityRequest release];
			
			if ([results count] > 0) {   
				entry = [results objectAtIndex:0];
			}
		}							
	} else if ([entities indexOfObject:selectedEntity] != NSNotFound) {
		// Update entity from REST UUID
		entry = [self managedObjectWithEntityName:[pathComponents objectAtIndex:0] andRESTUUID:[pathComponents objectAtIndex:1]];
	}
	
    [pathComponents release];
    [entities release];
	return entry;
}

+ (NSManagedObject*)managedObjectWithAbsolutePath:(NSString*)path {
	return [self managedObjectWithRelativePath:[[NSURL URLWithString:path] relativePath]];
}

+ (void)updateManagedObject:(NSManagedObject*)object withInfo:(NSDictionary*)infos {
	id value = nil;
	NSError *error = nil;
	for (NSString *supportedKey in [[[object entity] attributesByName] allKeys]) {
		value = [infos valueForKey:supportedKey];
		if (value) [object setValue:value forKey:supportedKey];
	}
	
	NSRelationshipDescription *relation = nil;
	for (NSString *supportedKey in [[[object entity] relationshipsByName] allKeys]) {
		if (value) {
			value = [infos valueForKey:supportedKey];
			relation = [[[object entity] relationshipsByName] valueForKey:supportedKey];
			
			if ([relation isToMany]) {
				NSSet *representedSet = value;
				
				NSMutableSet *uptodateSet = [NSMutableSet setWithCapacity:[representedSet count]];
				
				for (NSDictionary *relationInfo in representedSet) {
					[uptodateSet addObject:[self managedObjectWithAbsolutePath:[relationInfo valueForKey:REST_REF_KEYWORD]]];
				}
				
				[object willChangeValueForKey:supportedKey];
				[object setPrimitiveValue:uptodateSet forKey:supportedKey];
				[object didChangeValueForKey:supportedKey];
				
			} else [object setValue:[self managedObjectWithAbsolutePath:[value valueForKey:REST_REF_KEYWORD]] forKey:supportedKey];
		}
	}
	
	[[RESTManager sharedInstance].managedObjectContext save:&error];
}


+ (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict withContentType:(NSString*)ContentType {
	NSString *errorString = nil;
	
	if ([ContentType isEqualToString:@"application/x-bplist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	else if ([ContentType isEqualToString:@"application/x-plist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	else if ([ContentType isEqualToString:@"application/json"]) 
		return [[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
	else
		return nil;
}

+ (NSDictionary*)dictionaryFromResponse:(NSData*)response withContentType:(NSString*)ContentType {
	NSDictionary *dict = nil;
	NSString *errString = nil;
	if ([ContentType isEqualToString:@"application/x-bplist"] || [ContentType isEqualToString:@"application/x-plist"]) 
		dict = [NSPropertyListSerialization propertyListFromData:response
							mutabilityOption:NSPropertyListMutableContainersAndLeaves
								  format:nil
							errorDescription:&errString];
	
	else if ([ContentType isEqualToString:@"application/json"]) {
		SBJsonParser *parser = [SBJsonParser new];
		dict = [parser objectWithData:response];
		[parser release];
	}
	
	return dict;
}

+ (NSString*)baseURLForURIWithServerAddress:(NSString*)serverAddress {
    return [NSString stringWithFormat:@"%@://%@", [self sharedInstance].requestHTTPS ? @"https" : @"http" , serverAddress];
}

+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forEntityWithName:(NSString*)name {
    return [NSString stringWithFormat:@"%@/%@", [self baseURLForURIWithServerAddress:serverAddress], name];
}

+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object {
    return [self restURIWithServerAddress:serverAddress forManagedObject:object onRESTReadyObjectModel:[RESTManager sharedInstance].modelIsObjectiveRESTReady];
}

+ (NSString*)restURIWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object onRESTReadyObjectModel:(BOOL)RESTReady {
	NSError *error = nil;
	if (RESTReady) {
		// If the data model has been patched, we use dedicated UUID to make URI
		return [NSString stringWithFormat:@"%@/%@/%@", [self baseURLForURIWithServerAddress:serverAddress], [[object entity] name], [object rest_uuid]];
	} else {
		// If the data model isn't patched to be compatible with ObjectiveREST, we fall back on CoreData ID…
		if ([[object objectID] isTemporaryID]) {
			[[RESTManager sharedInstance].managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:object] error:&error];
		}
        
		return [NSString stringWithFormat:@"%@/%@", [self baseURLForURIWithServerAddress:serverAddress], [[[[object objectID] URIRepresentation] absoluteString] stringByReplacingOccurrencesOfString:@"x-coredata:/" withString:@"x-coredata"]];
	}
}

+ (NSDictionary*)restLinkRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject<RESTManagedObject>*)object {
	return [NSDictionary dictionaryWithObject:[self restURIWithServerAddress:serverAddress 
								forManagedObject:object] 
					   forKey:REST_REF_KEYWORD];
}

+ (NSManagedObject<RESTManagedObject>*)insertNewObjectForEntityForName:(NSString*)entityString {
	return [NSEntityDescription insertNewObjectForEntityForName:entityString inManagedObjectContext:[[RESTManager sharedInstance] managedObjectContext]];
}

#pragma mark - Data Conversion

+ (NSDictionary *)dictionaryRepresentationWithServerAddress:(NSString*)serverAddress forManagedObject:(NSManagedObject *)object 
{
	NSArray *attributes = [[[object entity] attributesByName] allKeys];
	NSArray *relationships = [[[object entity] relationshipsByName] allKeys];
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:[attributes count]  + [relationships count]];
	
	for (NSString *attribute in attributes) {
		NSObject *v = [object valueForKey:attribute];
		
		if (v != nil)
			[d setObject:v forKey:attribute];
	}
	
	for (NSString *relationship in relationships) {
		NSObject *value = [object valueForKey:relationship];
		
		if ([value isKindOfClass:[NSSet class]]) { // To-many
			NSSet *objects = (NSSet *)value;
			
			NSMutableSet *objectsSet = [NSMutableSet setWithCapacity:[objects count]];
			
			for (NSManagedObject *relation in objects)
				[objectsSet addObject:[self restLinkRepresentationWithServerAddress:serverAddress 
										   forManagedObject:(NSManagedObject<RESTManagedObject>*)relation]];
			
			[d setObject:objectsSet forKey:relationship];
		}
		else if ([value isKindOfClass:[NSManagedObject class]]) { // To-one
			NSManagedObject *o = (NSManagedObject *)value;
			
			[d setObject:[self restLinkRepresentationWithServerAddress:serverAddress 
								  forManagedObject:(NSManagedObject<RESTManagedObject>*)o] forKey:relationship];
		}
	}
	
	return d;
}


@end
