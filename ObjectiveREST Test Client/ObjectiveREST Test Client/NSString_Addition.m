//
//  NSString_Addition.m
//  ObjectiveREST Test Client
//
//  Created by Yoann Gini on 18/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import "NSString_Addition.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

@implementation NSString (Addition)


- (NSString *)base64EncodedString
{
    // Construct an OpenSSL context
    BIO *context = BIO_new(BIO_s_mem());
	
    // Tell the context to encode base64
    BIO *command = BIO_new(BIO_f_base64());
    context = BIO_push(command, context);
	
    // Encode all the data
    BIO_write(context, [self bytes], [self length]);
    BIO_flush(context);
	
    // Get the data out of the context
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(context, &outputBuffer);
    NSString *encodedString = [NSString
							   stringWithCString:outputBuffer
							   length:outputLength];
	
    BIO_free_all(context);
	
    return encodedString;
}
@end
