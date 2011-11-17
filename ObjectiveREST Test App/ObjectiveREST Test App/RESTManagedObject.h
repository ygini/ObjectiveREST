//
//  RESTManagedObject.h
//  ObjectiveREST Test App
//
//  Created by Yoann Gini on 17/11/11.
//  Copyright (c) 2011 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RESTManagedObject <NSObject>
// i.e. 6E4D3BA3-FCD3-4611-9796-583301DA30B
- (NSString *)rest_uuid;
@end
