//
//  CallManager.h
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/22/16.
//
//

#import <Foundation/Foundation.h>

@class CallData;
@class LinphoneManager;

@protocol CallManagerDelegate <NSObject>

- (void)onThrowError:(int)error workflow:(NSString *) workflow logPath:(NSString *) logPath;
- (void)onCallReleased: (NSString *) workflow logPath:(NSString *) logPath;
- (void)onEventComesUp: (int) eventCode;
- (void)onMinimized: (long) duration;
- (void)onSendQuality: (NSString *) quality;
- (void)onCheckReleased: (bool) registable networkType:(NSString *) networkType bandwidth:(float) bandwidth;
@end

@interface CallManager : NSObject

@property (nonatomic, strong) CallData *callData;
@property (nonatomic, strong) id<CallManagerDelegate> delegate;
@property (nonatomic, strong) LinphoneManager *linphoneManager;

- (void)startCall: (CallData*)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate;
- (void)startSimulatingIncomingCallWithCallKit:(CallData *)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate;
- (void)onAnswerIncomingCall:(NSUUID*)callUuid;
- (void)onAnswerIncomingCallWithoutCallKit:(CallData *)callDt;
- (void)onAudioSessionActivated;

- (void)checkNetworkStatus: (CallData*)callDt callManagerDelegate:(id<CallManagerDelegate>)callManagerDelegate;


//reopen
- (void)reOpen;

- (void)hangUp;

- (void)onChatMessageArrived;

- (void)setIsIncoming :(BOOL) incoming;

@end
