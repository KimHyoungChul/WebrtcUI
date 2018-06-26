//
//  AppDelegate.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 1/20/17.
//
//

#import "AppDelegate+callprovider.h"
#import <objc/runtime.h>
#import "Constant.h"
#import "CallData.h"
#import "CallManager.h"
#import "PublicData.h"
#import "ProviderDelegate.h"
#import "LinphoneInitViewController.h"
#import "CommonUtil.h"
#import "StringUtil.h"
#import "LinPhoneManager.h"

static char providerDelegateKey;
static char pushRegistryKey;

@implementation AppDelegate (callprovider)

//- (id) getCommandInstance:(NSString*)className {
//    return [self.viewController getCommandInstance:className];
//}

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load {
    [StringUtil initialize];
}

- (PKPushRegistry *)pushRegistry {
    return objc_getAssociatedObject(self, &pushRegistryKey);
}

- (void)setPushRegistry:(PKPushRegistry *)pushRegistry {
    objc_setAssociatedObject(self, &pushRegistryKey, pushRegistry, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ProviderDelegate *)providerDelegate {
    return objc_getAssociatedObject(self, &providerDelegateKey);
}

- (void)setProviderDelegate:(ProviderDelegate *)providerDel {
    objc_setAssociatedObject(self, &providerDelegateKey, providerDel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [LinphoneManager.instance becomeActive];
}

-(void)applicationDidEnterBackground:(UIApplication *)application{
    [LinphoneManager.instance enterBackgroundMode];
}

-(void)applicationWillResignActive:(UIApplication *)application{
    [LinphoneManager.instance resignActive];
}

-(void)applicationWillTerminate:(UIApplication *)application{
    [LinphoneManager.instance closeCall];
    [LinphoneManager.instance destroyLibLinphone];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    UIViewController *presentedViewController = self.window.rootViewController.presentedViewController;
    if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController.presentedViewController;
        UIViewController *viewController = [navigationController topViewController];
        return [viewController supportedInterfaceOrientations];

    }
    return [presentedViewController supportedInterfaceOrientations];
}

- (void)displayIncomingCall:(NSUUID*)uuid handle:(NSString*)handle hasVideo:(BOOL)hasVideo completion:(void (^)(void))callback {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
    [self.providerDelegate reportIncomingCall:uuid handle:callHandle hasVideo:hasVideo completion:callback];
}

- (void)answerIncomingCall {
//    CXAnswerCallAction *answerCallAction = [[CXAnswerCallAction alloc] initWithCallUUID:[NSUUID UUID]];
//    //CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:@"kkk"];
//    //CXStartCallAction *answerCallAction = [[CXStartCallAction alloc] initWithCallUUID:[NSUUID UUID] handle:handle];
//    CXTransaction *transaction = [[CXTransaction alloc] init];
//    [transaction addAction:answerCallAction];
//    [[[CXCallController alloc] init] requestTransaction:transaction completion:^(NSError * _Nullable error) {
//        if (error == nil) {
//            NSLog(@"AnswerCall Request Succeeded.");
//        } else {
//            NSLog(@"AnswerCall Request Failed. e");
//        }
//    }];
}

- (void)informCallProviderWillEndCall {
    [self.providerDelegate willEndCall];
}

- (void)informCallProviderCallConnected: (NSUUID*) uuid hasVideo:(Boolean)hasVideo{
    [self.providerDelegate onCallConnected:uuid hasVideo:hasVideo];
}

- (void)pushRegistry:(PKPushRegistry* )registry didUpdatePushCredentials:(PKPushCredentials* )credentials forType:(PKPushType)type
{
    if( [credentials.token length] == 0 )
    {
        NSLog(@"token NULL");
        return;
    }
    
    NSLog(@"PushToken[%@]", credentials.token);
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type
{
    NSLog(@"didReceiveIncomingPushWithPayload");
    CallData *callData = [[CallData alloc] init];
    [callData checkDefaultValues];
    callData.username = [payload.dictionaryPayload objectForKey:@"username"];
    callData.address = [payload.dictionaryPayload objectForKey:@"address"];
    callData.password = [payload.dictionaryPayload objectForKey:@"password"];
    callData.domain = [payload.dictionaryPayload objectForKey:@"domain"];
    callData.proxy = [payload.dictionaryPayload objectForKey:@"proxy"];
    callData.to = [payload.dictionaryPayload objectForKey:@"to"];
    callData.consultant_name = [payload.dictionaryPayload objectForKey:@"consultant_name"];
    callData.onlyAudioCall = ((BOOL)[payload.dictionaryPayload objectForKey:@"audiocall"]==YES)?1:0;
    
    [[PublicData sharedInstance] setIncomingCallData:callData];
    
//    CallManager *callManager = [[CallManager alloc] init];
//    [callManager onAnswerIncomingCallWithoutCallKit:callData];

    // incoming call simulate start;
    [self displayIncomingCall:[NSUUID UUID] handle:callData.consultant_name hasVideo:(callData.onlyAudioCall==1)?NO:YES completion:^{
    }];
}


@end
