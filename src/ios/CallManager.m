//
//  CallManager.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import "CallManager.h"
#import "LinPhoneManager.h"
#import "CallData.h"
#import "AppDelegate+callprovider.h"
#import "PublicData.h"
#import "StringUtil.h"
#import "Constant.h"
#import "ProviderDelegate.h"

#import <AVFoundation/AVFoundation.h>

@interface CallManager() <LinphoneManagerListener>{
    double startRegisterTime;
    BOOL isRegistered;
    BOOL isCallConnected;
    BOOL isIncoming;
    BOOL isCallKitNeeded;
    NSUUID *incomingCallUUID;
    BOOL isRetry;
    BOOL isAllowCameraPermission;
    BOOL checkNetwork;
}

@end

@implementation CallManager

@synthesize callData;
@synthesize delegate;
@synthesize linphoneManager;

- (instancetype)init {
    if (self = [super init]) {
        isIncoming = NO;
        isCallKitNeeded = YES;
        isAllowCameraPermission = NO;
        [PublicData sharedInstance].callManager = nil;
    }
    return self;
}

- (void)startCall:(CallData *)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate {
    
    if ([PublicData sharedInstance].isCalling == YES) {
        NSLog(@"CallManager Call is already stared.");
        return;
    }
    NSLog(@"CallManager Start Call");
    
    callData = callDt;
    delegate = callManagerDelegate;
    [StringUtil setLanguage:callData.language];
    isRetry = false;
    checkNetwork = false;
    [self checkPermissions];
//    [self initializeCall];
}

-(void)checkNetworkStatus: (CallData *)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate {
    
    return;
    callData = callDt;
    delegate = callManagerDelegate;
    [StringUtil setLanguage:callData.language];
    
    checkNetwork = true;
    [self initializeCall];
}

- (void)reOpen {
    if (self.linphoneManager) {
        [self.linphoneManager reOpen];
    }
}

- (void)hangUp {
    if (self.linphoneManager) {
        [self.linphoneManager hangupWithCause:CALL_HANGUP_BY_CALLER];
    }
}

- (void)onChatMessageArrived {
    if (self.linphoneManager) {
        [self.linphoneManager onChatMessageArrived];
    }
}

- (void)startSimulatingIncomingCallWithCallKit:(CallData *)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate {
    [PublicData sharedInstance].incomingCallData = callDt;
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [((AppDelegate*)[UIApplication sharedApplication].delegate) displayIncomingCall:[NSUUID UUID] handle:@"Unknown name" hasVideo:(callDt.onlyAudioCall==1 ? NO : YES) completion:^{
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        }];
    });
}

- (void)onAnswerIncomingCall:(NSUUID *)callUuid {
    if ([PublicData sharedInstance].incomingCallData) {
        isIncoming = YES;
        incomingCallUUID = callUuid;
        [self startCall:[PublicData sharedInstance].incomingCallData callManagerDelegate:(AppDelegate*)([UIApplication sharedApplication].delegate)];
    }
}

- (void)onAnswerIncomingCallWithoutCallKit:(CallData *)callDt {
    isIncoming = YES;
    isCallKitNeeded = NO;
    [self startCall:callDt callManagerDelegate:(AppDelegate*)([UIApplication sharedApplication].delegate)];
}

- (void) checkPermissions {
    [self checkAudioPermission];
}

- (void)setIsIncoming :(BOOL) incoming{
    isIncoming = incoming;
}

- (void) checkAudioPermission {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        [self checkVideoPermission];
    } else if(authStatus == AVAuthorizationStatusDenied){
        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    } else if(authStatus == AVAuthorizationStatusRestricted){
        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        [self checkVideoPermission];
    } else {
        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    }
}

- (void) checkVideoPermission {
    isAllowCameraPermission = NO;
    //Not check video permission. We can only show doctor's screen if camera permission is denied.
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
//        [self initializeCall];
        isAllowCameraPermission = YES;
    } else if(authStatus == AVAuthorizationStatusDenied){
//        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    } else if(authStatus == AVAuthorizationStatusRestricted){
//        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
//        [self initializeCall];
        
    } else {
//        [self throwError:CALL_ERROR_PERMISSIONS_DENIED];
    }
    
    [self initializeCall];
}


- (void) initializeCall {
    //Initalize parameters;
    
    [PublicData sharedInstance].isCalling = YES;
    
    startRegisterTime = [[NSDate date] timeIntervalSince1970];
    isRegistered = NO;
    isCallConnected = NO;

    [self initializeLinphone];

    //Set Current Parameters
    [self setLinphoneCallData];
    self.linphoneManager.isCallKitNeeded = isCallKitNeeded;
    self.linphoneManager.isCameraEnable = isAllowCameraPermission;
    self.linphoneManager.currentCallUuid =  [NSUUID UUID];
    if (isIncoming) {
        self.linphoneManager.isIncoming = YES;
        
    } else {
        self.linphoneManager.isIncoming = NO;
    }
    isIncoming = YES;   //when call retry, shows connecting screen
    
    [linphoneManager setCheckNetwork:checkNetwork];
    [linphoneManager doRegister];
}

