
//
//  Bridge between Cordova/PhoneGap and Linphone
//

#import "SipVideoCall.h"
#import "CallData.h"
#import "Constant.h"
#import "CommonUtil.h"
#import "StringUtil.h"
#import "AppDelegate+callprovider.h"

#import <AVFoundation/AVFoundation.h>
#import "PublicData.h"
#import "ProviderDelegate.h"

@interface SipVideoCall() {
    bool checkCameraPermission;
}

@end

@implementation SipVideoCall

@synthesize callbackID = _callbackID;

- (void) pluginInitialize {
    NSLog(@"pluginInitialized");
    
}

- (void)load: (CDVInvokedUrlCommand*)command {
    // Save callback id
//    self.callbackID = command.callbackId;
    
    //Save parameters
    NSString *load_settings = [command.arguments objectAtIndex:0];
    NSString * app_name = [load_settings valueForKey:@"app_name"];
    AppDelegate *appDelegate = (AppDelegate*)([UIApplication sharedApplication].delegate);
    if (appDelegate.providerDelegate != nil) {
        return;
    }
    appDelegate.pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    appDelegate.pushRegistry.delegate = appDelegate;
    appDelegate.providerDelegate = [[ProviderDelegate alloc] initWithAppName:app_name];
    appDelegate.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)call: (CDVInvokedUrlCommand*)command {
    // Save callback id
    self.callbackID = command.callbackId;
    
    //Save call parameters
    NSString *to = [command.arguments objectAtIndex:0];
    NSString *credentials = [command.arguments objectAtIndex:1];
    NSString *settings = [command.arguments objectAtIndex:2];
    NSString *guiSettings = [command.arguments objectAtIndex:3];
    NSString *extraSettings = [command.arguments objectAtIndex:4];

    CallData *callData = [[CallData alloc] init];
    [callData setTo:to];
    [callData setCallSettingValues: settings];
    [callData setCredentialValues: credentials];
    [callData setGUISettings: guiSettings];
    [callData setExtraSettings: extraSettings];

    
    self.callManager = [[CallManager alloc] init];
    [self.callManager setIsIncoming:NO];
    [self.callManager startCall: callData callManagerDelegate:self];
}

- (void)checkNetworkStatus: (CDVInvokedUrlCommand*)command {
    // Save callback id
    self.callbackID = command.callbackId;
    
    //Save call parameters
    NSString *to = [command.arguments objectAtIndex:0];
    NSString *credentials = [command.arguments objectAtIndex:1];
    NSString *settings = [command.arguments objectAtIndex:2];
    NSString *guiSettings = [command.arguments objectAtIndex:3];
    NSString *extraSettings = [command.arguments objectAtIndex:4];
    
    CallData *callData = [[CallData alloc] init];
    [callData setTo:to];
    [callData setCallSettingValues: settings];
    [callData setCredentialValues: credentials];
    [callData setGUISettings: guiSettings];
    [callData setExtraSettings: extraSettings];
    
    
    self.callManager = [[CallManager alloc] init];
    [self.callManager checkNetworkStatus: callData callManagerDelegate:self];
}

- (void)reOpen: (CDVInvokedUrlCommand*)command {
    // Save callback id
    //self.callbackID = command.callbackId;
    
    if(!self.callManager){
         self.callManager = [[CallManager alloc] init];
    }
    
    [self.callManager reOpen];
    
    [PublicData sharedInstance].callManager = nil;
}

- (void)hangUp: (CDVInvokedUrlCommand*)command {
    // Save callback id
//    self.callbackID = command.callbackId;
    
//    [self.commandDelegate runInBackground:^{
        if(!self.callManager){
            self.callManager = [[CallManager alloc] init];
        }
        [self.callManager hangUp];
        
        [PublicData sharedInstance].callManager = nil;
//    }];
}

- (void)incomingCall: (CDVInvokedUrlCommand*)command {
    
    self.callbackID = command.callbackId;
    //Save call parameters
    NSString *to = [command.arguments objectAtIndex:0];
    NSString *credentials = [command.arguments objectAtIndex:1];
    NSString *settings = [command.arguments objectAtIndex:2];
    NSString *guiSettings = [command.arguments objectAtIndex:3];
    NSString *extraSettings = [command.arguments objectAtIndex:4];
    
    CallData *callData = [[CallData alloc] init];
    [callData setTo:to];
    [callData setCallSettingValues: settings];
    [callData setCredentialValues: credentials];
    [callData setGUISettings: guiSettings];
    [callData setExtraSettings: extraSettings];
    
    self.callManager = [[CallManager alloc] init];
//    if (callData.onlyAudioCall == 1) { //audio call
//        [self scheduleSimulatingIncomingCallForAudioNotification: callData];
//    } else {
//        [self scheduleSimulatingIncomingCallForVideoNotification: callData];
//    }
    [self.callManager setIsIncoming:YES];
    [self.callManager startCall: callData callManagerDelegate:self];
}

