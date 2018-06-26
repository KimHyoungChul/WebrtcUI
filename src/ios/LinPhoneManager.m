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

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/sysctl.h>
#include <sys/types.h>

#import <AudioToolbox/AudioToolbox.h>
#import <CallKit/CallKit.h>

#import "LinPhoneManager.h"
#import "LinphoneVideoWindowViewController.h"
#import "LinphoneInitViewController.h"
#import "AppDelegate+callprovider.h"
#import "UIColor+Hex.h"
#import "CallData.h"
#import "Constant.h"
#import "StringUtil.h"
#import "FileUtil.h"
#import "CommonUtil.h"
#import "LinphoneLogUtil.h"
//#import "OverlayCreator.h"
#include "PublicData.h"
#include "linphone/linphonecore_utils.h"
#import "Reachability.h"
#import "ReachabilityManager.h"
#import "AudioHelper.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

static LinphoneCore* theLinphoneCore = nil;
static LinphoneManager* theLinphoneManager = nil;

const char *const LINPHONERC_APPLICATION_KEY = "app";

NSString *const kLinphoneCoreUpdate = @"LinphoneCoreUpdate";
NSString *const kLinphoneDisplayStatusUpdate = @"LinphoneDisplayStatusUpdate";
NSString *const kLinphoneTextReceived = @"LinphoneTextReceived";
NSString *const kLinphoneTextComposeEvent = @"LinphoneTextComposeStarted";
NSString *const kLinphoneCallUpdate = @"LinphoneCallUpdate";
NSString *const kLinphoneRegistrationUpdate = @"LinphoneRegistrationUpdate";
NSString *const kLinphoneAddressBookUpdate = @"LinphoneAddressBookUpdate";
NSString *const kLinphoneMainViewChange = @"LinphoneMainViewChange";
NSString *const kLinphoneLogsUpdate = @"LinphoneLogsUpdate";
NSString *const kLinphoneSettingsUpdate = @"LinphoneSettingsUpdate";
NSString *const kLinphoneBluetoothAvailabilityUpdate = @"LinphoneBluetoothAvailabilityUpdate";
NSString *const kLinphoneConfiguringStateUpdate = @"LinphoneConfiguringStateUpdate";
NSString *const kLinphoneGlobalStateUpdate = @"LinphoneGlobalStateUpdate";
NSString *const kLinphoneNotifyReceived = @"LinphoneNotifyReceived";


const int kLinphoneAudioVbrCodecDefaultBitrate=36; /*you can override this from linphonerc or linphonerc-factory*/

extern void libmsilbc_init(MSFactory *);
extern void libmsamr_init(MSFactory *);
extern void libmsx264_init(MSFactory *);
extern void libmsopenh264_init(MSFactory *);
extern void libmssilk_init(MSFactory *);
extern void libmsbcg729_init(MSFactory *);
extern void libmswebrtc_init(MSFactory *);
extern void libmscodec2_init(MSFactory *);

#define FRONT_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:1" /*"AV Capture: Front Camera"*/
#define BACK_CAM_NAME "AV Capture: com.apple.avfoundation.avcapturedevice.built-in_video:0" /*"AV Capture: Back Camera"*/

#define MAX_FAILED_COUNT 2
#define MAX_RETRY_COUNT 2
#define MAX_REGISTER_RETRY_COUNT 2

typedef NS_ENUM(NSInteger, CALL_FAILED_REASON) {
    MEDIACONNECTING_ERROR=2,
};

@interface LinphoneManager () {
    NSTimer *callTimer;
}
@end

@implementation LinphoneManager
{
@private
    id <LinphoneManagerListener> _listener;
    LinphoneProxyConfig *proxyCfg;
    LinphoneAuthInfo *proxyAuth;
    LinphoneCall *currentCall;
    LinphoneVideoWindowViewController *lvvController;
    LinphoneInitViewController *lcController; // added fm
    UINavigationController *navigationController;
    CXCallController *callController;
    BOOL isAudioCall;
    
    AVAudioPlayer *avAudioPlayer;
    BOOL bHangupFromCXProvider;
    BOOL isVideoCallConnecting;
    
    // Error
    int nErrorCode;
    
    // hangup
    int nHangup;
    
    bool isNeedZoom;
    
    // Registering Timer;
    NSTimer *registeringTimer;
    
    NSTimer *unregisteringTimer;
    
    // Ringing Timer;
    NSTimer *ringingTimer;
    
    // Ring Timer;
    NSTimer *ringTimer;
    
    // Init Timer
    NSTimer *initTimer;
    
    // Connecting timer
    NSTimer *connectingTimer;
    
    //Iterate Timer
    NSTimer * linphoneScheduler;
    
    NSTimer * qualityScheduler;
    
    // call state
    int nCallStatus;
    
    int regist_failed_cnt;
    bool is_regsiter_failed;
    bool is_unregister_failed;
    bool is_unregistering;
    int regist_retry_cnt;
    
    NSString* current_turn_server;
    int connect_failed_cnt;
    bool is_connect_failed;
    
    bool isCallRetry;
    NSDate * callStartTime;
    
    bool logEnable;
    MFMailComposeViewController * mailer;
    
    NSString * qualityLog;
    NSMutableArray * qualityArray;
    int qualityCnt;
    float qualitySumof10;
    
    bool checkNetwork;
}

@synthesize frontCamId;
@synthesize backCamId;
@synthesize logs;
@synthesize speakerEnabled;
@synthesize bluetoothAvailable;
@synthesize bluetoothEnabled;
@synthesize wasRemoteProvisioned;
@synthesize configDb;

@synthesize listener = _listener;
@synthesize parentView = _parentView;
@synthesize parentController = _parentController;
@synthesize ringback;

@synthesize currentCallUuid;
@synthesize isIncoming;
@synthesize isCallKitNeeded;
@synthesize currentCallData;
@synthesize logsStatus;
@synthesize logPath;
@synthesize badgeNum;

+ (BOOL)runningOnIpad {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

+ (BOOL)isNotIphone3G
{
    static BOOL done=FALSE;
    static BOOL result;
    if (!done){
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [[NSString alloc ] initWithUTF8String:machine];
        free(machine);
        
        result = ![platform isEqualToString:@"iPhone1,2"];
        
        // [platform release];
        done=TRUE;
    }
    return result;
}

+ (LinphoneManager *)instance {
    if( theLinphoneManager == nil ) {
        theLinphoneManager = [LinphoneManager alloc];
        return [theLinphoneManager init];
    }
    return theLinphoneManager;
}

#pragma mark - Lifecycle Functions

- (id)init {
    if ((self = [super init])) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
        NSString * path = [[NSBundle mainBundle] pathForResource:@"msg" ofType:@"wav"];
        avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
        logs = [[NSMutableArray alloc] init];
        speakerEnabled = FALSE;
        bluetoothEnabled = FALSE;
        
        NSString* factoryConfig = [LinphoneManager bundleFile:[LinphoneManager runningOnIpad]?@"linphonerc-factory~ipad":@"linphonerc-factory"];
        NSString *confiFileName = [LinphoneManager documentFile:@".linphonerc"];
        configDb=lp_config_new_with_factory([confiFileName cStringUsingEncoding:[NSString defaultCStringEncoding]] , [factoryConfig cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        //set default values for first boot
        if (lp_config_get_string(configDb,LINPHONERC_APPLICATION_KEY,"debugenable_preference",NULL)==NULL){
#ifdef DEBUG
            [self lpConfigSetBool:TRUE forKey:@"debugenable_preference"];
#else
            [self lpConfigSetBool:FALSE forKey:@"debugenable_preference"];
#endif
        }
        
        callController = [[CXCallController alloc] init];
        
        _isCalling = false;
        [PublicData sharedInstance].callManager = nil;
        
        regist_failed_cnt = 0;
        connect_failed_cnt = 0;
        regist_retry_cnt = 0;
        isCallRetry = false;
        isNeedZoom = false;
        is_unregistering = false;
        qualityArray = [[NSMutableArray alloc] init];
        qualityCnt = 0;
        qualitySumof10 = 0;
        qualityLog = @"Call Average Quality Array: ";
        
        badgeNum = 0;
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Error/warning log handler
static void linphone_iphone_log(struct _LinphoneCore *lc, const char *message) {
    NSString* log = [NSString stringWithCString:message encoding:[NSString defaultCStringEncoding]];
    NSLog( log, NULL);
}



#pragma mark - Call State Functions

- (void)onCall: (LinphoneCall *) call StateChanged: (LinphoneCallState) state withMessage: (const char *) message {
     NSLog( @"CALL STATE: %s, message: %s", linphone_call_state_to_string(state) , message );
    
    // Disable speaker when no more call
    if ((state == LinphoneCallEnd || state == LinphoneCallError)) {
        if(linphone_core_get_calls_nb(theLinphoneCore) == 0) {
            [self setSpeakerEnabled:FALSE];
            bluetoothAvailable = FALSE;
            bluetoothEnabled = FALSE;
            // IOS specific
            linphone_core_start_dtmf_stream(theLinphoneCore);
        }
    }
    
    // Enable speaker when video
    if(state == LinphoneCallIncomingReceived ||
       state == LinphoneCallOutgoingInit ||
       state == LinphoneCallConnected ||
       state == LinphoneCallStreamsRunning) {
        if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
            [self setSpeakerEnabled:TRUE];
        }
    }
    
    [self check_call_state: call StateChanged:state withMessage:message];
}

static void linphone_iphone_call_state(LinphoneCore *lc, LinphoneCall* call, LinphoneCallState state, const char* message) {
//     NSLog( @"NEW CALL STATE: '%s' (message: '%s') remote %s", linphone_call_state_to_string(state), message, linphone_call_get_remote_address_as_string(call) );
//    linphone_call_get_remote_address(call);
    [(__bridge LinphoneManager*)linphone_core_cbs_get_user_data(linphone_core_get_current_callbacks(lc)) onCall:call StateChanged: state withMessage:  message];
}

- (void)onCall: (LinphoneCall *) call StatsUpdated: (LinphoneCallStats *) stats {

}

static void linphone_iphone_call_stats_update(LinphoneCore *lc, LinphoneCall* call, LinphoneCallStats * stats) {
    [(__bridge LinphoneManager*)linphone_core_cbs_get_user_data(linphone_core_get_current_callbacks(lc)) onCall:call StatsUpdated: stats];
}


#pragma mark - Global state change

static void linphone_iphone_global_state_changed(LinphoneCore *lc, LinphoneGlobalState gstate, const char *message) {
    [(__bridge LinphoneManager*)linphone_core_cbs_get_user_data(linphone_core_get_current_callbacks(lc)) onGlobalStateChanged:gstate withMessage:message];
}

-(void)onGlobalStateChanged:(LinphoneGlobalState)state withMessage:(const char*)message {
    [LinphoneLogger log:LinphoneLoggerLog format:@"onGlobalStateChanged: %d (message: %s)", state, message];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:state], @"state",
                          [NSString stringWithUTF8String:message?message:""], @"message",
                          nil];
    
    // dispatch the notification asynchronously
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneGlobalStateUpdate object:self userInfo:dict];
    });
}


-(void)globalStateChangedNotificationHandler:(NSNotification*)notif {
    if( (LinphoneGlobalState)[[[notif userInfo] valueForKey:@"state"] integerValue] == LinphoneGlobalOn){
        [self finishCoreConfiguration];
    }
}

#pragma mark - Registration State Functions

- (void)onRegister:(LinphoneCore *)lc cfg:(LinphoneProxyConfig*) cfg state:(LinphoneRegistrationState) state message:(const char*) message {
    [self check_registration_state:state message:message];
}

static void linphone_iphone_registration_state(LinphoneCore *lc, LinphoneProxyConfig *cfg, LinphoneRegistrationState state, const char *message) {
    [(__bridge LinphoneManager*)linphone_core_cbs_get_user_data(linphone_core_get_current_callbacks(lc)) onRegister:lc cfg:cfg state:state message:message];
}


-(void) setCheckNetwork: (bool) check{
    checkNetwork = check;
}

#pragma mark - Configuring status changed

-(void)configuringStateChangedNotificationHandler:(NSNotification*)notif {
    if( (LinphoneConfiguringState)[[[notif userInfo] valueForKey:@"state"] integerValue] == LinphoneConfiguringSuccessful){
        wasRemoteProvisioned = TRUE;
    } else {
        wasRemoteProvisioned = FALSE;
    }
}

//scheduling loop
- (void)iterate {
    if (theLinphoneCore != NULL) {
        @try {
            linphone_core_iterate(theLinphoneCore);
        } @catch (NSException *exception) {
            NSLog(@"Iterate:  %@", exception);
        } @finally {
            
        }
    }
}

- (void)audioSessionInterrupted:(NSNotification *)notification {
    int interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self beginInterruption];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        [self endInterruption];
    }
}

