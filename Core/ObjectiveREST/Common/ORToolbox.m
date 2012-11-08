//
//  ORToolbox.m
//  iPlayer Client
//
//  Created by Yoann Gini on 06/05/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#import "ORToolbox.h"

#import "ORConstants.h"

@implementation ORToolbox
@synthesize serverURL = _serverURL, negociatedContentType = _negociatedContentType;

+ (ORToolbox*)sharedInstance {
    static ORToolbox* sharedInstanceORToolbox = nil;
    if (!sharedInstanceORToolbox) sharedInstanceORToolbox = [ORToolbox new];
    return sharedInstanceORToolbox;
}

+ (ORToolbox*)sharedInstanceForPersistentStore:(NSIncrementalStore*)store {
    static NSMutableDictionary* sharedInstanceORToolboxList = nil;
    if (!sharedInstanceORToolboxList) sharedInstanceORToolboxList = [NSMutableDictionary new];
    
    ORToolbox *instance = [sharedInstanceORToolboxList valueForKey:[store identifier]];
    
    if (!instance) {
        instance = [[ORToolbox new] autorelease];
        instance->_associatedStore = store;
        [sharedInstanceORToolboxList setValue:instance forKey:[store identifier]];
    }
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _acceptedContentType = [OR_SUPPORTED_CONTENT_TYPE retain];
    }
    return self;
}

- (void)dealloc {
    [_acceptedContentType release];
    [super dealloc];
}

#pragma mark - Routines

- (NSString*)acceptedContentType {
    NSMutableString *str = [NSMutableString new];
    NSInteger i = [_acceptedContentType count];
    for (NSInteger j = 0; j < i; j++) {
        [str appendString:[_acceptedContentType objectAtIndex:j]];
        if (j < i - 1) [str appendString:@","];
    }
    
    return [str autorelease];
}

-(NSString *)negociatedContentType {
    if ([_negociatedContentType length] > 0) {
        return _negociatedContentType;
    }
    
    return [_acceptedContentType objectAtIndex:0];
}

- (NSString*)absoluteVersionForPath:(NSString*)path {
    return [[_serverURL URLByAppendingPathComponent:path] absoluteString];
}

- (NSMutableURLRequest*)baseRequestForPath:(NSString*)path {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
	
    [req setValue:[self acceptedContentType] forHTTPHeaderField:@"Accept"];
    
	
	[req setValue:[NSString stringWithFormat:@"%@:%@", [_serverURL host], [_serverURL port]] forHTTPHeaderField:@"Host"];
    
	/*if (self.requestAuthentication) {
     if(self.useDigest) {
     
     } else {
     [req setValue:[NSString stringWithFormat:@"Basic %@", 
     [[NSString stringWithFormat:@"%@:%@",
     self.username,
     self.password]
     RESTbase64EncodedString]]
     forHTTPHeaderField:@"Authorization"];
     }
     }*/
    
    return req;
}

#pragma mark REST Client

