//
//  ProviderDelegate.h
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/11/16.
//
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

@interface ProviderDelegate : NSObject

- (instancetype) initWithAppName: (NSString *)appName;
- (void) onCallConnected: (NSUUID *)uuid hasVideo:(Boolean) hasVideo;
- (void) willEndCall;
- (void) reportIncomingCall:(NSUUID*)uuid handle:(CXHandle*)handle hasVideo:(BOOL)hasVideo completion:(void(^)()) completion;

@end