/** Should be called once per linphone_core_new() */
- (void)finishCoreConfiguration {
    
    linphone_core_enable_keep_alive(theLinphoneCore, true);
    if( ![self.ringback isEqual: @""] )
    {
        const char* lRingBack = [[LinphoneManager bundleFile:self.ringback] cStringUsingEncoding:[NSString defaultCStringEncoding]];
        linphone_core_set_ringback(theLinphoneCore, lRingBack);
    }
    
    /*DETECT cameras*/
    frontCamId= backCamId=nil;
    char** camlist = (char**)linphone_core_get_video_devices(theLinphoneCore);
    for (char* cam = *camlist;*camlist!=NULL;cam=*++camlist) {
        if (strcmp(FRONT_CAM_NAME, cam)==0) {
            frontCamId = cam;
            //great set default cam to front
            linphone_core_set_video_device(theLinphoneCore, cam);
        }
        if (strcmp(BACK_CAM_NAME, cam)==0) {
            backCamId = cam;
        }
        
    }
    
    if (![LinphoneManager isNotIphone3G]){
        LinphonePayloadType *pt=linphone_core_get_payload_type(theLinphoneCore,"SILK",24000,-1);
        if (pt) {
            linphone_payload_type_enable(pt,FALSE);
            [LinphoneLogger logc:LinphoneLoggerWarning format:"SILK/24000 and video disabled on old iPhone 3G"];
        }
        linphone_core_enable_video_capture(theLinphoneCore, FALSE);
        linphone_core_enable_video_display(theLinphoneCore, FALSE);
    }
    
    [LinphoneLogger logc:LinphoneLoggerWarning format:"Linphone [%s]  started on [%s]", linphone_core_get_version(), [[UIDevice currentDevice].model cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    
    linphone_core_enable_video_display(theLinphoneCore, TRUE);
    linphone_core_enable_video_capture(theLinphoneCore, TRUE);
    linphone_core_use_preview_window(theLinphoneCore, TRUE);
    
    // disable ipv6
    linphone_core_enable_ipv6(theLinphoneCore, false);
    
    NSLog(@"Linphone Version: %s",linphone_core_get_version());
    
    [self setupNetworkReachabilityCallback];
    
    [self disableAllCodecs];
    
    // audio codecs
    [self configurePayloadType: "OPUS" withRate: 48000 number: 98];
    [self configurePayloadType: "SPEEX" withRate: 32000 number: 99];
    [self configurePayloadType: "SPEEX" withRate: 16000 number: 100];
    [self configurePayloadType: "PCMU" withRate: 8000 number: -1];
    [self configurePayloadType: "PCMA" withRate: 8000 number: -1];
    // audio codec test
    //[self configurePayloadType: "abc" withRate: 48000];
    
    // video codecs
    [self configurePayloadType: "H264" withRate: 90000 number: 96];
    [self configurePayloadType:"VP8" withRate:90000 number: 97];
    
    // Post event
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:theLinphoneCore]
                                                     forKey:@"core"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCoreUpdate
                                                        object:[LinphoneManager instance]
                                                      userInfo:dict];
    
}


static BOOL libStarted = FALSE;

- (void)startLibLinphone {
    qualityLog = @"Call Average Quality Array: ";
    if ( libStarted ) {
        [LinphoneLogger logc:LinphoneLoggerError format:"Liblinphone is already initialized!"];
        return;
    }
    
    libStarted = TRUE;
    
    connectivity = none;
    signal(SIGPIPE, SIG_IGN);
    
    // create linphone core
    [self createLinphoneCore];
    linphone_core_migrate_to_multi_transport(theLinphoneCore);
    
    // init audio session (just getting the instance will init)
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    BOOL bAudioInputAvailable= audioSession.inputAvailable;
    NSError *err;
    
    if( ![audioSession setActive:NO error: &err] && err ) {
        NSLog(@"audioSession setActive failed: %@", [err description]);
    }
    
    if (!bAudioInputAvailable) {
        UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No microphone", nil)
                                                                         message:NSLocalizedString(@"You need to plug a microphone to your device to use the application.", nil)
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [errView addAction:defaultAction];
        [[self topViewController] presentViewController:errView animated:YES completion:nil];
    }
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
//        [self enterBackgroundMode];
    }
}

- (void)createLinphoneCore {
    
    if (theLinphoneCore != nil) {
        [LinphoneLogger logc:LinphoneLoggerLog format:"linphonecore is already created"];
        return;
    }
    [LinphoneLogger logc:LinphoneLoggerLog format:"Create linphonecore"];
    connectivity=none;
    
    LinphoneFactory * factory = linphone_factory_get();
    LinphoneCoreCbs * cbs = linphone_factory_create_core_cbs(factory);
    linphone_core_cbs_set_call_state_changed(cbs, linphone_iphone_call_state);
    linphone_core_cbs_set_registration_state_changed(cbs, linphone_iphone_registration_state);
    linphone_core_cbs_set_call_stats_updated(cbs, (LinphoneCoreCallStatsUpdatedCb)linphone_iphone_call_stats_update);
    linphone_core_cbs_set_global_state_changed(cbs, linphone_iphone_global_state_changed);
//    linphone_core_cbs_set_notify_presence_received_for_uri_or_tel(cbs, linphone_iphone_notify_presence_received_for_uri_or_tel);
//    linphone_core_cbs_set_authentication_requested(cbs, linphone_iphone_popup_password_request);
//    linphone_core_cbs_set_message_received(cbs, linphone_iphone_message_received);
//    linphone_core_cbs_set_message_received_unable_decrypt(cbs, linphone_iphone_message_received_unable_decrypt);
//    linphone_core_cbs_set_transfer_state_changed(cbs, linphone_iphone_transfer_state_changed);
//    linphone_core_cbs_set_is_composing_received(cbs, linphone_iphone_is_composing_received);
//    linphone_core_cbs_set_configuring_status(cbs, linphone_iphone_configuring_status_changed);
//    linphone_core_cbs_set_global_state_changed(cbs, linphone_iphone_global_state_changed);
//    linphone_core_cbs_set_notify_received(cbs, linphone_iphone_notify_received);
//    linphone_core_cbs_set_call_encryption_changed(cbs, linphone_iphone_call_encryption_changed);
    linphone_core_cbs_set_user_data(cbs, (__bridge void *)(self));
    theLinphoneCore = linphone_factory_create_core_with_config(factory, cbs, configDb);
    linphone_core_cbs_unref(cbs);
    
    //Set User Agent
    linphone_core_set_user_agent(theLinphoneCore, [@"Phemium VideoCall Plugin" UTF8String], [currentCallData.videocall_version UTF8String]);
    
    // Load Plugins if available in linphone SDK
    MSFactory *f = linphone_core_get_ms_factory(theLinphoneCore);
    
    libmssilk_init(f);
    libmsamr_init(f);
    libmsx264_init(f);
    libmsopenh264_init(f);
    libmswebrtc_init(f);
    libmscodec2_init(f);
    
    linphone_core_reload_ms_plugins(theLinphoneCore, NULL);
    
    /* set the CA file no matter what, since the remote provisioning could be hitting an HTTPS server */
    const char* lRootCa = [[LinphoneManager bundleFile:@"rootca.pem"] UTF8String];
    linphone_core_set_root_ca(theLinphoneCore, lRootCa);
    linphone_core_set_user_certificates_path(theLinphoneCore, [LinphoneLogUtil cacheDirectory].UTF8String);
    
    /* The core will call the linphone_iphone_configuring_status_changed callback when the remote provisioning is loaded (or skipped).
     Wait for this to finish the code configuration */
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(volumeChanged:)
     name:@"AVSystemController_SystemVolumeDidChangeNotification"
     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(globalStateChangedNotificationHandler:) name:kLinphoneGlobalStateUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configuringStateChangedNotificationHandler:) name:kLinphoneConfiguringStateUpdate object:nil];
    
    /*call iterate once immediately in order to initiate background connections with sip server or remote provisioning grab, if any */
    linphone_core_iterate(theLinphoneCore);
    linphoneScheduler =  [NSTimer scheduledTimerWithTimeInterval:0.02
                                                          target:self
                                                        selector:@selector(iterate)
                                                        userInfo:nil
                                                        repeats:YES];
}

-(void) qualityLoop{
    qualityScheduler =  [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(calculateAverageQuality)
                                                       userInfo:nil
                                                        repeats:YES];
}

+ (LinphoneCore*)getLc{
    if (theLinphoneCore == nil) {
        @throw ([NSException exceptionWithName:@"LinphoneCoreException" reason:@"LinphoneCore not initialized yet" userInfo:nil]);
    }
    return theLinphoneCore;
}

-(void) calculateAverageQuality{
    if (currentCall == nil) {
        return;
    }
    float currentQuality = linphone_call_get_current_quality(currentCall);
//    NSLog(@"Call Quality: %f", currentQuality);
    
    qualityCnt ++;
    if (qualityCnt % QUALITY_COUNT_SEND_PHEMIUM == 0) {
        qualitySumof10 += currentQuality;
        NSString * strCurrentQuality = [NSString stringWithFormat:@"%.2f", currentQuality];
        qualityLog = [NSString stringWithFormat:@"%@ %@,", qualityLog, strCurrentQuality];
        [self.listener onCallSendQuality:strCurrentQuality];
    }
    if (qualityCnt <= QUALITY_COUNT_FOR_AVERAGE) {
        [qualityArray addObject:[NSNumber numberWithFloat:currentQuality]];
    }else{
        for (int i = 1; i < QUALITY_COUNT_FOR_AVERAGE; i++) {
            qualityArray[i-1] = qualityArray[i];
        }
        qualityArray[QUALITY_COUNT_FOR_AVERAGE - 1] = [NSNumber numberWithFloat:currentQuality];
        
        float qualitySum = 0;
        for (int i = 0; i < QUALITY_COUNT_FOR_AVERAGE; i++) {
            qualitySum += [qualityArray[i] floatValue];
        }
        
        float qualityAvg = qualitySum / QUALITY_COUNT_FOR_AVERAGE;
        
        if (lvvController != NULL) {
            [lvvController updateCallStatus:qualityAvg];
        }
    }
}

- (void)closeCall{
    if (theLinphoneCore == NULL) {
        return;
    }
    linphone_core_terminate_all_calls(theLinphoneCore);
}

- (void)destroyLibLinphone {
    
    if (linphoneScheduler != NULL) {
        [linphoneScheduler invalidate];
        linphoneScheduler = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (theLinphoneCore != nil) { //just in case application terminate before linphone core initialization
        [LinphoneLogger logc:LinphoneLoggerLog format:"Destroy linphonecore"];
        linphone_core_unref(theLinphoneCore);
        theLinphoneCore = nil;
        
        // Post event
        NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:theLinphoneCore] forKey:@"core"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCoreUpdate object:[LinphoneManager instance] userInfo:dict];
        
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        if (proxyReachability) {
            CFRelease(proxyReachability);
        }
        proxyReachability = nil;
    }
    libStarted  = FALSE;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) resetLinphoneCore {
    [self destroyLibLinphone];
    [self createLinphoneCore];
    // reset network state to trigger a new network connectivity assessment
    linphone_core_set_network_reachable(theLinphoneCore, FALSE);
}

static int comp_call_id(const LinphoneCall* call , const char *callid) {
    if (linphone_call_log_get_call_id(linphone_call_get_call_log(call)) == nil) {
        ms_error ("no callid for call [%p]", call);
        return 1;
    }
    return strcmp(linphone_call_log_get_call_id(linphone_call_get_call_log(call)), callid);
}


-(void)enableLogCollection: (bool) enabled{
//        logEnable = enabled;  /// only when logenable is true
    
        if (currentCallData.log_enable) {
            [LinphoneLogUtil enableLogs: ORTP_DEBUG];
            logPath = [LinphoneLogUtil cacheDirectory];
            NSLog(@"Log Path: %@", logPath);
        }else{
            [LinphoneLogUtil enableLogs: ORTP_LOGLEV_END];
            logPath = @"";
            NSLog(@"Log Path: %@", logPath);
        }
}

#pragma mark - Audio route Functions

- (bool)allowSpeaker {
    if (IPAD) {
        return true;
    }
    bool allow = true;
    AVAudioSessionRouteDescription *newRoute = [AVAudioSession sharedInstance].currentRoute;
    if (newRoute) {
        NSString *route = newRoute.outputs[0].portType;
        allow = !([route isEqualToString:AVAudioSessionPortLineOut] ||
                  [route isEqualToString:AVAudioSessionPortHeadphones] ||
                  [[AudioHelper bluetoothRoutes] containsObject:route]);
    }
    return allow;
}

