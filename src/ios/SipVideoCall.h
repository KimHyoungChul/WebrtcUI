
//
//  Bridge between Cordova/PhoneGap and Linphone
//

#import <Cordova/CDVPlugin.h>
#import "LinPhoneManager.h"
#import "CallManager.h"

@class CallData;
@class CallManager;

@interface SipVideoCall : CDVPlugin <CallManagerDelegate>

@property (nonatomic, copy) NSString *callbackID;
@property (nonatomic, copy) NSString *mediaPermissionsCallbackId;
@property (nonatomic, strong) CallManager *callManager;

- (void)load: (CDVInvokedUrlCommand*)command;
- (void)call: (CDVInvokedUrlCommand*)command;
- (void)incomingCall: (CDVInvokedUrlCommand*)command;

//reopen
- (void)reOpen: (CDVInvokedUrlCommand*)command;
- (void)hangUp: (CDVInvokedUrlCommand*)command;

- (void)onChatMessageArrived: (CDVInvokedUrlCommand*)command;
- (void)checkMediaPermissions: (CDVInvokedUrlCommand*)command;
@end