- (NSDictionary*)postInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
    
	[req setHTTPMethod:@"POST"];
	
    NSData *body = [self preparedResponseFromDictionary:info];
    
	[req setHTTPBody:body];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
    [req setValue:[[NSNumber numberWithUnsignedInteger:[body length]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSDictionary*)postInfo:(NSDictionary*)info toPath:(NSString*)path {
    return [self postInfo:info toAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSDictionary*)putInfo:(NSDictionary*)info toAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"PUT"];
	
    NSData *body = [self preparedResponseFromDictionary:info];
    
	[req setHTTPBody:body];
    
    [req setValue:[self negociatedContentType] forHTTPHeaderField:@"Content-Type"];
    [req setValue:[[NSNumber numberWithUnsignedInteger:[body length]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
	
	NSMutableDictionary *dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSDictionary*)putInfo:(NSDictionary*)info toPath:(NSString*)path {
    return [self putInfo:info toAbsolutePath:[self absoluteVersionForPath:path]];
}

- (void)deleteAbsolutePath:(NSString*)path {
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	
	[req setHTTPMethod:@"DELETE"];
	
	NSURLResponse *rep = nil;
	NSError *err = nil;
	
	[NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
}

- (void)deletePath:(NSString*)path {
    [self deleteAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path {
	return [self getAbsolutePath:path withHTTPHeader:nil];
}

- (NSMutableDictionary*)getAbsolutePath:(NSString*)path withHTTPHeader:(NSDictionary*)headers {
	NSMutableDictionary *dict = nil;
	NSMutableURLRequest *req = [self baseRequestForPath:path];
	for (NSString *key in headers) {
		[req setValue:[headers valueForKey:key] forHTTPHeaderField:key];
	}
    
    [req setHTTPMethod:@"GET"];

    NSHTTPURLResponse *rep = nil;
    NSError *err = nil;
    
    NSData * answer = [NSURLConnection sendSynchronousRequest:req returningResponse:&rep error:&err];
    self.negociatedContentType = [[rep allHeaderFields] valueForKey:@"content-type"];
    
    dict = [[self dictionaryFromResponse:answer] mutableCopy];
    
	return [dict autorelease];
}

- (NSMutableDictionary*)getPath:(NSString*)path {
	return [self getAbsolutePath:[self absoluteVersionForPath:path]];
}

- (NSArray*)getAllObjectOfThisEntityKind:(NSString*)path {
	if ([path rangeOfString:@"x-coredata"].location == NSNotFound) {
		// REST Ready database
		return [[self getAbsolutePath:[path stringByDeletingLastPathComponent]] valueForKey:@"content"];
	} else {
		// Standard database
		NSArray *compo = [path pathComponents];
        
		return [[self getPath:[NSString stringWithFormat:@"/%@", [compo objectAtIndex:[compo count] -2]]] valueForKey:@"content"];
	}
	return nil;
}

- (NSArray*)getObjectsForFetchRequest:(NSFetchRequest*)request {
	NSDictionary *headers = nil;
	if ([request.predicate predicateFormat]) {
		headers = [NSDictionary dictionaryWithObject:[request.predicate predicateFormat]
											  forKey:@"NSPredicate"];
	}
	return [[self getAbsolutePath:[self absoluteVersionForPath:request.entityName]
				   withHTTPHeader:headers]
			valueForKey:@"content"];
}

#pragma mark - NSDictionary for REST

- (NSData*)preparedResponseFromDictionary:(NSDictionary*)dict {
	NSString *errorString = nil;
	
	if ([[self negociatedContentType] isEqualToString:@"application/x-bplist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	else if ([[self negociatedContentType] isEqualToString:@"application/x-plist"]) 
		return [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	else if ([[self negociatedContentType] isEqualToString:@"application/json"]) 
        return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
	else
		return nil;
}

- (NSDictionary*)dictionaryFromResponse:(NSData*)response {
	NSDictionary *dict = nil;
	NSString *errString = nil;
	if ([[self negociatedContentType] isEqualToString:@"application/x-bplist"] || [[self negociatedContentType] isEqualToString:@"application/x-plist"]) 
		dict = [NSPropertyListSerialization propertyListFromData:response
                                                mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                          format:nil
                                                errorDescription:&errString];
	
	else if ([[self negociatedContentType] isEqualToString:@"application/json"]) {
        dict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
	}
	
	return dict;
}

#pragma mark - NSManagedObject / NSDictionary

- (NSMutableDictionary*)dictionaryFromManagedObject:(NSManagedObject*)object {
    
    NSManagedObjectID *objectID = object.objectID;
    NSEntityDescription *entityDescription = objectID.entity;
    
    NSDictionary *relationList = [entityDescription relationshipsByName];
    NSDictionary *attributeList = [entityDescription attributesByName];
    
    NSRelationshipDescription *relation = nil;
    NSSet *relations;
    NSMutableArray *relationsLink;
    NSManagedObject *relationObject = nil;
    NSString *referenceID;
    
    id value;
    
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionaryWithCapacity:[attributeList count]  + [relationList count]];
    
    for (NSString *relationName in [relationList allKeys]) {
        relation = [relationList valueForKey:relationName];
        
        if ([relation isToMany]) {
            relations = [object valueForKey:relationName];
            relationsLink = [NSMutableArray arrayWithCapacity:[relations count]];
            for (relationObject in relations) {
                referenceID = [_associatedStore referenceObjectForObjectID:relationObject.objectID];
                [relationsLink addObject:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD]];
            }
            [returnDict setValue:relationsLink forKey:relationName];
        } else {
            relationObject = [object valueForKey:relationName];
            referenceID = [_associatedStore referenceObjectForObjectID:relationObject.objectID];
            [returnDict setValue:[NSDictionary dictionaryWithObject:referenceID forKey:OR_REF_KEYWORD] forKey:relationName];
        }
    }
    
    for (NSString *attribute in [attributeList allKeys]) {
		value = [object valueForKey:attribute];
		if (value)
			[returnDict setObject:value forKey:attribute];
	}
    
    return returnDict;
}

@end