-(void) audioRouteChangeListenerCallback:(NSNotification *) notif {
    if (IPAD) return;
    
    // there is at least one bug when you disconnect an audio bluetooth headset // since we only get notification of route having changed, we cannot tell if that is due to: // -bluetooth headset disconnected or // -user wanted to use earpiece // the only thing we can assume is that when we lost a device, it must be a bluetooth one (strong hypothesis though)
    
    if ([[notif.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
    {
        bluetoothAvailable = NO;
    }
    AVAudioSessionRouteDescription *newRoute = [AVAudioSession sharedInstance].currentRoute; if (newRoute) { NSString *route = newRoute.outputs[0].portType;
        NSLog(@"Current audio route is [%s]", [route UTF8String]);
        speakerEnabled = [route isEqualToString:AVAudioSessionPortBuiltInSpeaker];
        if (([[AudioHelper bluetoothRoutes] containsObject:route]) && !speakerEnabled) {
            bluetoothAvailable = TRUE; bluetoothEnabled = TRUE;
        }
        else {
            bluetoothEnabled = FALSE;
        }
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:bluetoothAvailable], @"available", nil]; [NSNotificationCenter.defaultCenter postNotificationName:kLinphoneBluetoothAvailabilityUpdate object:self userInfo:dict];
        
    }
}

- (void)setSpeakerEnabled:(BOOL)enable {
    speakerEnabled = enable;
    NSError *err = nil;
    
    if (enable && [self allowSpeaker]) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&err];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:FALSE];
        bluetoothEnabled = FALSE;
    } else {
        AVAudioSessionPortDescription *builtinPort = [AudioHelper builtinAudioDevice];
        [[AVAudioSession sharedInstance] setPreferredInput:builtinPort error:&err];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:(linphone_core_get_calls_nb(theLinphoneCore) > 0)];
    }
    
    if (err) {
        NSLog(@"Failed to change audio route: err %@", err.localizedDescription);
        err = nil;
    }
}

- (void)setBluetoothEnabled:(BOOL)enable {
    if (bluetoothAvailable) {
        // The change of route will be done in setSpeakerEnabled
        bluetoothEnabled = enable;
        if (bluetoothEnabled) {
            NSError *err = nil;
            AVAudioSessionPortDescription *_bluetoothPort = [AudioHelper bluetoothAudioDevice];
            [[AVAudioSession sharedInstance] setPreferredInput:_bluetoothPort error:&err];
            // if setting bluetooth failed, it must be because the device is not available
            // anymore (disconnected), so deactivate bluetooth.
            if (err) {
                bluetoothEnabled = FALSE;
                NSLog(@"Failed to enable bluetooth: err %@", err.localizedDescription);
                err = nil;
            } else {
                speakerEnabled = FALSE;
                return;
            }
        }
    }
    [self setSpeakerEnabled:speakerEnabled];
}


#pragma mark - Misc Functions

+ (NSString*)bundleFile:(NSString*)file {
    return [[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] ofType:[file pathExtension]];
}

+ (NSString*)documentFile:(NSString*)file {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:file];
}


#pragma mark - LPConfig Functions

- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key {
    [self lpConfigSetString:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return;
    lp_config_set_string(configDb, [section UTF8String], [key UTF8String], value?[value UTF8String]:NULL);
}

- (NSString*)lpConfigStringForKey:(NSString*)key {
    return [self lpConfigStringForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}
- (NSString*)lpConfigStringForKey:(NSString*)key withDefault:(NSString*)defaultValue {
    NSString* value = [self lpConfigStringForKey:key];
    return value?value:defaultValue;
}

- (NSString*)lpConfigStringForKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return nil;
    const char* value = lp_config_get_string(configDb, [section UTF8String], [key UTF8String], NULL);
    if (value)
        return [NSString stringWithUTF8String:value];
    else
        return nil;
}

- (void)lpConfigSetInt:(NSInteger)value forKey:(NSString*)key {
    [self lpConfigSetInt:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetInt:(NSInteger)value forKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return;
    lp_config_set_int(configDb, [section UTF8String], [key UTF8String], (int)value );
}

- (NSInteger)lpConfigIntForKey:(NSString*)key {
    return [self lpConfigIntForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (NSInteger)lpConfigIntForKey:(NSString*)key forSection:(NSString *)section {
    if (!key) return -1;
    return lp_config_get_int(configDb, [section UTF8String], [key UTF8String], -1);
}

- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key {
    [self lpConfigSetBool:value forKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key forSection:(NSString *)section {
    return [self lpConfigSetInt:(NSInteger)(value == TRUE) forKey:key forSection:section];
}

- (BOOL)lpConfigBoolForKey:(NSString*)key {
    return [self lpConfigBoolForKey:key forSection:[NSString stringWithUTF8String:LINPHONERC_APPLICATION_KEY]];
}

- (BOOL)lpConfigBoolForKey:(NSString*)key forSection:(NSString *)section {
    return [self lpConfigIntForKey:key forSection:section] == 1;
}

- (BOOL)lpConfigBoolForKey:(NSString *)key withDefault:(BOOL)defaultValue {
    return [self lpConfigBoolForKey:key];
}

#pragma mark - PHEMIUM

- (void)disableAllCodecs
{
    LinphonePayloadType *pt;
    
    // Get audio codecs from linphonerc
    const MSList *audioCodecs = linphone_core_get_audio_payload_types(theLinphoneCore);
    const MSList *elem;
    
    // Disable all audio codecs
    for (elem = audioCodecs; elem != NULL; elem = elem->next)
    {
        pt = (LinphonePayloadType *)elem->data;
        linphone_payload_type_enable(pt, FALSE);
    }
    
    // Get video codecs from linphonerc
    const MSList *videoCodecs = linphone_core_get_video_payload_types(theLinphoneCore);
    
    // Disable all video codecs
    for (elem = videoCodecs; elem != NULL; elem = elem->next)
    {
        pt = (LinphonePayloadType *)elem->data;
        linphone_payload_type_enable(pt, FALSE);
    }
}


- (void)configurePayloadType: (const char *) type withRate: (int) rate number:(int) number
{
    LinphonePayloadType *pt;
    
    if ( ( pt = linphone_core_get_payload_type(theLinphoneCore, type, rate, LINPHONE_FIND_PAYLOAD_IGNORE_CHANNELS) ) )
    {
        if (number != -1) {
            linphone_payload_type_set_number(pt, number);
        }
        
        linphone_payload_type_enable(pt, TRUE);
    }
}


- (void) stopDisplay
{
    linphone_core_set_native_video_window_id(theLinphoneCore, 0);
    linphone_core_set_native_preview_window_id(theLinphoneCore, 0);
}


- (void) startDisplayAtLocalview: (UIView *) local andRemoteView: (UIView *) remote
{
    linphone_core_set_native_video_window_id(theLinphoneCore, (__bridge void *)(remote));
    linphone_core_set_native_preview_window_id(theLinphoneCore, (__bridge void *)(local));
}


- (void)orientationChangedTo: (UIInterfaceOrientation) orientation
{
    int oldLinphoneOrientation = linphone_core_get_device_rotation(theLinphoneCore);
    int newRotation = 0;
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortraitUpsideDown:
            newRotation = 180;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            newRotation = 90;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            newRotation = 270;
            break;
            
        case UIInterfaceOrientationPortrait:
            newRotation = 0;
            break;
            
        default:
            break;
    }
    
    if (newRotation != -1 && oldLinphoneOrientation != newRotation) {
        linphone_core_set_device_rotation(theLinphoneCore, newRotation);
        if ( currentCall && linphone_call_params_video_enabled( linphone_call_get_current_params(currentCall) ) ) {
            //Orientation has changed, must call update call
            linphone_call_update(currentCall, NULL);
        }
    }
}

- (void)setCallData: (CallData *)callData {
}

- (void)setVideoSize {
    NSString * video_size = currentCallData.video_size == nil ? @"vga" : currentCallData.video_size;  // IF not set, default value is "vga"
    bool bSupport = false;
    const MSVideoSizeDef *sizes = linphone_core_get_supported_video_sizes(theLinphoneCore);
    for (; sizes->name != NULL; sizes++)
    {
        NSLog(@"video sizes: %d,%d %s", sizes->vsize.width, sizes->vsize.height, sizes->name);
        NSString * size_name = [NSString stringWithFormat:@"%s", sizes->name];
        if ([video_size isEqualToString:size_name]) {
            bSupport = true;
            break;
        }
    }
    if(bSupport){
        if ([video_size isEqualToString:@"qcif"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_QCIF);
        }
        if ([video_size isEqualToString:@"cif"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_CIF);
        }
        if ([video_size isEqualToString:@"qvga"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_QVGA);
        }
        if ([video_size isEqualToString:@"vga"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_VGA);
        }
        if ([video_size isEqualToString:@"720p"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_720P);
        }
        if ([video_size isEqualToString:@"1080p"]) {
            linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_1080P);
        }
    }else{
        linphone_core_set_preferred_video_size(theLinphoneCore, MS_VIDEO_SIZE_QVGA);
    }
    NSString * logString = [NSString stringWithFormat:@"---Set Video Resolution: %@" , video_size];
    [self insertLogString:logString];
}
    
- (void)setTransportValue {
    // User random ports
    LinphoneSipTransports transportValue = {};
    if ([currentCallData.transport_mode isEqualToString:@"tcp"]) {
        transportValue.tcp_port = -1;
        transportValue.dtls_port = -1;
        transportValue.tls_port = 0;
        transportValue.udp_port = 0;
    }
    if ([currentCallData.transport_mode isEqualToString:@"udp"]) {
        transportValue.tcp_port = 0;
        transportValue.dtls_port = -1;
        transportValue.tls_port = 0;
        transportValue.udp_port = -1;
    }
    if ([currentCallData.transport_mode isEqualToString:@"tls"]) {
        transportValue.tcp_port = -1;
        transportValue.dtls_port = -1;
        transportValue.tls_port = -1;
        transportValue.udp_port = -1;
    }
    linphone_core_set_sip_transports(theLinphoneCore, &transportValue);
    linphone_core_set_audio_port_range(theLinphoneCore, 10000, 10199);
    linphone_core_set_video_port_range(theLinphoneCore, 12000, 12199);
}


- (void)setProxy: (NSString *) proxy address:(NSString *)address  {
    NSLog(@"setProxy function called. proxy: %@", proxy);
    if (![proxy hasPrefix:@"sip:"] &&  ![proxy hasPrefix:@"sips:"]) {
        proxy = [NSString stringWithFormat:@"sip:%@", proxy];
    }
    char * _proxy = ms_strdup([proxy UTF8String]);
    LinphoneAddress * proxyAddress = linphone_core_interpret_url( theLinphoneCore, _proxy);
    proxyCfg = linphone_core_create_proxy_config(theLinphoneCore);
    if (proxyAddress != NULL) {
        if ([currentCallData.transport_mode isEqualToString:@"tcp"]) {
            linphone_address_set_transport(proxyAddress, LinphoneTransportTcp);
        }
        if ([currentCallData.transport_mode isEqualToString:@"udp"]) {
            linphone_address_set_transport(proxyAddress, LinphoneTransportUdp);
        }
        if ([currentCallData.transport_mode isEqualToString:@"tls"]) {
            linphone_address_set_transport(proxyAddress, LinphoneTransportTls);
        }
        
        ms_free(_proxy);
        _proxy = linphone_address_as_string_uri_only(proxyAddress);
    }
    LinphoneAddress *lpAddress = linphone_core_interpret_url(theLinphoneCore, "sip:user@domain.com");
    linphone_address_set_username(lpAddress, currentCallData.username.UTF8String);
    linphone_address_set_domain(lpAddress, currentCallData.domain.UTF8String);
    linphone_proxy_config_set_identity_address(proxyCfg, lpAddress);
    linphone_proxy_config_set_server_addr(proxyCfg, _proxy);
    linphone_proxy_config_set_route(proxyCfg, _proxy);
    
    linphone_core_add_proxy_config(theLinphoneCore, proxyCfg);
    linphone_core_set_default_proxy_config(theLinphoneCore, proxyCfg);
    NSString * logString = [NSString stringWithFormat:@"---Platform: %@" , @"iOS"];
    [self insertLogString:logString];

    logString = [NSString stringWithFormat:@"---ProxyServer Address: %s" , linphone_proxy_config_get_server_addr(proxyCfg)];
    [self insertLogString:logString];
    
    logString = [NSString stringWithFormat:@"---SIP Transport: %@" , currentCallData.transport_mode];
    [self insertLogString:logString];
    
    logString = [NSString stringWithFormat:@"---Debug Mode: %@" , currentCallData.log_enable?@"true":@"false"];
    [self insertLogString:logString];
}


- (void)setUser: (NSString *) user pass: (NSString *) pass domain:(NSString*) domain forAddress: (NSString *) sipaddress
{
    proxyAuth = linphone_auth_info_new([user UTF8String], NULL, [pass UTF8String], NULL, [domain UTF8String], [domain UTF8String]);
    linphone_core_add_auth_info(theLinphoneCore, proxyAuth);
}

- (void)setTurnServer:(NSString *)turnServer0 
    domain0:(NSString *)turnDomain0 username0:(NSString *)turnUsername0 password0:(NSString *)turnPassword0
    alternate:(NSString *)turnServer1 
    domain1:(NSString *)turnDomain1 username1:(NSString *)turnUsername1 password1:(NSString *)turnPassword1
{
    int currentIndex = connect_failed_cnt % 2;
    LinphoneNatPolicy *op = linphone_core_create_nat_policy(theLinphoneCore);
    linphone_nat_policy_enable_ice(op, true);
    linphone_nat_policy_enable_turn(op, true);
    
    NSString *currentServer = turnServer0;
    NSString *currentDomain = turnDomain0;
    NSString *currentUsername = turnUsername0;
    NSString *currentPassword = turnPassword0;
    if( currentIndex == 1 )
    {
        currentServer = turnServer1;
        currentDomain = turnDomain1;
        currentUsername = turnUsername1;
        currentPassword = turnPassword1;
    }

    NSString * logString = [NSString stringWithFormat:@"--- Turn definition when try #%d. Address: %@, Domain: %@, Username: %@, Password: %@", 
        connect_failed_cnt, currentServer, currentDomain, currentUsername, currentPassword ];
    [self insertLogString:logString];

    linphone_nat_policy_set_stun_server(op, [currentServer UTF8String]);
    current_turn_server = currentServer;
    if (![StringUtil isEmpty:currentUsername]) {
        const LinphoneAuthInfo *turnAuthInfo = nil;
        const char *domain = NULL;
        if (![StringUtil isEmpty:currentDomain]) {
            domain = [currentDomain UTF8String];
        }
        if (![StringUtil isEmpty:currentPassword]) {
            turnAuthInfo = linphone_core_create_auth_info(theLinphoneCore, [currentUsername UTF8String], NULL, [currentPassword UTF8String], NULL, domain, domain);
        } else {
            turnAuthInfo = linphone_core_find_auth_info(theLinphoneCore, NULL, [currentUsername UTF8String], domain);
        }
        if (turnAuthInfo != nil) {
            NSLog(@"turnAuthInfo is not nil");
            linphone_core_add_auth_info(theLinphoneCore, turnAuthInfo);
        }
        linphone_nat_policy_set_stun_server_username(op, linphone_auth_info_get_username(turnAuthInfo));
        linphone_core_set_nat_policy(theLinphoneCore, op);

        
    }
    
    // encryption: default is srtp
    if ([currentCallData.encryption_mode isEqualToString:@"none"]) {
        linphone_core_set_media_encryption_mandatory(theLinphoneCore, false);
        linphone_core_set_media_encryption(theLinphoneCore, LinphoneMediaEncryptionNone);
    }
    if ([currentCallData.encryption_mode isEqualToString:@"srtp"]) {
        linphone_core_set_media_encryption_mandatory(theLinphoneCore, true);
        linphone_core_set_media_encryption(theLinphoneCore, LinphoneMediaEncryptionSRTP);
    }
    if ([currentCallData.encryption_mode isEqualToString:@"zrtp"]) {
        linphone_core_set_media_encryption_mandatory(theLinphoneCore, true);
        linphone_core_set_media_encryption(theLinphoneCore, LinphoneMediaEncryptionZRTP);
    }
    if ([currentCallData.encryption_mode isEqualToString:@"dtls"]) {
        linphone_core_set_media_encryption_mandatory(theLinphoneCore, true);
        linphone_core_set_media_encryption(theLinphoneCore, LinphoneMediaEncryptionDTLS);
    }
    
    logString = [NSString stringWithFormat:@"---Encryption Mode: %@" , currentCallData.encryption_mode];
    [self insertLogString:logString];
}


- (void)setCallQualityParams: (int) download_bandwidth upload_bandwidth: (int) upload_bandwidth framerate: (int) framerate
{
    if( download_bandwidth != -1 )
    {
        linphone_core_set_download_bandwidth(theLinphoneCore, download_bandwidth);
    }
    
    if( upload_bandwidth != -1 )
    {
        linphone_core_set_upload_bandwidth(theLinphoneCore, upload_bandwidth);
    }
    
    if( framerate != -1 )
    {
        linphone_core_set_preferred_framerate(theLinphoneCore, framerate);
    }
}

- (void)setCallResolution: (NSString *) resolution uploadKbps: (int) uploadBandwidth downloadKbps: (int) downloadBandwidth echoCancel: (BOOL) echo
{
    linphone_core_set_upload_bandwidth(theLinphoneCore, uploadBandwidth);
    linphone_core_set_download_bandwidth(theLinphoneCore, downloadBandwidth);
    linphone_core_enable_echo_cancellation(theLinphoneCore, (bool_t)echo);
    linphone_core_set_preferred_video_size_by_name(theLinphoneCore, [resolution cStringUsingEncoding: NSUTF8StringEncoding]);
}

//- (void)setMainColor:(NSString *)main_color secondaryColor:(NSString *)secondary_color displayName:(NSString *)display_name displayButtonTime:(int)display_button_time language:(NSString *)lang userName:(NSString *)user_name {
//    mainColor = [UIColor colorWithCSS:main_color];
//    secondaryColor = [UIColor colorWithCSS:secondary_color];
//    displayName = display_name;
//    displayButtonTime = display_button_time;
//    language = lang;
//    userName = user_name;
//}

- (void)doRegister {
    if (!proxyCfg) {
        return;
    }
    _isCalling = false;
    NSString * pluginVersion = [NSString stringWithFormat:@"Phemium Videocall Plugin Version: %@" , currentCallData.videocall_version];
    NSString * logString = [NSString stringWithFormat:@"---Plugin Version: %@" , pluginVersion];
    [self insertLogString:logString];
    
    switch ([ReachabilityManager detectNetworkType]) {
        case NETWORK_STATUS_NOINTERNET:
            nErrorCode = CALL_ERROR_NOINTERNET;
            logString = [NSString stringWithFormat:@"---Network Info: %@" , @"No Internet"];
            [self insertLogString:logString];
            [self hideCallingScreen];
            return;
        case NETWORK_STATUS_WIFI:
            logString = [NSString stringWithFormat:@"---Network Info: %@" , @"WiFi"];
            [self insertLogString:logString];
            break;
        case NETWORK_STATUS_2G:
            logString = [NSString stringWithFormat:@"---Network Info: %@" , @"2G"];
            [self insertLogString:logString];
            break;
        case NETWORK_STATUS_3G:
            logString = [NSString stringWithFormat:@"---Network Info: %@" , @"3G"];
            [self insertLogString:logString];
            break;
        case NETWORK_STATUS_4G:
            logString = [NSString stringWithFormat:@"---Network Info: %@" , @"4G"];
            [self insertLogString:logString];
            break;
        default:
            break;
    }
    
    float vol = [[AVAudioSession sharedInstance] outputVolume];
    logString = [NSString stringWithFormat:@"---Output Volume: %.0f", vol * 100];
    [self insertLogString:logString];
    NSLog(@"output volume: %1.2f dB", vol);
    
    NSString * cameraPermission = @"";
    if (_isCameraEnable) {
        cameraPermission = @"Allowed";
    }else{
        cameraPermission = @"Not Allowed";
    }
    logString = [NSString stringWithFormat:@"---Camera Permisssion: %@" , cameraPermission];
    [self insertLogString:logString];
    
    logString = [NSString stringWithFormat:@"---Consultation Id: %@" , currentCallData.consultation_id];
    [self insertLogString:logString];
    
    if (isIncoming) {
        [self showConnectingScreen];
    }
    
    regist_failed_cnt = 0;
    is_regsiter_failed = false;
    is_unregister_failed = false;
    
    nErrorCode = CALL_NO_ERROR;
    nCallStatus = CALL_STATUS_REGISTERING;
    [lcController setCallStatus:nCallStatus count:regist_failed_cnt];
    
    
    logString = [NSString stringWithFormat:@"---%@" , @"Login..."];
    [self insertLogString:logString];
    
    NSLog(@"registering...");
    
    //linphone_core_clear_proxy_config(theLinphoneCore);
    //linphone_core_clear_all_auth_info(theLinphoneCore);
    linphone_proxy_config_edit(proxyCfg);
    linphone_proxy_config_enable_register(proxyCfg, TRUE);
    linphone_proxy_config_done(proxyCfg);
    linphone_core_set_network_reachable(theLinphoneCore, true);

    registeringTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_REGISTER_TIMEOUT_SECONDS target:self selector:@selector(onRegisterTimeout) userInfo:nil repeats:NO];
}

- (void)doUnregister {
    if (!proxyCfg) {
        return;
    }
    if (is_unregistering) {
        return;
    }
    is_unregistering = true;
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"UnRegistration..."];
    [self insertLogString:logString];
    
    NSLog(@"unregistering...");
    
    linphone_proxy_config_edit(proxyCfg);
    linphone_proxy_config_enable_register(proxyCfg, FALSE);
    linphone_proxy_config_set_expires(proxyCfg, 0);
    linphone_proxy_config_done(proxyCfg);
    
    linphone_core_clear_proxy_config(theLinphoneCore);
    linphone_core_clear_all_auth_info(theLinphoneCore);
    
    unregisteringTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_UNREGISTER_TIMEOUT_SECONDS target:self selector:@selector(onUnregisterTimeout) userInfo:nil repeats:NO];
}

- (void)onRegisterTimeout {
    
    if (registeringTimer != nil) {
        [registeringTimer invalidate];
        registeringTimer = nil;
    }
    
    if (is_regsiter_failed) {
        return;
    }
    NSLog(@"register timeout");
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Register Timeout..."];
    [self insertLogString:logString];
    
    is_regsiter_failed = true;
    
    regist_retry_cnt ++;
    if (regist_retry_cnt < MAX_REGISTER_RETRY_COUNT) {
        
        [self enableLogCollection:YES];
        NSString * logString = [NSString stringWithFormat:@"---%@" , @"Register Retrying"];
        [self insertLogString:logString];
        
        [lcController setCallStatus:CALL_STATUS_RETRYING count:0];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            NSLog(@"Regsiter Retrying...");
            [self doRegister];
        });
    }else{
        regist_retry_cnt = 0;
        nErrorCode = CALL_ERROR_REGISTER_FAILURE;
        
        //originally [self returnCodeToListener], but in case of incoming simulation where connecting screen is shown up by default, we should dismiss that first, and then return code.
        [self hideCallingScreen];
    }
}

