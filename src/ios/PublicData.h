//
//  PublicData.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import <Foundation/Foundation.h>

@class CallData;
@class CallManager;
@interface PublicData : NSObject

+ (PublicData*) sharedInstance;

@property (nonatomic, strong) CallData* incomingCallData;
@property (nonatomic, strong) CallManager* callManager;

@property (nonatomic) BOOL isCalling;

@end
