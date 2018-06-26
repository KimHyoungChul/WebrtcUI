//
//  PublicData.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import "PublicData.h"

static PublicData* instance;

@implementation PublicData

+ (PublicData*) sharedInstance {
    if (instance == nil) {
        instance = [[PublicData alloc] init];
        instance.isCalling = NO;
    }
    return instance;
}

@end