- (void)onUnregisterTimeout {
    if (is_unregister_failed) {
        return;
    }
    NSLog(@"unregister timeout");
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Unregister Timeout..."];
    [self insertLogString:logString];
    
    is_unregister_failed = true;
    
    nErrorCode = CALL_ERROR_UNKNOWN;
    
    if (unregisteringTimer != nil) {
        [unregisteringTimer invalidate];
        unregisteringTimer = nil;
    }
    
    //originally [self returnCodeToListener], but in case of incoming simulation where connecting screen is shown up by default, we should dismiss that first, and then return code.
    [self hideCallingScreen];
   
}

- (void)onInitTimeout {
    NSLog(@"init timeout");
    nErrorCode = CALL_ERROR_INIT_TIMEOUT;
    
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Init Timeout..."];
    [self insertLogString:logString];
    
    //originally [self returnCodeToListener], but in case of incoming simulation where connecting screen is shown up by default, we should dismiss that first, and then return code.
    if (initTimer != nil) {
        [initTimer invalidate];
        initTimer = nil;
    }
    [self hangupWithCause: CALL_HANGUP_BY_ERROR];
}

- (void)onRingTimeout {
    NSLog(@"ring timeout");
    
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Web User Not Found..."];
    [self insertLogString:logString];
    
    nErrorCode = CALL_ERROR_WEB_USER_NOT_FOUND;

    if (ringTimer != nil) {
        [ringTimer invalidate];
        ringTimer = nil;
    }
    
    [self hangupWithCause: CALL_HANGUP_BY_ERROR];
}

- (void)onRingingTimeout {
    NSLog(@"ringing timeout");
    nErrorCode = CALL_ERROR_RINGING_TIMEOUT;
    
    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Ringing Timeout..."];
    [self insertLogString:logString];

    if (ringingTimer != nil) {
        [ringingTimer invalidate];
        ringingTimer = nil;
    }
    [self hangupWithCause: CALL_HANGUP_BY_ERROR];
}

- (void)call: (NSString *) to {
    isAudioCall = NO;
    nErrorCode = CALL_NO_ERROR;
    
    _isCalling = true;
    if (currentCall) { // No more than one call at a time
        NSLog(@"WARNING: Trying to setup a second call when one is in progress");
        return;
    }
    
    initTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_INIT_TIMEOUT_SECONDS target:self selector:@selector(onInitTimeout) userInfo:nil repeats:NO];
    
    //get supporting recording file formats
    /*const char **recording_file_formats = linphone_core_get_supported_file_formats(theLinphoneCore);
    if (recording_file_formats != nil) {
        NSLog(@"Recordable file formats: %s", recording_file_formats[2]);
    }*/
    
    //currentCall = linphone_core_invite(theLinphoneCore, [to cStringUsingEncoding: NSUTF8StringEncoding]);
    //NSString *recordFilePath = [FileUtil getPathForRecordingMedia: NO];
    //NSLog(@"Record File Path: %@", recordFilePath);
    LinphoneCallParams *params = linphone_core_create_call_params(theLinphoneCore, currentCall);
    linphone_call_params_enable_video(params, YES);
    NSString * phemiumInfo = [NSString stringWithFormat:@"%@/%@/%@/%@/%@", currentCallData.consultation_id,currentCallData.enduser_version, @"videocall",
                              [[UIDevice currentDevice] localizedModel] , [[UIDevice currentDevice]systemVersion]];
    linphone_call_params_add_custom_header(params, [@"PhemiumInfo" UTF8String], [phemiumInfo UTF8String]);
    
