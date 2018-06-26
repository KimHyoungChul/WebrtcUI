/* LinphoneManager.h
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Utils.h"

#include "linphonecore.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#import <MessageUI/MessageUI.h>

#define IPAD (LinphoneManager.runningOnIpad)

extern const char *const LINPHONERC_APPLICATION_KEY;


typedef enum _NetworkType {
    network_none = 0,
    network_2g,
    network_3g,
    network_4g,
    network_lte,
    network_wifi
} NetworkType;

typedef enum _Connectivity {
    wifi,
    wwan,
    none
} Connectivity;


struct NetworkReachabilityContext {
    bool_t testWifi, testWWan;
    void (*networkStateChanged) (Connectivity newConnectivity);
};
//
// This protocol is to be followed by the LinphoneManager listener to get informed of call/registration processes
//
@protocol LinphoneManagerListener <NSObject>

- (void)onRegisterSucceeded;
- (void)onRegisterFailedWithMessage: (NSString *) message;
- (void)onCallConnectedWithPeer: (NSUUID*) uuid hasVideo:(Boolean) hasVideo;
- (void)onCallRejectedWithCode: (NSNumber *) code;
- (void)onCallReleased: (NSString *) workflow;
- (void)onCallFailed: (int)code workflow: (NSString *) workflow;
- (void)onCallRinging;
- (void)onCallEventOccur: (int)code;
- (void)onCallMinimized: (long)duration;
- (void)onCallSendQuality: (NSString *)quality;
- (void)onCallRetry;
- (void)onIncomingCallFrom: (NSString *) from;
- (void)onTransferRequestedTo: (NSString *) to;



@end



//
// LinPhone Manager
//
@class CallData;
@interface LinphoneManager : NSObject<UINavigationControllerDelegate, MFMailComposeViewControllerDelegate> {

@protected SCNetworkReachabilityRef proxyReachability;
    
@private NSTimer* mIterateTimer;
        Connectivity connectivity;

}
+ (LinphoneManager*)instance;
+ (LinphoneCore*)getLc;

@property (retain, nonatomic) id <LinphoneManagerListener> listener;
@property (retain, nonatomic) UIView *parentView;
@property (retain, nonatomic) UIViewController *parentController;

@property (readonly) const char*  frontCamId;
@property (readonly) const char*  backCamId;
@property (readonly) NSMutableArray *logs;
@property (nonatomic, assign) BOOL speakerEnabled;
@property (nonatomic, assign) BOOL bluetoothAvailable;
@property (nonatomic, assign) BOOL keepAlive;
@property (nonatomic, assign) BOOL bluetoothEnabled;
@property (readonly) BOOL wasRemoteProvisioned;
@property (readonly) LpConfig *configDb;
@property (retain, nonatomic) NSString *ringback;

@property (strong, nonatomic) NSString *SSID;

@property (nonatomic, strong) NSUUID *currentCallUuid;
@property (atomic) BOOL isIncoming;
@property (atomic) BOOL isCallKitNeeded;

@property (atomic) BOOL isCalling;

@property (atomic) BOOL isCameraEnable;

@property (retain, nonatomic) NSString * logsStatus;
@property (retain, nonatomic) NSString * logPath;

@property (nonatomic) NSInteger badgeNum;
// Call Data
@property (nonatomic, strong) CallData *currentCallData;

// Startup
- (id)init;
- (void)startLibLinphone;
- (void)destroyLibLinphone;
- (void)closeCall;
- (void) setLocalizedMessages: (NSDictionary *) options;

- (BOOL)resignActive;
- (void)becomeActive;
- (BOOL)enterBackgroundMode;

-(void)enableLogCollection: (bool) enabled;

// Proxy/Registration
- (void)setTransportValue;
- (void)setVideoSize;
- (void)setProxy: (NSString *) proxy address:(NSString *)address;
- (void)setUser: (NSString *) user pass: (NSString *) pass domain: (NSString*) domain forAddress: (NSString *) sipaddress;
- (void)setTurnServer:(NSString *)turnServer0 
    domain0:(NSString *)turnDomain0 username0:(NSString *)turnUsername0 password0:(NSString *)turnPassword0
    alternate:(NSString *)turnServer1 
    domain1:(NSString *)turnDomain1 username1:(NSString *)turnUsername1 password1:(NSString *)turnPassword1;
- (void)doRegister;
- (void)doUnregister;
// Call setup and negotiation
- (void)setCallQualityParams: (int) download_bandwidth upload_bandwidth: (int) upload_bandwidth framerate: (int) framerate;
- (void)call: (NSString *) to;
- (void)audioCall: (NSString *) to;
- (void)hangupWithCause : (int) cause;
- (void)transferTo: (NSString *) to;
- (void)hangupFromCXProvider;

//reopen
- (void)reOpen;

- (void)onChatMessageArrived;

// In-call controls
- (void)switchCamera;
- (void)mute;
- (BOOL)isMuted;
- (void)muteCamera: (void (^)(BOOL))callback;
- (BOOL)isCameraMuted;
- (void)minimizeVideo;
- (NSString *)takeSnapshot;
- (NSNumber *)getCallQuality;
- (void) startDisplayAtLocalview: (UIView *) local andRemoteView: (UIView *) remote;
- (void) stopDisplay;
- (bool)allowSpeaker;
- (void)resizePreviewVideoSize:(CGSize)previewViewFrameSize;

// Event handlers
//- (void)onRegistrationState: (LinphoneRegistrationState) state withMessage: (char const *) message;
//- (void)onCall: (LinphoneCall *) call state: (LinphoneCallState) state withMessage: (char const *) message;
- (void)setCallResolution: (NSString *) resolution uploadKbps: (int) uploadBandwidth downloadKbps: (int) downloadBandwidth echoCancel: (BOOL) echo;
- (void)accept;
- (void)orientationChangedTo: (UIInterfaceOrientation) orientation;

- (void)checkCallAction;
- (void)setCallData: (CallData*)callData;
- (void)sendLinphoneDebug;

- (void) setCheckNetwork: (bool) check;

- (BOOL)lpConfigBoolForKey:(NSString *)key withDefault:(BOOL)value;
@end