- (void)initializeLinphone {
    NSLog(@"SipVideoCall:initialize");
        LinphoneManager *manager = [LinphoneManager instance];

    self.linphoneManager = manager;
    self.linphoneManager.listener = self;
    self.linphoneManager.currentCallData = callData;
    self.linphoneManager.badgeNum = 0;
    if (!isRetry) {
        self.linphoneManager.logsStatus = @"";
    }
    [self.linphoneManager startLibLinphone];
}

- (void) setLinphoneCallData {
    // Set Credentials
    NSLog(@"SipVideoCall:setCredentials");
    assert(self);
    [linphoneManager setProxy: callData.proxy address:callData.address];
    [linphoneManager setUser: callData.username pass: callData.password domain:callData.domain forAddress: callData.address];
    [linphoneManager setTurnServer:callData.turnServer0 
        domain0:callData.turnDomain0 username0:callData.turnUsername0 password0:callData.turnPassword0 
        alternate:callData.turnServer1
        domain1:callData.turnDomain1 username1:callData.turnUsername1 password1:callData.turnPassword1
        ];
    [linphoneManager setCallQualityParams:callData.download_bandwidth upload_bandwidth:callData.upload_bandwidth framerate:callData.framerate];
    
    [linphoneManager setTransportValue];
    [linphoneManager setVideoSize];
    [linphoneManager enableLogCollection:callData.log_enable];
}

- (void) onAudioSessionActivated {
    NSLog(@"onAudioSessionActivated called.");
    if (isIncoming) {
        if (callData.onlyAudioCall == 1) {
            [self.linphoneManager audioCall:callData.to];
        } else {
            [self.linphoneManager call:callData.to];
        }
    }
}

- (void)setCredentials {

}

- (void)throwError: (int)error {
    if(self.linphoneManager)
        [self.linphoneManager destroyLibLinphone];
    [delegate onThrowError: error workflow:@"Could not place call because michrophone permissions are denied" logPath:@""];
}

- (void)onRegisterSucceeded {
    NSLog(@"onRegisterSucceed called.");
    if (checkNetwork) {
        [delegate onCheckReleased:true networkType:@"" bandwidth:0];
        return;
    }
    if (isCallConnected == NO) {
        isCallConnected = YES;
        NSLog(@"call connected");
        // else {
        if (callData.onlyAudioCall == 1) {
            [self.linphoneManager audioCall:callData.to];
        } else {
            [self.linphoneManager call:callData.to];
        }
        // }
    }
}

- (void)onRegisterFailedWithMessage: (NSString *) message {
    NSLog(@"Register failed.");
    if(self.linphoneManager)
        [self.linphoneManager destroyLibLinphone];
    [delegate onThrowError: CALL_ERROR_REGISTER_FAILURE workflow:message logPath:self.linphoneManager.logPath];
}

//called when outgoing call is connected
- (void)onCallConnectedWithPeer: (NSUUID *)uuid hasVideo:(Boolean) hasVideo{
    isCallConnected = YES;
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    [appDelegate informCallProviderCallConnected:uuid hasVideo:hasVideo];
}

- (void)onCallRejectedWithCode: (NSNumber *) code {
}

- (void)onCallFailed: (int)code workflow:(NSString *)workflow{
    [PublicData sharedInstance].isCalling = NO;
//    if(self.linphoneManager)
//        [self.linphoneManager destroyLibLinphone];
    if (self.linphoneManager) {
        [self.linphoneManager sendLinphoneDebug];
    }
    [delegate onThrowError: code workflow:workflow logPath:self.linphoneManager.logPath];
}

- (void)onCallReleased: (NSString * )workflow {
    [PublicData sharedInstance].isCalling = NO;
    linphoneManager.badgeNum = 0;
//    if(self.linphoneManager)
//        [self.linphoneManager destroyLibLinphone];
    if (self.linphoneManager) {
        [self.linphoneManager sendLinphoneDebug];
    }
    [delegate onCallReleased: workflow logPath:self.linphoneManager.logPath];
}

- (void)onCallRinging {

}

- (void)onCallEventOccur: (int)code {
    [delegate onEventComesUp: code];
}

- (void)onCallMinimized:(long)duration{
    [delegate onMinimized: duration];
}

-(void)onCallSendQuality:(NSString *)quality{
    [delegate onSendQuality:quality];
}

- (void)onCallRetry{
    isRetry = true;
    [self initializeCall];
}

- (void)onIncomingCallFrom: (NSString *) from {

}

- (void)onTransferRequestedTo: (NSString *) to {

}

@end