//    linphone_call_params_enable_low_bandwidth(params, YES)
    //linphone_call_params_set_record_file(params, [recordFilePath UTF8String]);
    linphone_proxy_config_get_contact(proxyCfg);
    currentCall = linphone_core_invite_with_params(theLinphoneCore, [to cStringUsingEncoding: NSUTF8StringEncoding], params);
    
    linphone_call_ref(currentCall);
    
    bHangupFromCXProvider = NO;
    
    NSLog(@"isIncoming: %d", isIncoming);
//    if (!isIncoming && isCallKitNeeded) {
    if(isCallKitNeeded){
        [self requestStartCallTransaction:to toUsername:currentCallData.consultant_name];
    }
}

- (void)audioCall: (NSString *) to {
    isAudioCall = YES;
    nErrorCode = CALL_NO_ERROR;
    
    _isCalling = true;
    NSLog(@"Audio Call.");
    if (currentCall) { // No more than one call at a time
        NSLog(@"WARNING: Trying to setup a second call when one is in progress");
        return;
    }
    
    initTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_INIT_TIMEOUT_SECONDS target:self selector:@selector(onInitTimeout) userInfo:nil repeats:NO];
    
    NSString *recordFilePath = [FileUtil getPathForRecordingMedia: YES];
    NSLog(@"Record File Path: %@", recordFilePath);
    LinphoneCallParams *params = linphone_core_create_call_params(theLinphoneCore, currentCall);
    linphone_call_params_enable_video(params, NO);
    //linphone_call_params_set_record_file(params, [recordFilePath UTF8String]);
    
    NSString * phemiumInfo = [NSString stringWithFormat:@"%@/%@/%@/%@/%@", currentCallData.consultation_id,currentCallData.enduser_version, @"audiocall",
                              [[UIDevice currentDevice] localizedModel] , [[UIDevice currentDevice]systemVersion]];
    linphone_call_params_add_custom_header(params, [@"PhemiumInfo" UTF8String], [phemiumInfo UTF8String]);
    
    
    currentCall = linphone_core_invite_with_params(theLinphoneCore, [to cStringUsingEncoding: NSUTF8StringEncoding], params);
    
    linphone_call_ref(currentCall);
    linphone_call_params_unref(params);
    
//    if (!isIncoming && isCallKitNeeded) {
    if(isCallKitNeeded){
        [self requestStartCallTransaction:to toUsername:currentCallData.consultant_name];
    }
}

- (void)requestStartCallTransaction: (NSString *)to toUsername: username {
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:username];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:currentCallUuid handle:handle];
    NSLog(@"Start Call Action UUID: %@", startCallAction.callUUID.UUIDString);
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)requestEndCallTransaction{
    if (currentCallUuid == nil) {
        NSLog(@"Current Call UUID is nil.");
        return;
    }
    NSLog(@"End Call Action UUID: %@", currentCallUuid.UUIDString);
    
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:currentCallUuid];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:endCallAction];
    [self requestTransaction:transaction];
}

- (void)requestTransaction: (CXTransaction *)transaction {
    NSLog(@"Call Transaction Request Sent.");
    [callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"Requested transaction successfully");
            CXCallAction *callAction = (CXCallAction *)[transaction.actions objectAtIndex:0];
            if ([callAction isKindOfClass:[CXStartCallAction class]]) {
                currentCallUuid = callAction.callUUID;
            } else if([callAction isKindOfClass:[CXEndCallAction class]]){
                currentCallUuid = nil;
                [((AppDelegate *)[UIApplication sharedApplication].delegate) informCallProviderWillEndCall];
            } else {
                
            }
        } else {
            NSLog(@"Error requesting transaction: \(%@)", error);
        }
    }];
}

- (void)mute {
    linphone_core_enable_mic(theLinphoneCore, (bool_t)[self isMuted]);
    if (!isAudioCall) {
        [lvvController setMuteButtonState];
    }
    
    NSString * logString = @"";
    
    
    // for informing event to enduser-plugin
    if ([self isMuted]) {
        [self.listener onCallEventOccur:CALL_EVENT_MICRO_MUTED];
        logString = [NSString stringWithFormat:@"Event: %@" , @"User muted Microphone"];
    } else {
        [self.listener onCallEventOccur:CALL_EVENT_MICRO_UNMUTED];
        logString = [NSString stringWithFormat:@"Event: %@" , @"User unmuted Microphone"];
    }
    
    [self insertLogString:logString];
}

- (void)minimizeVideo {
    NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:callStartTime];
    long seconds = lroundf( difference );
    [self.listener onCallMinimized: seconds];
    
    NSString * logString = @"";
    logString = [NSString stringWithFormat:@"Event: User returned to normal view"];
    [self insertLogString:logString];
}

-(void)insertLogString : (NSString *) logString{
    NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:callStartTime];
    long duration = 0l;
    if(nCallStatus == CALL_STATUS_CONNECTED){
        duration = lroundf( difference );
    }else{
        duration = 0l;
    }
    int seconds = duration % 60;
    int minutes = duration / 60  % 60;
    int hours = (int)duration / 3600;
    NSString * timeValue = @"";
    if (duration == 0) {
        timeValue = @"";
    }else{
        if (hours > 0) {
            timeValue = [NSString stringWithFormat:@"%dh %dm %ds", hours, minutes, seconds];
        }else{
            timeValue = [NSString stringWithFormat:@"%dm %ds", minutes, seconds];
        }
    }
    
    NSString *logStringWithTimeValue = [NSString stringWithFormat:@"%@: %@" , timeValue, logString];
    if ([timeValue isEqualToString:@""]) {
        logStringWithTimeValue = [NSString stringWithFormat:@"%@", logString];
    }
    logsStatus = [NSString stringWithFormat:@"%@ %@; \n", logsStatus, logStringWithTimeValue];
}

- (BOOL)isMuted
{
    return !linphone_core_mic_enabled(theLinphoneCore);
}

- (NSString *)takeSnapshot
{
    if (!currentCall)
    {
        return nil;
    }
    
    NSString *tempfile = [NSTemporaryDirectory () stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"jpg"]];
    linphone_call_take_video_snapshot(currentCall, [tempfile cStringUsingEncoding: NSUTF8StringEncoding]);
    return tempfile;
}


- (NSNumber *)getCallQuality
{
    if (!currentCall)
    {
        return [NSNumber numberWithFloat: -1.0];
    }
    
    float q = linphone_call_get_current_quality(currentCall);
    return [NSNumber numberWithFloat: q];
}

- (void)volumeChanged:(NSNotification *)notification
{
    float volume =
    [[[notification userInfo]
      objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
     floatValue];
    
    // Do stuff with volume
    if (_isCalling) {
        NSString *logString = [NSString stringWithFormat:@"---Output Volume: %f", volume];
        [self insertLogString:logString];
        NSLog(@"output volume: %1.2f dB", 20.f*log10f(volume+FLT_MIN));
    }
}


- (void)initController
{
    if (!lvvController) {
        lvvController = [[LinphoneVideoWindowViewController alloc] initWithNibName: @"LinphoneVideoWindowViewController" bundle: [NSBundle mainBundle]];
        lvvController.theLinphoneManager = self;
        
        //Parameters
        UIColor *mainColor = [UIColor colorWithCSS:currentCallData.main_color];
        UIColor *fontColor = [UIColor colorWithCSS:currentCallData.font_color];
        NSString *calleeUserName = currentCallData.consultant_name;
        NSString *callRecordingNotification = currentCallData.call_recording_notification_visible;
        NSString * chatMode = currentCallData.chat_mode;
        NSString * zoomMode = currentCallData.zoom_mode;
        if (![StringUtil isEmpty:calleeUserName]) {
            lvvController.userName = currentCallData.consultant_name;
        }
        lvvController.displayButtonTime = currentCallData.display_button_time;
        if (mainColor != nil) {
            lvvController.mainColor = [UIColor colorWithCSS:currentCallData.main_color];
        }
        lvvController.displayNameMode = currentCallData.display_topview_mode;
        lvvController.fontSize = currentCallData.font_size;
        if (fontColor != nil) {
            lvvController.fontColor = [UIColor colorWithCSS:currentCallData.font_color];
        }
        if ([callRecordingNotification isEqualToString:@"yes"]) {
            lvvController.bCallRecordingNotification = YES;
        } else {
            lvvController.bCallRecordingNotification = NO;
        }
        if ([chatMode isEqualToString:@"WithChat"]) {
            lvvController.bShowChatBtn = YES;
        } else {
            lvvController.bShowChatBtn = NO;
        }
        
        if ([zoomMode isEqualToString:@"zoom"]) {
            lvvController.bZoomMode = YES;
        } else {
            lvvController.bZoomMode = NO;
        }
    }
}

// added fj
- (void)initConnectingViewController {
    if (!lcController) {
        BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
        if (isLandscape) {
            lcController = [[LinphoneInitViewController alloc] initWithNibName: @"LinphoneInitViewControllerLandscape" bundle: [NSBundle mainBundle]];
        }else{
            lcController = [[LinphoneInitViewController alloc] initWithNibName: @"LinphoneInitViewControllerPortrait" bundle: [NSBundle mainBundle]];
        }

        
        //Parameters
        UIColor *mainColor = [UIColor colorWithCSS:currentCallData.main_color];
        UIColor *secondaryColor = [UIColor colorWithCSS:currentCallData.secondary_color];
        UIColor *fontColor = [UIColor colorWithCSS:currentCallData.font_color];
        NSString *calleeUserName = currentCallData.consultant_name;
        NSString *callRecordingNotification = currentCallData.call_recording_notification_visible;
        NSString *chatMode = currentCallData.chat_mode;
        
        if (mainColor != nil) {
            lcController.mainColor = mainColor;
        }
        if (secondaryColor != nil) {
            lcController.secondaryColor = secondaryColor;
        }
        if (![StringUtil isEmpty:calleeUserName]) {
            lcController.userName = currentCallData.consultant_name;
        }
        lcController.fontSize = currentCallData.font_size;
        if (fontColor != nil) {
            lcController.fontColor = [UIColor colorWithCSS:currentCallData.font_color];
        }
        if ([callRecordingNotification isEqualToString:@"yes"]) {
            lcController.bCallRecordingNotification = YES;
        } else {
            lcController.bCallRecordingNotification = NO;
        }
        if ([chatMode isEqualToString:@"WithChat"]) {
            lcController.bShowChatBtn = YES;
        } else {
            lcController.bShowChatBtn = NO;
        }
        
        if (isIncoming) {
            [lcController setCallStatus:CALL_STATUS_REGISTERING count:0];
        }
    }
}


- (UIViewController *)topViewController{
    return [CommonUtil topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (void)showPlayer
{
    [self initController];
    [self.parentController presentViewController: lvvController animated: YES completion:^{
    }
     ];
}


- (void)hidePlayer
{
    if (lvvController && self.parentController.presentedViewController == lvvController)
    {
        [self.parentController dismissViewControllerAnimated: YES completion:^{
            [self stopDisplay];
        }];
    }
}

- (void) setLocalizedMessages: (NSDictionary *) options {
    [self initController];
    lvvController.messages = options;
}

- (void)hangupFromCXProvider {
    bHangupFromCXProvider = YES;
    [self hangupWithCause: CALL_HANGUP_BY_CALLER];
}

- (void)hangupWithCause: (int) cause {
    if(!currentCall){
        return;
    }
    if (lvvController != nil) {
        [lvvController.navigationController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"Call Hangup");
            [self stopDisplay];
            lvvController = nil;
            [self returnCodeToListener];
            [lcController setCallStatus:CALL_STATUS_ENDING count:0];
            [lvvController.navigationController pushViewController:lcController animated:YES];
        }];
    }

    nHangup = cause;
    NSLog(@"Terminate Call");
    linphone_call_terminate(currentCall);
}

- (void)transferTo: (NSString *) to {
    linphone_call_transfer(currentCall, [to cStringUsingEncoding: NSUTF8StringEncoding]);
}

- (void)sendLinphoneDebug{
    if (currentCallData.log_enable) {
        if ([MFMailComposeViewController canSendMail]) {
            mailer = [[MFMailComposeViewController alloc] init];
            mailer.mailComposeDelegate = self;
            [mailer setSubject:@"Phemium VideoCall Log"];
            NSArray * toReceipents = [NSArray arrayWithObjects:currentCallData.to_email, nil];
            [mailer setToRecipients:toReceipents];
            NSData * exportFileData = [NSData dataWithContentsOfFile: [NSString stringWithFormat:@"%@/linphone1.log", logPath]];
            [mailer addAttachmentData:exportFileData mimeType:@"text/plain" fileName:@"linphone1.log"];
            NSString * emailBody = @"Linphone Log file attached";
            [mailer setMessageBody:emailBody isHTML:NO];
            [[self topViewController] presentViewController:mailer animated:YES completion:nil];
        }else{
            NSLog(@"Cannot send email");
        }

    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"Email was sent");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Email was saved");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Email was failed");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"Email was cancelled");
            break;
        default:
            break;
    }
    if (mailer != nil) {
        [mailer dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)switchCamera {
    const char *currentCam = linphone_core_get_video_device(theLinphoneCore);
    
    if (backCamId && strcmp(currentCam, frontCamId) == 0)
    {
        linphone_core_set_video_device(theLinphoneCore, backCamId);
    }
    else if (frontCamId && strcmp(currentCam, backCamId) == 0)
    {
        linphone_core_set_video_device(theLinphoneCore, frontCamId);
    }
    
    if (currentCall)
    {
        linphone_call_update(currentCall, NULL);
    }
}

- (void)resizePreviewVideoSize:(CGSize)previewViewFrameSize {
//    NSLog(@"resizePreviewVideoSize called. %f, %f", previewViewFrameSize.width, previewViewFrameSize.height);
//    linphone_core_set_preview_video_size(theLinphoneCore, ms_video_size_make(previewViewFrameSize.width, previewViewFrameSize.height));
//    if (currentCall) {
//        linphone_core_update_call(theLinphoneCore, currentCall, NULL);
//    }
}

- (void) scaleVideoTask
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 1 * NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   ^{
                       if ([self scaleVideo] == false) {
                           [self scaleVideoTask];
                       } else {
                           [self qualityLoop];
                           [self stopConnectingTimer];
                           [lcController onVideoCallConnected];
                           nCallStatus = CALL_STATUS_CONNECTED;
                           [self showVideoCallScreen];
                       }
                   });
}

