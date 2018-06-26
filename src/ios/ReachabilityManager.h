//
//  ReachabilityManager.h
//  Phemium Videocall Test App
//
//  Created by arnoldmac on 5/5/17.
//
//

#import <Foundation/Foundation.h>

@class Reachability;

#import "LinPhoneManager.h"

@interface ReachabilityManager : NSObject

@property (strong, nonatomic) Reachability * reachability;

+(ReachabilityManager *) sharedManager;

+(BOOL) isReachable;
+(BOOL) isUnreachable;
+(BOOL) isReachableViaWWAN;
+(BOOL) isReachableViaWiFi;

+(int) detectNetworkType;
+(void) setReachabilityDelegate:(LinphoneManager*) linphoneManager;

@end
