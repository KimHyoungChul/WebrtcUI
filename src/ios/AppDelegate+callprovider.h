//
//  AppDelegate.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 1/20/17.
//
//
#import "AppDelegate.h"
#import "PushKit/Pushkit.h"

@class ProviderDelegate;
@interface AppDelegate (callprovider) <PKPushRegistryDelegate>

@property (nonatomic, strong) PKPushRegistry *pushRegistry;
@property (nonatomic, strong) ProviderDelegate *providerDelegate;
//@property (nonatomic, strong) UIViewController *waitingViewController;

- (void)displayIncomingCall:(NSUUID*)uuid handle:(NSString*)handle hasVideo:(BOOL)hasVideo completion:(void (^)(void)) callback;
- (void)informCallProviderWillEndCall;
- (void)informCallProviderCallConnected:(NSUUID*) uuid hasVideo:(Boolean) hasVideo;

@end
