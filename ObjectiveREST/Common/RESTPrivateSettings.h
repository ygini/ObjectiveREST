//
//  RESTPrivateSettings.h
//  ObjectiveREST
//
//  Created by Yoann Gini on 28/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#ifndef ObjectiveREST_RESTPrivateSettings_h
#define ObjectiveREST_RESTPrivateSettings_h
#import "HTTPLogging.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

// Define chunk size used to read in data for responses
// This is how much data will be read from disk into RAM at a time
#if TARGET_OS_IPHONE
#define READ_CHUNKSIZE  (1024 * 128)
#else
#define READ_CHUNKSIZE  (1024 * 512)
#endif

// Define chunk size used to read in POST upload data
#if TARGET_OS_IPHONE
#define POST_CHUNKSIZE  (1024 * 32)
#else
#define POST_CHUNKSIZE  (1024 * 128)
#endif

// Define the various timeouts (in seconds) for various parts of the HTTP process
#define TIMEOUT_READ_FIRST_HEADER_LINE       30
#define TIMEOUT_READ_SUBSEQUENT_HEADER_LINE  30
#define TIMEOUT_READ_BODY                    -1
#define TIMEOUT_WRITE_HEAD                   30
#define TIMEOUT_WRITE_BODY                   -1
#define TIMEOUT_WRITE_ERROR                  30
#define TIMEOUT_NONCE                       300

// Define the various limits
// MAX_HEADER_LINE_LENGTH: Max length (in bytes) of any single line in a header (including \r\n)
// MAX_HEADER_LINES      : Max number of lines in a single header (including first GET line)
#define MAX_HEADER_LINE_LENGTH  8190
#define MAX_HEADER_LINES         100
// MAX_CHUNK_LINE_LENGTH : For accepting chunked transfer uploads, max length of chunk size line (including \r\n)
#define MAX_CHUNK_LINE_LENGTH    200

// Define the various tags we'll use to differentiate what it is we're currently doing
#define HTTP_REQUEST_HEADER                10
#define HTTP_REQUEST_BODY                  11
#define HTTP_REQUEST_CHUNK_SIZE            12
#define HTTP_REQUEST_CHUNK_DATA            13
#define HTTP_REQUEST_CHUNK_TRAILER         14
#define HTTP_REQUEST_CHUNK_FOOTER          15
#define HTTP_PARTIAL_RESPONSE              20
#define HTTP_PARTIAL_RESPONSE_HEADER       21
#define HTTP_PARTIAL_RESPONSE_BODY         22
#define HTTP_CHUNKED_RESPONSE_HEADER       30
#define HTTP_CHUNKED_RESPONSE_BODY         31
#define HTTP_CHUNKED_RESPONSE_FOOTER       32
#define HTTP_PARTIAL_RANGE_RESPONSE_BODY   40
#define HTTP_PARTIAL_RANGES_RESPONSE_BODY  50
#define HTTP_RESPONSE                      90
#define HTTP_FINAL_RESPONSE                91

#endif
