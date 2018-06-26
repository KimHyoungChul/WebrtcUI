//
//  ProviderDelegate.m
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/11/16.
//
//

#import "ProviderDelegate.h"
#import "LinPhoneManager.h"
#import "CallManager.h"
#import "AudioController.h"
#import "StringUtil.h"
#import "CallData.h"

@interface ProviderDelegate() <CXProviderDelegate> {
    BOOL callWillEndByCode;
    CallManager *incomingCallManager;
    AudioController *audioController;
}

@property (nonatomic, strong) CXProvider *provider;

@end

@implementation ProviderDelegate

- (instancetype) init {
    self = [super init];
    return self;
}

- (instancetype) initWithAppName: (NSString *)appName{
    self = [super init];
    CXProviderConfiguration *configuration = [self getProviderConfiguration:appName];
    self.provider = [[CXProvider alloc] initWithConfiguration: configuration];
    [self.provider setDelegate:self queue:nil];
    callWillEndByCode = NO;
    return self;
}

- (CXProviderConfiguration *) getProviderConfiguration: (NSString *)appName {
    NSString* localizedName = appName;
    CXProviderConfiguration* providerConfiguration = [[CXProviderConfiguration alloc] initWithLocalizedName:localizedName];
    
    providerConfiguration.supportsVideo = YES;
    
    providerConfiguration.maximumCallsPerCallGroup = 1;
    
    providerConfiguration.maximumCallGroups = 1;
    
    providerConfiguration.supportedHandleTypes = [NSSet setWithObject:[NSNumber numberWithInt: CXHandleTypeGeneric]];
    
    UIImage *iconMaskImage = [UIImage imageNamed:@"callee-icon"];
    providerConfiguration.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage);
    
    providerConfiguration.ringtoneSound = @"calling.wav";
    
    return providerConfiguration;
}

- (void)onCallConnected: (NSUUID *)callUuid hasVideo:(Boolean)hasVideo {
    NSLog(@"ProviderDelegate: %@ called.", @"onCallConnected");
    [self.provider reportOutgoingCallWithUUID:callUuid connectedAtDate:[NSDate date]];
    
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.hasVideo = hasVideo;
    [self.provider reportCallWithUUID:callUuid updated:update];
}

- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"ProviderDelegate: %@ called.", @"providerDidReset");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"ProviderDelegate: %@ called.", @"performStartCallAction");
    [action fulfill];
    [self.provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:nil];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"ProviderDelegate: %@ called.", @"performAnswerCallAction");
    [self configureAudioSession];
    incomingCallManager = [[CallManager alloc] init];
    [incomingCallManager onAnswerIncomingCall:action.callUUID];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"ProviderDelegate: %@ called.", @"performEndCallAction");
    [action fulfill];
    incomingCallManager = nil;
    
    if (callWillEndByCode == YES) {
        callWillEndByCode = NO;
    } else {
        NSLog(@"Provider Delegate 'hangup' calling.");
        [[LinphoneManager instance] hangupFromCXProvider];
    }
    [self stopAudio];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"ProviderDelegate: %@ called.", @"didActivateAudioSession");
//    if (incomingCallManager) {
//        [incomingCallManager onAudioSessionActivated];
//    }
    
    [self startAudio];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"ProviderDelegate: %@ called.", @"didDeactivateAudioSession");
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"ProviderDelegate: %@ called.", @"timedOutPerformingAction");
}

#pragma mark - other methods
- (void)willEndCall {
    NSLog(@"Provider Delegate called 'willEndCall'");
    callWillEndByCode = YES;
}

- (void) reportIncomingCall:(NSUUID*)uuid handle:(CXHandle*)handle hasVideo:(BOOL)hasVideo completion:(void (^)())completion {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = handle;
    update.hasVideo = hasVideo;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    NSLog(@"before calling reportIncomingCall called");

    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"reportIncomingCall called - error is nil");
        } else {
            NSLog(@"reportIncomingCall called - error isn't nil");
        }
        
        completion();
    }];
}

- (void)configureAudioSession {
    if (audioController == nil) {
        audioController = [[AudioController alloc] init];
    }
}

- (void)startAudio {
    if ([audioController startIOUnit] == kAudioServicesNoError) {
        audioController.muteAudio = NO;
    }
}

- (void)stopAudio {
    if ([audioController stopIOUnit] != kAudioServicesNoError) {
        // handle error
    }
}

@end
