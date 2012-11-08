//
//  ORConstants.h
//  OSX-ObjectiveREST
//
//  Created by Yoann Gini on 08/11/12.
//  Copyright (c) 2012 iNig-Services. All rights reserved.
//

#define OR_NO_CACHE_STORE						@"OR_NO_CACHE_STORE"

#define OR_SUPPORTED_CONTENT_TYPE				[NSArray arrayWithObjects:@"application/x-bplist", @"application/x-plist", @"application/json", nil]

#define	ORErrorDomain							@"ORErrorDomain"

typedef enum {
	ORErrorDomainCode_SERVER_UNAVIABLE,
	ORErrorDomainCode_Unsupported_NSFetchRequestResultType,
	ORErrorDomainCode_Unsupported_NSFetchRequestType
}
ORErrorDomainCode;

#define OR_KEY_REF_REST							@"rest_ref"
#define OR_KEY_WS_URL							@"ws_url"
#define OR_KEY_METADATA							@"metadata"
#define OR_KEY_CONTENT							@"content"

#define OR_WS_PREFIX_INSERTED					@"INSERTED: "
#define OR_WS_PREFIX_UPDATED					@"UPDATED: "
#define OR_WS_PREFIX_DELETED					@"DELETED: "