- (BOOL)scaleVideo
{
    if( currentCall && (nCallStatus == CALL_STATUS_CONNECTING))
    {
        float x = 0.5;
        float y = 0.5;
        float zoomFactor = [self calculateZoomFactor];
        NSLog(@"zoomFactor: %f", zoomFactor);
        if (zoomFactor != 0 && zoomFactor != 1) {
            linphone_call_zoom_video(currentCall, zoomFactor, &x, &y);
            return true;
        }
        if (zoomFactor == 1) {
            return true;
        }
    }
    return false;
}

- (float)calculateZoomFactor
{
    MSVideoSize size = linphone_call_params_get_received_video_size(linphone_call_get_current_params(currentCall));
    
    NSLog(@"video size width: %d", size.width);
    
    // 0 means remote video is not measured yet
    if( size.width == 0 )
    {
        return 0;
    }
    
    float scaleFactor = 1;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat remoteDisplayWidth = screenRect.size.width;
    CGFloat remoteDisplayHeight;
    [self setNeedZoomMode];
    if (isNeedZoom) {
        remoteDisplayHeight = screenRect.size.height;
    }else{
        remoteDisplayHeight = remoteDisplayWidth / size.width * size.height;
    }
    
    float remoteDisplayRatio = remoteDisplayWidth / remoteDisplayHeight;
    
    float remoteVideoWidth = size.width;
    float remoteVideoHeight = size.height;
    
    // Get remote video ratio
    float remoteVideoRatio = remoteVideoWidth / remoteVideoHeight;
    
    if (remoteVideoRatio > remoteDisplayRatio) {
        scaleFactor = 1 / (1 - ((remoteDisplayHeight - (remoteDisplayWidth / remoteVideoRatio)) / remoteDisplayHeight));
    } else if (remoteVideoRatio < remoteDisplayRatio) {
        scaleFactor = 1 / (1 - ((remoteDisplayWidth - (remoteDisplayHeight * remoteVideoRatio)) / remoteDisplayWidth));
    }
    
    return scaleFactor;
    
}

-(void) setNeedZoomMode
{
    NSString * zoomMode = currentCallData.zoom_mode;
    if ([zoomMode isEqualToString:@"zoom"]) {
        isNeedZoom = YES;
    } else {
        isNeedZoom = NO;
    }
}

- (void)accept
{
    linphone_call_accept(currentCall);
    [self showPlayer];
}


- (void)muteCamera: (void (^)(BOOL)) callback {
    if (!currentCall) {
//        return NO;
        callback(NO);
    }
    
    bool_t isEnabled = linphone_call_camera_enabled(currentCall);
    linphone_call_enable_camera(currentCall, (bool_t) !isEnabled);
    
    NSString * logString = @"";
    if (isEnabled) {
        linphone_call_update(currentCall, NULL);
        callback((!isEnabled) ? NO : YES);
        [self.listener onCallEventOccur:CALL_EVENT_CAMERA_MUTED];
        
        logString = [NSString stringWithFormat:@"Event: %@" , @"User muted Camera"];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            linphone_call_update(currentCall, NULL);
            dispatch_async(dispatch_get_main_queue(), ^{
                callback((!isEnabled) ? NO : YES);

                [self.listener onCallEventOccur:CALL_EVENT_CAMERA_UNMUTED];
            });
        });
        logString = [NSString stringWithFormat:@"Event: %@" , @"User unmuted Camera"];
    }
    
    [self insertLogString:logString];
}


- (BOOL) isCameraMuted
{
    if (!currentCall) {
        return NO;
    }
    
    return linphone_call_camera_enabled(currentCall) ? NO : YES;
}

 - (BOOL)resignActive {
     if (theLinphoneCore == NULL) {
         return YES;
     }
    linphone_core_stop_dtmf_stream(theLinphoneCore);
    return YES;
}

- (void)enableProxyPublish:(BOOL)enabled {
    if (linphone_core_get_global_state(theLinphoneCore) != LinphoneGlobalOn) {
        NSLog(@"Not changing presence configuration because linphone core not ready yet");
        return;
    }
        const MSList *proxies = linphone_core_get_proxy_config_list(theLinphoneCore);
        while (proxies) {
            LinphoneProxyConfig *cfg = proxies->data;
            linphone_proxy_config_edit(cfg);
            linphone_proxy_config_enable_publish(cfg, enabled);
            linphone_proxy_config_done(cfg);
            proxies = proxies->next;
        }
        // force registration update first, then update friend list subscription
        linphone_core_iterate(theLinphoneCore);
}

- (BOOL)enterBackgroundMode {
    if (theLinphoneCore == NULL) {
        return YES;
    }
    LinphoneProxyConfig *proxyCfg = linphone_core_get_default_proxy_config(theLinphoneCore);
    
    BOOL shouldEnterBgMode = FALSE;
    // disable presence
    [self enableProxyPublish:NO];
    
    // handle proxy config if any
    if (proxyCfg) {
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                // For registration register
                [self refreshRegisters];
            }
    }
    
    /*stop the video preview*/
    if (theLinphoneCore) {
        linphone_core_enable_video_preview(theLinphoneCore, FALSE);
        linphone_core_iterate(theLinphoneCore);
    }
    linphone_core_stop_dtmf_stream(theLinphoneCore);
    return YES;
}

- (void)becomeActive {
    if (theLinphoneCore == NULL) {
        return;
    }
    // enable presence
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max || self->connectivity == none) {
        [self refreshRegisters];
    }
    
    /*IOS specific*/
    linphone_core_start_dtmf_stream(theLinphoneCore);
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted){
                             }];
    
    /*start the video preview in case we are in the main view*/
    linphone_core_enable_video_preview(theLinphoneCore, TRUE);
    [self enableProxyPublish:YES];
}

- (void)beginInterruption {
    LinphoneCall *c = linphone_core_get_current_call(theLinphoneCore);
    NSLog(@"Sound interruption detected!");
    if (c && linphone_call_get_state(c) == LinphoneCallStreamsRunning) {
//        speakerBeforePause = speakerEnabled;
        linphone_call_pause(c);
    }
}

- (void)endInterruption {
    NSLog(@"Sound interruption ended!");
}

- (void)refreshRegisters {
    if (connectivity == none) {
        // don't trust ios when he says there is no network. Create a new reachability context, the previous one might
        // be mis-functionning.
        NSLog(@"None connectivity");
        [self setupNetworkReachabilityCallback];
    }
    NSLog(@"Network reachability callback setup");
    if (theLinphoneCore != NULL) {
        linphone_core_refresh_registers(theLinphoneCore); // just to make sure REGISTRATION is up to date
    }
}

#pragma mark - Connecting Timer

- (void) startConnectingTimer {
    connectingTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_CONNECTING_TIMEOUT_SECONDS target:self selector:@selector(onConnectingTimeout) userInfo:nil repeats:NO];
}

- (void) onConnectingTimeout {
    if (nCallStatus == CALL_STATUS_CONNECTING) {
        
        NSString * logString = [NSString stringWithFormat:@"---%@" , @"Establishing Timeout..."];
        [self insertLogString:logString];
        
        NSLog(@"Connecting Timeout: %d", connect_failed_cnt);
        nErrorCode = CALL_ERROR_CALL_CONNECTING_FAILURE;
        connect_failed_cnt ++;
        isCallRetry = true;
        if (connect_failed_cnt > MAX_RETRY_COUNT) {
            isCallRetry = false;
            
        }
        
        if (isVideoCallConnecting) {
            [self hangupWithCause:CALL_HANGUP_BY_ERROR];
        }
    }

}

- (void) stopConnectingTimer {
    [connectingTimer invalidate];
    connectingTimer = nil;
    isVideoCallConnecting = NO;
}

#pragma mark - Callstate Changed Callback

- (void) check_call_state:(LinphoneCall*)call StateChanged:(LinphoneCallState)state withMessage:(const char *)message {

    NSString * logString = @"";
    switch (state)
    {
        case LinphoneCallIncomingReceived:
            if (currentCall != NULL) {
                linphone_call_terminate(call); //Reject if in call already
            } else {
                currentCall = call;
                NSString *remote = [NSString stringWithCString: linphone_call_get_remote_address_as_string(call) encoding: NSUTF8StringEncoding];
                [self.listener onIncomingCallFrom: remote];
            }
            break;
            
        case LinphoneCallOutgoingInit:
            NSLog(@"Linphone calling state: Outgoing Init");
            
            logString = [NSString stringWithFormat:@"---%@" , @"Connecting..."];
            [self insertLogString:logString];
        
            nCallStatus = CALL_STATUS_INIT;
            if (lcController != nil) {
                [lcController setCallStatus:nCallStatus count:0];
            }
            isVideoCallConnecting = NO;
            if (initTimer != nil) {
                [initTimer invalidate];
                initTimer = nil;
            }
            if (!isIncoming) {
                [self showCallingScreen]; 
            }
            ringTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_RING_TIMEOUT_SECONDS target:self selector:@selector(onRingTimeout) userInfo:nil repeats:NO];
            break;
            
        case LinphoneCallOutgoingRinging:
            NSLog(@"Linphone calling state: Outgoing Ring");
            
            if (ringTimer != nil) {
                [ringTimer invalidate];
                ringTimer = nil;
            }
            
            nCallStatus = CALL_STATUS_RINGING;
            [lcController setCallStatus:nCallStatus count:0];

            [self.listener onCallRinging];

            if (!isAudioCall) {
                [self setSpeakerEnabled: YES];
            }
            ringingTimer = [NSTimer scheduledTimerWithTimeInterval:CALL_RINGING_TIMEOUT_SECONDS target:self selector:@selector(onRingingTimeout) userInfo:nil repeats:NO];
            if (!isIncoming) {
                [self startRingSound];
            }
            break;
            
        case LinphoneCallConnected:
            NSLog(@"Linphone calling state: Call Connected");
            
            if (ringingTimer != nil) {
                [ringingTimer invalidate];
                ringingTimer = nil;
            }
            nCallStatus = CALL_STATUS_CONNECTING;
            [lcController setCallStatus:nCallStatus count:0];
            [self stopRingSound];
            
//            if (!isIncoming && currentCallUuid != nil && isCallKitNeeded) {
            if (currentCallUuid != nil && isCallKitNeeded) {
                [self.listener onCallConnectedWithPeer: currentCallUuid hasVideo:(!isAudioCall)];
            }
//            [self.listener onCallConnectedWithVideo:(!isAudioCall)];
            
            if (!isAudioCall) {
                
                logString = [NSString stringWithFormat:@"---%@" , @"Establishing Call..."];
                [self insertLogString:logString];
                
                
                isVideoCallConnecting = YES;
                [self startConnectingTimer];
                [self scaleVideoTask];
                if (!isIncoming) {
                    [self showConnectingScreen];
                }
            } else {
                [self qualityLoop];
                nCallStatus = CALL_STATUS_CONNECTED;
                [self startCallTimer];
                [self showAudioChattingScreen];
            }
            //linphone_call_start_recording(call);
            break;
            
        case LinphoneCallError:
            NSLog( @"Linphone calling state: Call end or error. Reason: %s", linphone_reason_to_string( linphone_call_get_reason(call) ) );
            
            switch ( linphone_call_get_reason(call) )
            {
                case LinphoneReasonNotAnswered:
                    nErrorCode = CALL_ERROR_WEB_USER_NOT_FOUND;
                    break;
                
                case LinphoneReasonDeclined:
                    nErrorCode = CALL_ERROR_DECLINED;
                    break;
                
                case LinphoneReasonNotFound:
                    nErrorCode = CALL_ERROR_WEB_USER_NOT_FOUND;
                    break;
                    
                case LinphoneReasonDoNotDisturb:
                    nErrorCode = CALL_ERROR_BUSY;
                    break;
                
                case LinphoneReasonBusy:
                    nErrorCode = CALL_ERROR_BUSY;
                    break;
                    
                case LinphoneReasonUnknown:
                    nErrorCode = CALL_ERROR_CALLEE_NOT_EXIST;
                    break;
                case LinphoneReasonTemporarilyUnavailable:
                    nErrorCode = CALL_ERROR_WEB_USER_NOT_FOUND;
                    break;
                    
                default:
                    nErrorCode = CALL_ERROR_UNKNOWN;
                    break;
            }
            break;
            
        case LinphoneCallEnd:
//            [self fix_audio_on_call_end];
            linphone_core_stop_dtmf_stream(theLinphoneCore);
            [self endCall:call];
            [self doUnregister];
            break;
            
        case  LinphoneCallReleased:
            NSLog(@"Linphone calling state: Call Released. Error:%d", nErrorCode);
            
            //linphone_call_stop_recording(call);
            [self endCall:call];
            [self doUnregister];
            break;
            
        case LinphoneCallIdle:
        case LinphoneCallOutgoingProgress:
        case LinphoneCallOutgoingEarlyMedia:
        case LinphoneCallStreamsRunning:
        case LinphoneCallPausing:
        case LinphoneCallPaused:
        case LinphoneCallPausedByRemote:
        case LinphoneCallUpdatedByRemote:
        case LinphoneCallIncomingEarlyMedia:
        case LinphoneCallUpdating:
        case LinphoneCallResuming:
        case LinphoneCallRefered:
        case LinphoneCallEarlyUpdating:
        case LinphoneCallEarlyUpdatedByRemote:
            break;
    }
    
    logString = [NSString stringWithFormat:@"Server Response, message: %s, state: %d" , message, state];
    [self insertLogString:logString];
}

