//
//  ReachabilityManager.m
//  Phemium Videocall Test App
//
//  Created by arnoldmac on 5/5/17.
//
//

#import "ReachabilityManager.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Reachability.h"
#import "Constant.h"

@implementation ReachabilityManager

#pragma mark -
#pragma mark Default Manager
+ (ReachabilityManager *)sharedManager {
    static ReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

#pragma mark -
#pragma mark Memory Management
- (void)dealloc {
    // Stop Notifier
    if (_reachability) {
        [_reachability stopNotifier];
    }
}

#pragma mark -
#pragma mark Class Methods
+ (BOOL)isReachable {
    return [[[ReachabilityManager sharedManager] reachability] isReachable];
}

+ (BOOL)isUnreachable {
    return ![[[ReachabilityManager sharedManager] reachability] isReachable];
}

+ (BOOL)isReachableViaWWAN {
    return [[[ReachabilityManager sharedManager] reachability] isReachableViaWWAN];
}

+ (BOOL)isReachableViaWiFi {
    
    return [[[ReachabilityManager sharedManager] reachability] isReachableViaWiFi];
}

#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];
    
    if (self) {
        // Initialize Reachability
        self.reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
        
        // Start Monitoring
        [self.reachability startNotifier];
    }
    
    return self;
}

+(int) detectNetworkType{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        NSLog(@"none");
        //No internet
        return NETWORK_STATUS_NOINTERNET;
    }
    else if (status == ReachableViaWiFi)
    {
        NSLog(@"Wifi");
        //WiFi
        return NETWORK_STATUS_WIFI;
    }
    else if (status == ReachableViaWWAN)
    {
        NSLog(@"WWAN");
        
        
        //connection type
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
//        _carrier = [[netinfo subscriberCellularProvider] carrierName];
        
        if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
            NSLog(@"2G");
            return NETWORK_STATUS_2G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
            NSLog(@"2G");
            return NETWORK_STATUS_2G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
            NSLog(@"2G");
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
            NSLog(@"3G");
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
            NSLog(@"3G");
            return NETWORK_STATUS_3G;
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
            NSLog(@"4G");
            return NETWORK_STATUS_4G;
        }
    }
    return NETWORK_STATUS_NOINTERNET;
}

@end