#pragma mark - CallManagerDelegate methods

- (void)onCallReleased : (NSString *) workflow logPath:(NSString *)logPath {
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:[NSNumber numberWithInt: 0] forKey:@"error_code"];
    [dictionary setValue:workflow forKey:@"workflow"];
    [dictionary setValue:logPath forKey:@"log_path"];
    [dictionary setValue:@"released" forKey:@"event"];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallback:@0];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

- (void)onThrowError: (int) errorCode workflow:(NSString *) workflow logPath:(NSString *)logPath{
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:[NSNumber numberWithInt: errorCode] forKey:@"error_code"];
    [dictionary setValue:workflow forKey:@"workflow"];
    [dictionary setValue:logPath forKey:@"log_path"];
//    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:errorCode];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

- (void)onEventComesUp: (int) eventCode {
    NSString *eventString = nil;
    switch (eventCode) {
        case CALL_EVENT_MICRO_MUTED:
            eventString = @"microMuted";
            break;
        case CALL_EVENT_MICRO_UNMUTED:
            eventString = @"microUnmuted";
            break;
        case CALL_EVENT_CAMERA_MUTED:
            eventString = @"cameraMuted";
            break;
        case CALL_EVENT_CAMERA_UNMUTED:
            eventString = @"cameraUnmuted";
            break;
        case MINIMIZE_VIDEO:
            eventString = @"minimized";
            [PublicData sharedInstance].callManager = self.callManager;
            break;
        default:
            break;
    }
    
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:[NSNumber numberWithInt: 0] forKey:@"error_code"];
    [dictionary setValue:@"" forKey:@"workflow"];
    [dictionary setValue:eventString forKey:@"event"];
//    
//    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
//    [pluginResult setKeepCallback:@1];
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

- (void)onMinimized: (long) duration {
    [PublicData sharedInstance].callManager = self.callManager;
    
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:[NSNumber numberWithInt: 0] forKey:@"error_code"];
    [dictionary setValue:@"" forKey:@"workflow"];
    [dictionary setValue:[NSString stringWithFormat: @"minimized:%ld", duration] forKey:@"event"];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallback:@1];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

-(void)onSendQuality:(NSString *)quality{
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:[NSNumber numberWithInt: 0] forKey:@"error_code"];
    [dictionary setValue:@"" forKey:@"workflow"]; 
    [dictionary setValue:quality forKey:@"quality"];
    [dictionary setValue:[NSString stringWithFormat: @"sendQuality"] forKey:@"event"];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallback:@1];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

- (void)onChatMessageArrived: (CDVInvokedUrlCommand*)command {
//    self.callbackID = command.callbackId;
    if(!self.callManager){
         self.callManager = [[CallManager alloc] init];
    }
    
    [self.callManager onChatMessageArrived];
}

- (void)checkMediaPermissions: (CDVInvokedUrlCommand*)command {
    // Save callback id
    self.mediaPermissionsCallbackId = command.callbackId;
    
    if (command.arguments.count == 0) {
        checkCameraPermission = NO;
    }else{
        NSString * permission = [command.arguments objectAtIndex:0];
        checkCameraPermission = NO;
        if ([permission isEqualToString:@"audio"]) {
            checkCameraPermission = NO;
        }if ([permission isEqualToString:@"audio+video"]) {
            checkCameraPermission = YES;
        }else{
            
        }
    }
    [self checkPermissions];
}

- (void)onCheckReleased: (bool) registable networkType:(NSString *) networkType bandwidth:(float) bandwidth{
    NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:(registable?@"true":@"false") forKey:@"registry_availiability"];
    [dictionary setValue:networkType forKey:@"coverage"];
    [dictionary setValue:[NSString stringWithFormat:@"%.2f", bandwidth] forKey:@"bandwidth"];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallback:@1];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackID];
}

- (void) checkPermissions {
    [self checkAudioPermission];
}

- (void) checkAudioPermission {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            // Will get here on both iOS 7 & 8 even though camera permissions weren't required
            // until iOS 8. So for iOS 7 permission will always be granted.
            if (granted) {
                [self checkVideoPermission];
            } else {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.mediaPermissionsCallbackId];
            }
        }];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.mediaPermissionsCallbackId];
    }
}

- (void) checkVideoPermission {
    if (!checkCameraPermission) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.mediaPermissionsCallbackId];
        return;

    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        // Will get here on both iOS 7 & 8 even though camera permissions weren't required
        // until iOS 8. So for iOS 7 permission will always be granted.
        if (granted) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.mediaPermissionsCallbackId];
        } else {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.mediaPermissionsCallbackId];
            
        }
    }];
}
@end