- (void) endCall:(LinphoneCall *)call {
    if (nCallStatus != CALL_STATUS_ENDED) {
        if (currentCall != nil && call == currentCall) {
            
            NSLog(@"Call is ended");
            [self stopAllTimer];
            
            [self insertLogString:qualityLog];
            
            NSString * logString = @"";
            NSString * message = @"";
            switch (nHangup) {
                case CALL_HANGUP_BY_ERROR:
                    message = @"Error occured";
                    break;
                case CALL_HANGUP_BY_CALLER:
                    message = @"Caller did hangup call";
                    break;
                default:
                    message = @"Callee did hangup call";
                    break;
            }
            nCallStatus = CALL_STATUS_ENDED;
            logString = [NSString stringWithFormat:@"Call Released. reason: %@" , message];
            [self insertLogString:logString];
            
            if (callStartTime != nil) {
                NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:callStartTime];
                long duration = lroundf( difference );
                int seconds = duration % 60;
                int minutes = duration / 60  % 60;
                int hours = (int)duration / 3600;
                
                logString = [NSString stringWithFormat:@"Call Duration: %dh %dm %ds" , hours, minutes, seconds];
                [self insertLogString:logString];
            }else{
                logString = [NSString stringWithFormat:@"Call Duration: %dh %dm %ds" , 0, 0, 0];
                [self insertLogString:logString];
            }
//            [[OverlayCreator instance] destroyOverlay];
            qualityCnt = 0;
            qualitySumof10 = 0;
            if (qualityScheduler != nil) {
                [qualityScheduler invalidate];
                qualityScheduler = nil;
            }
            callStartTime = nil;
            currentCall = nil;
            linphone_call_unref(call);
            [self stopRingSound];
//            [self doUnregister];
        }
    }
}
// Workaround to fix speaker error after the first call
- (void) fix_audio_on_call_end
{
    AVAudioSession* session = [AVAudioSession
                               sharedInstance];

    // Play music even in background and dont stop playing music
    // even another app starts playing sound
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                   error:NULL];

    [session setActive:YES error:NULL];
    
    
}

-(void)check_network_type{
}

- (void) check_registration_state: (LinphoneRegistrationState)state message: (const char*)message {
    NSString * logString = @"";
    logString = [NSString stringWithFormat:@"Server Response, message: %s state: %d" , message, state];
    [self insertLogString:logString];
    switch (state)
    {
        case LinphoneRegistrationOk:
            if(!is_regsiter_failed){
                is_regsiter_failed = false;
                if (registeringTimer != nil) {
                    [registeringTimer invalidate];
                    registeringTimer = nil;
                }
                regist_failed_cnt = 0;
                is_unregistering = false;
                [self.listener onRegisterSucceeded];
            }
            break;
            
        case LinphoneRegistrationFailed:
            if (!_isCalling) {
                regist_failed_cnt ++;
                if(regist_failed_cnt > MAX_FAILED_COUNT){
                    if (is_regsiter_failed) {
                        return;
                    }
                    is_regsiter_failed = true;
                    [self doUnregister];
                }
            }
            break;
        case LinphoneRegistrationCleared:
            if (is_unregister_failed) {
                return;
            }
            [self stopAllTimer];
            if (!_isCalling) {
                regist_retry_cnt ++;
                if (regist_retry_cnt < MAX_REGISTER_RETRY_COUNT) {
                    
                    [self enableLogCollection:YES];
                    NSString * logString = [NSString stringWithFormat:@"---%@" , @"Register Retrying"];
                    [self insertLogString:logString];
                    
                    [lcController setCallStatus:CALL_STATUS_RETRYING count:0];
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^{
                        NSLog(@"Regsiter Retrying...");
                        [self doRegister];
                    });
                }else{
                    regist_retry_cnt = 0;
                    nErrorCode = CALL_ERROR_REGISTER_FAILURE;
                    
                    if (registeringTimer != nil) {
                        [registeringTimer invalidate];
                        registeringTimer = nil;
                    }
                    
                    //originally [self returnCodeToListener], but in case of incoming simulation where connecting screen is shown up by default, we should dismiss that first, and then return code.
                    [self hideCallingScreen];
                }
            }else{
                if (!bHangupFromCXProvider && isCallKitNeeded) {
                    [self requestEndCallTransaction];
                } else {
                    bHangupFromCXProvider = NO;
                }
                
                [PublicData sharedInstance].callManager = nil;
                
                nHangup = CALL_HANGUP_BY_CALLEE;
                NSLog(@"call hang up by: %d", nHangup);
                if (!isCallRetry) {
                    connect_failed_cnt = 0;
                    [self hideCallingScreen];
                } else {
                    if (lcController != NULL) {
                        [lcController setCallStatus:CALL_STATUS_RETRYING count:0];
                    }
                    [self enableLogCollection:YES];
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10*NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^{
                        NSLog(@"Call Retry");
                        [self resetLinphoneCore];
                        isCallRetry = false;
                        [_listener onCallRetry];
                    });
                }
            }
            _isCalling = false;
            break;
        case LinphoneRegistrationNone:
//            if (_isCalling) {
//            
//            }else{
//                regist_retry_cnt = 0;
//                nErrorCode = CALL_ERROR_REGISTER_FAILURE;
//            
//                if (registeringTimer != nil) {
//                    [registeringTimer invalidate];
//                    registeringTimer = nil;
//                }
//                if (unregisteringTimer != nil) {
//                    [unregisteringTimer invalidate];
//                    unregisteringTimer = nil;
//                }
//            
//                //originally [self returnCodeToListener], but in case of incoming simulation where connecting screen is shown up by default, we should dismiss that first, and then return code.
//                [self hideCallingScreen];
//            }
            break;
        case LinphoneRegistrationProgress:
            break;
    }
}

- (void) checkCallAction
{
    LinphoneCall* call = linphone_core_get_current_call(theLinphoneCore);
    
    if( !call)
        return;
    
    linphone_call_accept(call);
    
}

#pragma mark - ringtone play

- (void)startRingSound {
    if (lcController != nil) {
        [lcController startRingtone];
    }
}

- (void)stopRingSound {
    if (lcController != nil) {
        [lcController stopRingtone];
    }
}

#pragma mark - switching screens

- (void)reOpen {
    badgeNum = 0;
    if(isAudioCall){
         [lcController showAudioCallConnected];
         navigationController = [[UINavigationController alloc] initWithRootViewController:lcController];
        [lcController clearBadge];
    }else{
        [self initController];
        navigationController = [[UINavigationController alloc] initWithRootViewController:lvvController];
        [lvvController clearBadge];
    }
    navigationController.navigationBarHidden = YES;
    navigationController.delegate = self;
    [[self topViewController] presentViewController:navigationController animated:YES completion:nil];
}

- (void)onChatMessageArrived {
    badgeNum ++;
    if(isAudioCall){
        [lcController startMessagetone];
        [lcController chatArrived];
    }else{
        [lvvController startMessagetone];
        [lvvController chatArrived];
    }
}

- (BOOL)isTopInitController {
    return [[self topViewController] isKindOfClass:[LinphoneInitViewController class]];
}

- (void)showCallingScreen {
    [self initConnectingViewController];
    if (isAudioCall) {
        lcController.bIsAudioCall = YES;
    } else {
        lcController.bIsAudioCall = NO;
    }
    
    if ([self isTopInitController]) {
        [lcController setIsLinking];
        [lcController refreshView];
    } else { // if top is MainViewController
        [lcController setIsLinking];
        [lcController refreshView];
        navigationController = [[UINavigationController alloc] initWithRootViewController:lcController];
        navigationController.navigationBarHidden = YES;
        navigationController.delegate = self;
        [[self topViewController] presentViewController:navigationController animated:YES completion:nil];
    }
}


- (void)showRegisteringScreen {
    [self initConnectingViewController];
    
    // test start
    //    UILocalNotification *notification1 = [[UILocalNotification alloc] init];
    //    notification1.alertBody = @"Test2";
    //    notification1.fireDate = [[[NSDate alloc] init] dateByAddingTimeInterval:5.0f];
    //    notification1.category = NotificationCategoryIdent1;
    //
    //    [[UIApplication sharedApplication] scheduleLocalNotification:notification1];
    // test end
    [lcController setCallStatus:CALL_STATUS_REGISTERING count:0];
    if ([self isTopInitController]) {
        [lcController setIsConnecting];
        [lcController refreshView];
    } else if ([[self topViewController] isKindOfClass:[LinphoneVideoWindowViewController class]]) {
        NSLog(@"Top View Controller is LinphoneVideoWindowViewController.");
    } else {
        NSLog(@"showConnectingScreen called.");
        [lcController setIsConnecting];
        
        navigationController = [[UINavigationController alloc] initWithRootViewController:lcController];
        navigationController.navigationBarHidden = YES;
        navigationController.delegate = self;
        
        [[self topViewController] presentViewController:navigationController animated:YES completion:nil];
    }
}


- (void)showConnectingScreen {
    [self initConnectingViewController];
    
    // test start
//    UILocalNotification *notification1 = [[UILocalNotification alloc] init];
//    notification1.alertBody = @"Test2";
//    notification1.fireDate = [[[NSDate alloc] init] dateByAddingTimeInterval:5.0f];
//    notification1.category = NotificationCategoryIdent1;
//    
//    [[UIApplication sharedApplication] scheduleLocalNotification:notification1];
    // test end
    if ([self isTopInitController]) {
        [lcController setIsConnecting];
        [lcController refreshView];
    } else if ([[self topViewController] isKindOfClass:[LinphoneVideoWindowViewController class]]) {
        NSLog(@"Top View Controller is LinphoneVideoWindowViewController.");
    } else {
        NSLog(@"showConnectingScreen called.");
        [lcController setIsConnecting];
        [lcController refreshView];
        navigationController = [[UINavigationController alloc] initWithRootViewController:lcController];
        navigationController.navigationBarHidden = YES;
        navigationController.delegate = self;

        [[self topViewController] presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)showAudioChattingScreen {
    if ([self isTopInitController]) {
        [lcController showAudioCallConnected];
    }
}

- (void)showVideoCallScreen {
    [self initController];
    
    if ([self isTopInitController]) {
        [lcController.navigationController pushViewController:lvvController animated:YES];
        [self startCallTimer];
    }
}

- (void)hideConnectingScreen {
    
}

- (void)hideCallingScreen {
    NSLog(@"Hiding Linphone Video Chatting Screen.");
    [self stopAllTimer];
    UIViewController *topController = [self topViewController];
    [self stopDisplay];
    if ([topController isKindOfClass:[LinphoneVideoWindowViewController class]]) {
        [lvvController.navigationController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"Stop Display");
            lcController = nil;
            lvvController = nil;
            [self returnCodeToListener];
        }];
    } else if ([topController isKindOfClass:[LinphoneInitViewController class]]) {
        [lcController.navigationController dismissViewControllerAnimated:YES completion:^{
            NSLog(@"Stop Display");
            lcController = nil;
            lvvController = nil;
            [self returnCodeToListener];
        }];
    } else {
        [self returnCodeToListener];
    }
}

- (UIViewController *)getMainViewController {
    return ((AppDelegate*)[UIApplication sharedApplication].delegate).window.rootViewController;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[LinphoneVideoWindowViewController class]]) {
        NSLog(@"Calling LinphoneVideoWindowController showConnected function");
        LinphoneVideoWindowViewController *videoWindowViewController = (LinphoneVideoWindowViewController *)viewController;
        [videoWindowViewController showConnected];
    }
}

#pragma mark - return code to listener
- (void)returnCodeToListener {
    if(isCallRetry){
        return;
    }

    if (isVideoCallConnecting) {
        // Video Connecting timeout error.
        NSLog(@"call connecting timeout");
        [self.listener onCallFailed: CALL_ERROR_CALL_CONNECTING_FAILURE workflow:logsStatus];
    } else {
        if (nErrorCode == CALL_NO_ERROR) {
            [self.listener onCallReleased: logsStatus];
        } else {
            [self.listener onCallFailed: nErrorCode workflow:logsStatus];
        }
    }
}


- (void)startCallTimer {
    NSString * message = @"";
    if (isAudioCall) {
        message = @"Doing an Audio Call";
    }else{
        message = @"Doing a Video Call";
    }
    
    NSString * logString = [NSString stringWithFormat:@"---%@" , message];
    [self insertLogString:logString];
    
    if (callTimer) {
        [self stopCallTimer];
    }
    callStartTime = [NSDate date];
    
    callTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(increaseTimerCount:) userInfo:callStartTime repeats: YES];
   
    [callTimer fire];
}


- (void)stopCallTimer {
    if (callTimer) {
        [callTimer invalidate];
        callTimer = nil;
    }
}

- (void)stopRingTimer {
    if (ringTimer) {
        [ringTimer invalidate];
        ringTimer = nil;
    }
}

- (void)stopRingingTimer {
    if (ringingTimer) {
        [ringingTimer invalidate];
        ringingTimer = nil;
    }
}

- (void)stopInitTimer {
    if (initTimer) {
        [initTimer invalidate];
        initTimer = nil;
    }
}

- (void)stopUnregisteringTimer {
    if (unregisteringTimer) {
        [unregisteringTimer invalidate];
        unregisteringTimer = nil;
    }
}

- (void)stopAllTimer {
    [self stopInitTimer];
    [self stopRingTimer];
    [self stopRingingTimer];
    [self stopConnectingTimer];
    [self stopCallTimer];
    [self stopUnregisteringTimer];
}

- (void)increaseTimerCount : (NSTimer *) timer{
    
    NSDate *callStartTime = [timer userInfo];
    if(isAudioCall){
        [lcController increaseTimerCount: callStartTime];
    }else{
        [lvvController increaseTimerCount:callStartTime];
    }
}

#pragma mark - Network Functions

- (SCNetworkReachabilityRef)getProxyReachability {
    return proxyReachability;
}

+ (void)kickOffNetworkConnection {
    static BOOL in_progress = FALSE;
    if (in_progress) {
        NSLog(@"Connection kickoff already in progress");
        return;
    }
    in_progress = TRUE;
    /* start a new thread to avoid blocking the main ui in case of peer host failure */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static int sleep_us = 10000;
        static int timeout_s = 5;
        BOOL timeout_reached = FALSE;
        int loop = 0;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) @"192.168.0.200" /*"linphone.org"*/, 15000, nil,
                                           &writeStream);
        BOOL res = CFWriteStreamOpen(writeStream);
        const char *buff = "hello";
        NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval loop_time;
        
        if (res == FALSE) {
            NSLog(@"Could not open write stream, backing off");
            CFRelease(writeStream);
            in_progress = FALSE;
            return;
        }
        
        // check stream status and handle timeout
        CFStreamStatus status = CFWriteStreamGetStatus(writeStream);
        while (status != kCFStreamStatusOpen && status != kCFStreamStatusError) {
            usleep(sleep_us);
            status = CFWriteStreamGetStatus(writeStream);
            loop_time = [[NSDate date] timeIntervalSince1970];
            if (loop_time - start >= timeout_s) {
                timeout_reached = TRUE;
                break;
            }
            loop++;
        }
        
        if (status == kCFStreamStatusOpen) {
            CFWriteStreamWrite(writeStream, (const UInt8 *)buff, strlen(buff));
        } else if (!timeout_reached) {
            CFErrorRef error = CFWriteStreamCopyError(writeStream);
            NSLog(@"CFStreamError: %@", error);
            CFRelease(error);
        } else if (timeout_reached) {
            NSLog(@"CFStream timeout reached");
        }
        CFWriteStreamClose(writeStream);
        CFRelease(writeStream);
        in_progress = FALSE;
    });
}

+ (NSString *)getCurrentWifiSSID {
#if TARGET_IPHONE_SIMULATOR
    return @"Sim_err_SSID_NotSupported";
#else
    NSString *data = nil;
    CFDictionaryRef dict = CNCopyCurrentNetworkInfo((CFStringRef) @"en0");
    if (dict) {
        NSLog(@"AP Wifi: %@", dict);
        data = [NSString stringWithString:(NSString *)CFDictionaryGetValue(dict, @"SSID")];
        CFRelease(dict);
    }
    return data;
#endif
}

static void showNetworkFlags(SCNetworkReachabilityFlags flags) {
    NSMutableString *log = [[NSMutableString alloc] initWithString:@"Network connection flags: "];
    if (flags == 0)
        [log appendString:@"no flags."];
    if (flags & kSCNetworkReachabilityFlagsTransientConnection)
        [log appendString:@"kSCNetworkReachabilityFlagsTransientConnection, "];
    if (flags & kSCNetworkReachabilityFlagsReachable)
        [log appendString:@"kSCNetworkReachabilityFlagsReachable, "];
    if (flags & kSCNetworkReachabilityFlagsConnectionRequired)
        [log appendString:@"kSCNetworkReachabilityFlagsConnectionRequired, "];
    if (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)
        [log appendString:@"kSCNetworkReachabilityFlagsConnectionOnTraffic, "];
    if (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)
        [log appendString:@"kSCNetworkReachabilityFlagsConnectionOnDemand, "];
    if (flags & kSCNetworkReachabilityFlagsIsLocalAddress)
        [log appendString:@"kSCNetworkReachabilityFlagsIsLocalAddress, "];
    if (flags & kSCNetworkReachabilityFlagsIsDirect)
        [log appendString:@"kSCNetworkReachabilityFlagsIsDirect, "];
    if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        [log appendString:@"kSCNetworkReachabilityFlagsIsWWAN, "];
    NSLog(@"%@", log);
}

//This callback keeps tracks of wifi SSID changes.
static void networkReachabilityNotification(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                            const void *object, CFDictionaryRef userInfo) {
    LinphoneManager *mgr = LinphoneManager.instance;
    SCNetworkReachabilityFlags flags;
    
    // for an unknown reason, we are receiving multiple time the notification, so
    // we will skip each time the SSID did not change
    NSString *newSSID = [LinphoneManager getCurrentWifiSSID];
    if ([newSSID compare:mgr.SSID] == NSOrderedSame)
        return;
    
    
    if (newSSID != Nil && newSSID.length > 0 && mgr.SSID != Nil && newSSID.length > 0){
        if (SCNetworkReachabilityGetFlags([mgr getProxyReachability], &flags)) {
            NSLog(@"Wifi SSID changed, resesting transports.");
            mgr->connectivity = none; //this will trigger a connectivity change in networkReachabilityCallback.
            networkReachabilityCallBack([mgr getProxyReachability], flags, nil);
        }
    }
    mgr.SSID = newSSID;
    
    
}

void networkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *nilCtx) {
    showNetworkFlags(flags);
    LinphoneManager *lm = LinphoneManager.instance;
    SCNetworkReachabilityFlags networkDownFlags = kSCNetworkReachabilityFlagsConnectionRequired |
    kSCNetworkReachabilityFlagsConnectionOnTraffic |
    kSCNetworkReachabilityFlagsConnectionOnDemand;
    
    if (theLinphoneCore != nil) {
        LinphoneProxyConfig *proxy = linphone_core_get_default_proxy_config(theLinphoneCore);
        
        struct NetworkReachabilityContext * ctx = nilCtx ? ((struct NetworkReachabilityContext *)nilCtx) : 0;
        if ((flags == 0) || (flags & networkDownFlags)) {
            linphone_core_set_network_reachable(theLinphoneCore, false);
            lm->connectivity = none;
            [LinphoneManager kickOffNetworkConnection];
        } else {
            Connectivity newConnectivity;
            BOOL isWifiOnly = false;
            if (!ctx || ctx->testWWan)
                newConnectivity = flags & kSCNetworkReachabilityFlagsIsWWAN ? wwan : wifi;
            else
                newConnectivity = wifi;
            
            if (newConnectivity == wwan && proxy && isWifiOnly &&
                (lm->connectivity == newConnectivity || lm->connectivity == none)) {
                linphone_proxy_config_expires(proxy, 0);
            } else if (proxy) {
                NSInteger defaultExpire = [lm lpConfigIntForKey:@"default_expires"];
                if (defaultExpire >= 0)
                    linphone_proxy_config_expires(proxy, (int)defaultExpire);
                // else keep default value from linphonecore
            }
            
            if (lm->connectivity != newConnectivity) {
                // connectivity has changed
                linphone_core_set_network_reachable(theLinphoneCore, false);
                if (newConnectivity == wwan && proxy && isWifiOnly) {
                    linphone_proxy_config_expires(proxy, 0);
                }
                linphone_core_set_network_reachable(theLinphoneCore, true);
                linphone_core_iterate(theLinphoneCore);
                NSLog(@"Network connectivity changed to type [%s]", (newConnectivity == wifi ? "wifi" : "wwan"));
                lm->connectivity = newConnectivity;
            }
        }
        if (ctx && ctx->networkStateChanged) {
            (*ctx->networkStateChanged)(lm->connectivity);
        }
    }
}

- (void)setupNetworkReachabilityCallback {
    SCNetworkReachabilityContext *ctx = NULL;
    // any internet cnx
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    if (proxyReachability) {
        NSLog(@"Cancelling old network reachability");
        SCNetworkReachabilityUnscheduleFromRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(proxyReachability);
        proxyReachability = nil;
    }
    
    // This notification is used to detect SSID change (switch of Wifi network). The ReachabilityCallback is
    // not triggered when switching between 2 private Wifi...
    // Since we cannot be sure we were already observer, remove ourself each time... to be improved
    _SSID = [LinphoneManager getCurrentWifiSSID];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),
                                       CFSTR("com.apple.system.config.network_change"), NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self),
                                    networkReachabilityNotification, CFSTR("com.apple.system.config.network_change"),
                                    NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    
    proxyReachability =
    SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    
    if (!SCNetworkReachabilitySetCallback(proxyReachability, (SCNetworkReachabilityCallBack)networkReachabilityCallBack,
                                          ctx)) {
        NSLog(@"Cannot register reachability cb: %s", SCErrorString(SCError()));
        return;
    }
    if (!SCNetworkReachabilityScheduleWithRunLoop(proxyReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
        NSLog(@"Cannot register schedule reachability cb: %s", SCErrorString(SCError()));
        return;
    }
    
    // this check is to know network connectivity right now without waiting for a change. Don'nt remove it unless you
    // have good reason. Jehan
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(proxyReachability, &flags)) {
        networkReachabilityCallBack(proxyReachability, flags, nil);
    }
}

- (NetworkType)network {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7) {
        UIApplication *app = [UIApplication sharedApplication];
        NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
        NSNumber *dataNetworkItemView = nil;
        
        for (id subview in subviews) {
            if ([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                dataNetworkItemView = subview;
                break;
            }
        }
        
        NSNumber * number = (NSNumber *)[dataNetworkItemView valueForKey:@"dataNetworkType"];
        return [number intValue];
    } else {
#pragma deploymate push "ignored-api-availability"
        CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
        NSString *currentRadio = info.currentRadioAccessTechnology;
        if ([currentRadio isEqualToString:CTRadioAccessTechnologyEdge]) {
            return network_2g;
        } else if ([currentRadio isEqualToString:CTRadioAccessTechnologyLTE]) {
            return network_4g;
        }
#pragma deploymate pop
        return network_3g;
    }
}

@end
