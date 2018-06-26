//
//  LinphoneVideoWindowViewController.m
//  PhemiumApp
//

#import "LinphoneVideoWindowViewController.h"
#import "VideoContainerView.h"
#import "ControlContainerView.h"
#import "UIColor+Hex.h"
#import "StringUtil.h"
#import "Constant.h"

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>

@interface LinphoneVideoWindowViewController () {
    BOOL controlsVisible;
    NSTimer *delayHideControlsFirstTimeAfterAppear;
    NSTimer *delayHideControls;
    NSTimer *delayResizeLocalVideo;
    UISwipeGestureRecognizer *swipeGestureUp;
    UISwipeGestureRecognizer *swipeGestureDown;
    UISwipeGestureRecognizer *swipeGestureLeft;
    UISwipeGestureRecognizer *swipeGestureRight;
    
    UIPanGestureRecognizer * panRecognizer;
    
    NSInteger swipeWState, swipeHState;
    BOOL IsCameraPermissionChecked;
    BOOL IsMicrophonePermissionChecked;
    BOOL IsLocalVideoSmall;
    
    int badgeNum;
    
    BOOL IsSmallVideoSwipe;
    BOOL IsMovedUpOrDown;
    
    float swipe_time_up_down;
    float swipe_time_left_right;
    
    float firstX;
    float firstY;
}
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;
@end

@implementation LinphoneVideoWindowViewController

@synthesize containerView;
@synthesize controlsView;
@synthesize timeLabel;
@synthesize muteButtonContainer;
@synthesize muteCameraButtonContainer;
@synthesize switchCameraButtonContainer;
@synthesize closeButtonContainer;
@synthesize portraitView;
@synthesize remoteVideoView;
@synthesize messages = _messages;
@synthesize theLinphoneManager;
@synthesize imgViewDisabledOutputDevice1;
@synthesize imgViewDisabledOutputDevice2;

@synthesize constraintControlsContainer;
@synthesize bShowChatBtn;
@synthesize bZoomMode;

// @synthesize openControlsButton;
// @synthesize messageTextLabel;
// @synthesize modalImage;
// @synthesize qualityImage;
// @synthesize dismissModalButton;
// @synthesize messageView;

- (id)initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.userName = @"";
        self.displayButtonTime = 2.0f;
        self.mainColor = [UIColor colorWithCSS:@"0a79c7"];
        self.displayNameMode = @"atScreenTouch";
        self.fontColor = [UIColor whiteColor];
        self.fontSize = 17;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Keep screen on during call
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    swipeHState = UISwipeGestureRecognizerDirectionDown;
    swipeWState = UISwipeGestureRecognizerDirectionRight;
    
    //[self.portraitView viewWithTag: 1].layer.borderColor = [UIColor lightGrayColor].CGColor;
    //[self.portraitView viewWithTag: 1].layer.borderWidth = 1.0f;
    //[self.portraitView viewWithTag: 1].layer.cornerRadius = 2.0f;
    //[self.portraitView viewWithTag: 1].layer.masksToBounds = YES;
    
    controlsVisible = YES;
    
    IsCameraPermissionChecked = NO;
    IsMicrophonePermissionChecked = NO;
    IsLocalVideoSmall = YES;
    IsSmallVideoSwipe = NO;
    IsMovedUpOrDown = NO;
    
//    self.lbUserName.text = [NSString stringWithFormat:@"%@ %@ - %@", self.userName, [StringUtil localizedString:@"company_name"], [StringUtil localizedString: @"service_name"]];
    self.lbUserName.text = [NSString stringWithFormat:@"%@", self.userName];
    self.lbRecordingNotification.text = [StringUtil localizedString: @"recording_text"];
    UIFont *font = self.lbUserName.font;
    UIFontDescriptor * fontD = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold)];
    UIFontDescriptor * fontE = [font.fontDescriptor
                                fontDescriptorWithSymbolicTraits:(font.fontDescriptor.symbolicTraits & ~UIFontDescriptorTraitBold)];
    [self.lbUserName setFont:[UIFont fontWithDescriptor:fontD size:self.fontSize]];
    [self.timeLabel setFont:[UIFont fontWithDescriptor:fontE size:self.fontSize-FONT_SIZE_OFFSET_STATUS_LABEL]];
    [self.lbUserName setTextColor:self.fontColor];
    [self.timeLabel setTextColor:self.fontColor];
    
    [self.muteButtonContainer setBackColor:self.mainColor];
    [self.muteCameraButtonContainer setBackColor:self.mainColor];
    [self.switchCameraButtonContainer setBackColor: self.mainColor];
    [self.closeButtonContainer setBackColor:[UIColor redColor]];
    
    if ([self.displayNameMode isEqualToString:@"never"]) {
        [self.topView setHidden:YES];
    } else {
        [self.topView setHidden:NO];
    }
    if (self.bCallRecordingNotification == YES) {
        [self.recordView setHidden: NO];
    } else {
        [self.recordView setHidden: YES];
        self.constraintTopViewTop.constant = 30;
        [self.topView layoutIfNeeded];
    }
    
    // hide disabled output device status buttons
    [self.imgViewDisabledOutputDevice1 setHidden: YES];
    [self.imgViewDisabledOutputDevice2 setHidden: YES];
    
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateViewPosition:)];
    panRecognizer.minimumNumberOfTouches  = 1;
    panRecognizer.maximumNumberOfTouches = 1;
    [[self getSmallVideoView] addGestureRecognizer:panRecognizer];
    
//    swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
//    swipeGestureUp.direction = UISwipeGestureRecognizerDirectionUp;
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureUp];
//    
//    swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
//    swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown;
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureDown];
//    
//    swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
//    swipeGestureLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureLeft];
//    
//    swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
//    swipeGestureRight.direction = UISwipeGestureRecognizerDirectionRight;
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureRight];
    
    [self setupGradient];
    
    badgeNum = 0;
    
    if (badgeNum != 0) {
        self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d" , badgeNum];
        self.chatBtn.badgeBGColor = [UIColor redColor];
    }
    
    if (!bShowChatBtn) {
        self.chatBtn.hidden = YES;
    }
    
    [super updateViewConstraints];
    if (bZoomMode) {
        NSLog(@"Zoom Mode");
        [[self getLargeVideoView] setContentMode:UIViewContentModeScaleToFill];
        [[self getSmallVideoView] setContentMode:UIViewContentModeScaleAspectFill];
    }else{
        NSLog(@"Not Zoom Mode");
        [[self getLargeVideoView] setContentMode:UIViewContentModeScaleAspectFit];
        [[self getSmallVideoView] setContentMode:UIViewContentModeScaleAspectFit];
    }
    [[self getLargeVideoView] setNeedsDisplay];
    [[self getSmallVideoView] setNeedsDisplay];
    
    self.alertLabel.text = [StringUtil localizedString: @"low_signal_alert"];
    swipe_time_up_down = 0.6;
    swipe_time_left_right = 0.3;
    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                        name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

-(void) updateViewPosition: (UIPanGestureRecognizer *)recognizer
{
    [self.view bringSubviewToFront:recognizer.view];
    CGPoint translatedPoint = [recognizer translationInView:recognizer.view.superview];
    
    if (recognizer.state == UIGestureRecognizerStateBegan ) {
        NSLog(@"begin position");
        firstX = recognizer.view.center.x;
        firstY = recognizer.view.center.y;
    }
    
    translatedPoint = CGPointMake(recognizer.view.center.x + translatedPoint.x,
                                  recognizer.view.center.y + translatedPoint.y);
    [recognizer.view setCenter:translatedPoint];
    [recognizer setTranslation:CGPointZero inView:recognizer.view];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat delta_up, delta_left, delta_down, delta_right;
        if(controlsVisible){
            delta_down = 88;
        }else{
            delta_down = 8;
        }
        
        delta_right = 24;
        delta_left = delta_right;
        delta_up = self.topView.frame.origin.y + self.topView.frame.size.height + 12;
        float lastX, lastY;
        if (recognizer.view.center.x < self.view.frame.size.width / 2) {
            lastX = [self getSmallVideoView].frame.size.width / 2 + delta_left;
            swipeWState = UISwipeGestureRecognizerDirectionLeft;
        }else{
            lastX = self.view.frame.size.width - [self getSmallVideoView].frame.size.width / 2 - delta_right;
            swipeWState = UISwipeGestureRecognizerDirectionRight;
        }
        
        if (recognizer.view.center.y < self.view.frame.size.height / 2) {
            lastY = [self getSmallVideoView].frame.size.height / 2 + delta_up;
            swipeHState = UISwipeGestureRecognizerDirectionUp;
        }else{
            lastY = self.view.frame.size.height - [self getSmallVideoView].frame.size.height / 2 - delta_down;
            swipeHState = UISwipeGestureRecognizerDirectionDown;
        }
        
        translatedPoint = CGPointMake(lastX, lastY);
        [UIView animateWithDuration:0.5 delay:0.1 options:UIViewAnimationOptionCurveLinear animations:^{
            [recognizer.view setCenter:translatedPoint];
        } completion:^(BOOL finished) {
            
        }];
        
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
}

- (void) viewWillAppear: (BOOL) animated {
    [super viewWillAppear:animated];
    
    [[self.portraitView viewWithTag: 1] setHidden: NO];
    [[self getSmallVideoView].layer setBorderWidth:1];
    [[self getSmallVideoView].layer setBorderColor:[UIColor darkGrayColor].CGColor];
    timeLabel.text = @"00:00";
    
    if ([self checkedCameraPermission] == NO) {
        [muteCameraButtonContainer setButtonState: CAMERA_NOT_ALLOWED];
        
        [[self.portraitView viewWithTag: 1] setHidden: YES];
        [switchCameraButtonContainer setButtonState: SWITCH_CAMERA_NOT_ALLOWED];
    } else {
        // get capture device available formats: vga, 720p and etc
        [self setMuteCameraButtonState];
    }
    
    // change the state of mute button
    if ([self checkMicrophonePermission] == NO) {
    } else {
        [self setMuteButtonState];
    }
    
    // set resolution of the local video view
    if (self.localVideoSize.width != 0 && self.localVideoSize.height != 0) {
        CGRect frame = [self getSmallVideoView].frame;

        CGFloat w, h, tempW, tempH;
        tempH = 110;
        tempW = 100;
        if(tempH < frame.size.width) {
            if (CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)) {
                tempH = frame.size.width;
                tempW = frame.size.height;
            } else {
                tempH = frame.size.height;
                tempW = frame.size.width;
            }
        }
        w = self.localVideoSize.width * tempH / self.localVideoSize.height;
        h = tempH;
       
        [[self getSmallVideoView] setFrame:CGRectMake(frame.origin.x + frame.size.width - w, frame.origin.y + frame.size.height - h, w, h)];
        [[self getLargeVideoView] setFrame:self.view.frame];
    }
    
    UILongPressGestureRecognizer * singleTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleTap];
}

-(void) handleSingleTap: (UITapGestureRecognizer *) recognizer{
    LinphoneManager *linphoneManager = [LinphoneManager instance];
    [linphoneManager enableLogCollection : YES];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
//    [self setupGradient];
    //delayHideControlsFirstTimeAfterAppear = [NSTimer scheduledTimerWithTimeInterval:_displayButtonTime target:self selector:@selector(hideControlsAfterAppear) userInfo:nil repeats:NO];
    [self startDelayForHidingControls];
    
    //Added by super for Remove small view when reopen
//    [self setMuteCameraButtonState];
    if ([theLinphoneManager isCameraMuted]) {
        [[self getSmallVideoView] setHidden: YES];
    }
}

#pragma mark - Messagetone play

- (void)startMessagetone {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"incoming_chat" ofType:@"wav"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    AVAudioPlayer * avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    //    avAudioPlayer.delegate = self;
    if (error != nil) {
        NSLog(@"messagetone music load error");
    } else {
        if ([avAudioPlayer prepareToPlay]) {
            [avAudioPlayer play];
            NSLog(@"messagetone music playing");
        } else {
            NSLog(@"messagetone music play not ready");
        }
    }
}

- (void) hideControlsAfterAppear {
    [self startDelayForHidingControls];
}

- (void) animateHideRecordView {
    self.constraintTopViewTop.constant = 30;
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
    }];
}


- (void)orientationChanged:(NSNotification *)notification{
    // large video view
    [self getLargeVideoView].frame = self.view.frame;
    
    [self swipeSmallVideo:swipeHState];
    [self swipeSmallVideo:swipeWState];

    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        swipe_time_up_down = 0.6;
        swipe_time_left_right = 0.3;
    }
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        swipe_time_up_down = 0.3;
        swipe_time_left_right = 0.6;
    }

}

// This functions aren't needed any more.
/*
 - (void) resizeLocalVideo {
 [UIView beginAnimations: nil context: nil];
 [UIView setAnimationDelegate: self.portraitView];
 [UIView setAnimationDuration: 2];
 [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
 
 CGPoint oldCenter = [self.portraitView viewWithTag: 1].center;
 CGPoint newCenter;
 
 newCenter.x = oldCenter.x * 0.75;
 newCenter.y = oldCenter.y * 0.78;
 
 [self.portraitView viewWithTag: 1].transform = CGAffineTransformMakeScale(0.75, 0.75);
 [self.portraitView viewWithTag: 1].center = newCenter;
 
 [UIView commitAnimations];
 }*/

- (void) setupGradient {
    [remoteVideoView setupGradientLayer];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void) setMuteCameraButtonState {
    BOOL isCameraMuted = [[LinphoneManager instance] isCameraMuted];
    
    if (isCameraMuted) {
        [muteCameraButtonContainer setButtonState: CAMERA_MUTED];
        [switchCameraButtonContainer setButtonState: SWITCH_CAMERA_NOT_ALLOWED];
    } else {
        [muteCameraButtonContainer setButtonState: CAMERA_MUTE];
        // check status of back and front camera and set the background and userInteractionEnabled property
        [self setSwitchCameraButtonState];
    }
}
- (IBAction)goTextChat:(id)sender {
    [self.navigationController dismissViewControllerAnimated:true completion:^{
        [[LinphoneManager instance] minimizeVideo];
    }];
}

- (void) setMuteButtonState {
    BOOL isMuted = [[LinphoneManager instance] isMuted];
    
    [muteButtonContainer setButtonState: isMuted? VOICE_MUTED : VOICE_MUTE];
}

- (void) setSwitchCameraButtonState {
    if (theLinphoneManager.backCamId != nil && theLinphoneManager.frontCamId != nil) {
        [self.switchCameraButtonContainer setButtonState: SWITCH_CAMERA];
    } else {
        [self.switchCameraButtonContainer setButtonState: SWITCH_CAMERA_NOT_ALLOWED];
    }
}

- (void) swipeSmallVideo: (NSInteger) direction {
    
    IsSmallVideoSwipe = YES;
    
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector:@selector(animationStopped:finished:context:)];

    [UIView setAnimationDelay: 0.075];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
    
    CGFloat delta_up, delta_left, delta_down, delta_right;
    if(controlsVisible){
        delta_down = 88;
    }else{
        delta_down = 8;
    }
    
    delta_right = 24;
    delta_left = delta_right;
    delta_up = self.topView.frame.origin.y + self.topView.frame.size.height + 12;
    CGPoint oldCenter = [self getSmallVideoView].center;
    CGPoint newCenter;
    
    switch (direction) {
        case UISwipeGestureRecognizerDirectionUp:
            swipeHState = UISwipeGestureRecognizerDirectionUp;
            newCenter.y = [self getSmallVideoView].frame.size.height / 2 + delta_up;
            newCenter.x = oldCenter.x;
            
            [UIView setAnimationDuration: swipe_time_up_down];
            break;
        case UISwipeGestureRecognizerDirectionDown:
            swipeHState = UISwipeGestureRecognizerDirectionDown;
            newCenter.y = self.view.frame.size.height - [self getSmallVideoView].frame.size.height / 2 - delta_down;
            newCenter.x = oldCenter.x;
            
            [UIView setAnimationDuration: swipe_time_up_down];
            break;
        case UISwipeGestureRecognizerDirectionLeft:
            swipeWState = UISwipeGestureRecognizerDirectionLeft;
            newCenter.y = oldCenter.y;
            newCenter.x = [self getSmallVideoView].frame.size.width / 2 + delta_left;
            
            [UIView setAnimationDuration: swipe_time_left_right];
            break;
        case UISwipeGestureRecognizerDirectionRight:
            swipeWState = UISwipeGestureRecognizerDirectionRight;
            newCenter.y = oldCenter.y;
            newCenter.x = self.view.frame.size.width - [self getSmallVideoView].frame.size.width / 2 - delta_right;
        
            [UIView setAnimationDuration: swipe_time_left_right];
            break;
        default:
            newCenter.y = 435;
            newCenter.x = 260;
            break;
    }
    
    [self getSmallVideoView].center = newCenter;
    
    [UIView commitAnimations];
}

- (void) upLocalVideo: (BOOL) up {
    
    if(swipeHState == UISwipeGestureRecognizerDirectionUp){
        return;
    }
    
    if (IsSmallVideoSwipe) {
        IsMovedUpOrDown = YES;
        return;
    }
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationDelegate: self];

    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationDelay: 0.075];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
    
    CGPoint oldCenter = [self getSmallVideoView].center;
    CGPoint newCenter;
    int upDown = -80;
    
    if (!up) {
        upDown = 80;
    }
    
    newCenter.y = oldCenter.y + upDown;
    newCenter.x = oldCenter.x;
    
    [self getSmallVideoView].center = newCenter;
    
    [UIView commitAnimations];
}


-(void)animationStopped:(NSString * )animationID
               finished:(NSNumber *)finished
                context:(void *)context{
    IsSmallVideoSwipe = NO;
    if(IsMovedUpOrDown){
        if (controlsVisible) {
            [self upLocalVideo:YES];
        }else{
            [self upLocalVideo:NO];
        }
        IsMovedUpOrDown = NO;
    }
}

- (void)viewDidUnload {
    // Enable idle timer after call
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [self setContainerView: nil];
    [self setControlsView: nil];
    [self setTimeLabel: nil];
    [self setPortraitView: nil];
    
    [delayHideControls invalidate];
    [delayResizeLocalVideo invalidate];
    
    // [self setMessageView: nil];
    // [self setMessageTextLabel: nil];
    // [self setQualityImage: nil];
    // [self setOpenControlsButton: nil];
    // [self setDismissModalButton: nil];
    // [self setModalImage: nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotate {
    return YES;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {
    return YES;
}

- (BOOL)checkedCameraPermission {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        // do your logic
        return YES;
    } else if(authStatus == AVAuthorizationStatusDenied){
        // denied
    } else if(authStatus == AVAuthorizationStatusRestricted){
        // restricted, normally won't happen
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
    } else {
        // impossible, unknown authorization status
    }
    
    if (authStatus != AVAuthorizationStatusNotDetermined) {
        IsCameraPermissionChecked = YES;
    }
    return NO;
}

- (BOOL)checkMicrophonePermission {
    AVAudioSessionRecordPermission recordPermission = [AVAudioSession sharedInstance].recordPermission;
    if (recordPermission == AVAudioSessionRecordPermissionUndetermined) {
        
    } else if (recordPermission == AVAudioSessionRecordPermissionDenied) {
        
    } else if (recordPermission == AVAudioSessionRecordPermissionGranted) {
        return YES;
    }
    
    if (recordPermission != AVAudioSessionRecordPermissionUndetermined) {
        IsMicrophonePermissionChecked = YES;
    }
    return NO;
}



- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    /*
     CGPoint newCenter;
     
     switch (toInterfaceOrientation) {
     case UIInterfaceOrientationPortrait:
     [self.portraitView setTransform: CGAffineTransformMakeRotation(0)];
     newCenter.x = 100;
     newCenter.y = 100;
     break;
     case UIInterfaceOrientationPortraitUpsideDown:
     newCenter.x = 100;
     newCenter.y = 100;
     [self.portraitView setTransform: CGAffineTransformMakeRotation(M_PI)];
     break;
     case UIInterfaceOrientationLandscapeLeft:
     newCenter.x = 100;
     newCenter.y = 400;
     [self.portraitView setTransform: CGAffineTransformMakeRotation(-M_PI /                                                                          2)];
     break;
     case UIInterfaceOrientationLandscapeRight:
     newCenter.x = 800;
     newCenter.y = 400;
     [self.portraitView setTransform: CGAffineTransformMakeRotation(M_PI / 2)];
     break;
     }
     
     [self.portraitView viewWithTag: 1].center = newCenter;
     */
}


- (void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation)fromInterfaceOrientation {
    [self.theLinphoneManager orientationChangedTo: self.interfaceOrientation];
}


- (void) showRemoteHangup {
    [self finishCall];
    // [self fadeMessage: @"remote-hangup" during: 3 close: YES];
}


- (void) showConnected {
    [self.portraitView setHidden: NO];
    //  [self.view.window insertSubview: self.portraitView belowSubview: self.view];
    
    [self.theLinphoneManager startDisplayAtLocalview: [self.portraitView viewWithTag: 1] andRemoteView: [self.portraitView viewWithTag: 2]];
//    [self.theLinphoneManager orientationChangedTo: self.interfaceOrientation];
    // [self fadeMessage: @"connected" during: 1 close: NO];
//    [self startCallTimer];
}

-(void) updateCallStatus : (float) callQuality{
    NSLog(@"Average Quality: %f", callQuality);
    if (callQuality < 1) {
        [_alertMessage setAlpha:0.4];
    }else{
        [_alertMessage setAlpha:0.0];
    }
    [_signalBarView setSignal:((int)round(callQuality))];
}

- (void)increaseTimerCount : (NSDate *) callStartTime{
    NSTimeInterval difference = [[NSDate date] timeIntervalSinceDate:callStartTime];
    long seconds = lroundf( difference );
    if (seconds == 11) {
        [self.recordView setHidden: YES];
        if (self.bCallRecordingNotification == YES) {
            [self animateHideRecordView];
        }
    }
    
    if( difference > 3600 ) {
        self.timeLabel.text = [NSString stringWithFormat: @"%02ld:%02ld:%02ld", seconds / 3600, seconds / 60, seconds % 60];
    } else {
        self.timeLabel.text = [NSString stringWithFormat: @"%02ld:%02ld", seconds / 60, seconds % 60];
    }
}



#pragma mark - showing message on top
/*
 - (void) showRinging {
 [self fadeMessage: @"ringing" during: 3 close: NO];
 }
 
 
 - (void) showFailed {
 [self fadeMessage: @"call-failed" during: 5 close: YES];
 }
 
 
 - (void) showNoResponse {
 [self fadeMessage: @"no-response" during: 5 close: YES];
 }
 
 - (void) showDeclined {
 [self fadeMessage: @"call-declined" during: 5 close: YES];
 }
 
 
 - (void) showRejected {
 [self fadeMessage: @"call-rejected" during: 5 close: YES];
 }*/

// This function isn't needed any more.
/*
 - (void) updateQuality
 {
 float q = [[theLinphoneManager getCallQuality] floatValue];
 
 if (q <= 0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-1"]]];
 } else if (q > 0.0 && q <= 1.0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-1"]]];
 } else if (q > 1.0 && q <= 2.0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-2"]]];
 } else if (q > 2.0 && q <= 3.0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-3"]]];
 } else if (q > 3.0 && q <= 4.0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-4"]]];
 } else if (q > 4.0) {
 [self.qualityImage setImage: [UIImage imageNamed:[[self class] resolveImageResource:@"calidad-5"]]];
 }
 }
 */

/*
 - (IBAction)dismissButtonPressed: (id) sender {
 [theLinphoneManager hangup];
 [self finishCall];
 }
 */

#pragma mark - Control Button Action

- (IBAction)muteButtonPress: (id) sender {
    [theLinphoneManager mute];
    [self closeControls];
}

- (IBAction)muteCamButtonPress: (id) sender {
    if(!muteButtonContainer.userInteractionEnabled){
        return;
    }
    [theLinphoneManager muteCamera:^(BOOL bResult) {
        [self setMuteCameraButtonState];
        if (bResult) {
            [self checkDisabledOutputDevice];
            [[self getLocalVideoView] setHidden:YES];
            if ([[self getLargeVideoView] isEqual:[self getLocalVideoView]]) {
                [self switchVideoView];
            }
        } else {
            [self checkDisabledOutputDevice];
            [[self getLocalVideoView] setHidden:NO];
        }
    }];
    
    //    if ([theLinphoneManager muteCamera]) {
    //        [self.muteCameraButton setSelected: YES];
    //    } else {
    //        [self.muteCameraButton setSelected: NO];
    //    }
    [self closeControls];
}

- (IBAction)hangupPress: (id) sender {
    [theLinphoneManager hangupWithCause: CALL_HANGUP_BY_CALLER];
    [self finishCall];
}

- (IBAction)switchCameraPress: (id) sender {
    if(!switchCameraButtonContainer.userInteractionEnabled){
        return;
    }
    [theLinphoneManager switchCamera];
    [self closeControls];
}

/*
 - (void) fadeMessage: (NSString *) message during: (NSTimeInterval) duration close: (BOOL) close {
 if (self.messages && [self.messages valueForKey: message]) {
 self.messageTextLabel.text = [self.messages valueForKey: message];
 } else {
 self.messageTextLabel.text = "";
 }
 
 self.messageView.alpha = 0;
 self.messageView.hidden = NO;
 self.dismissModalButton.hidden = !close;
 UIImage *icon = [UIImage imageNamed: [[self class] resolveImageResource:message]];
 
 if (icon) {
 self.modalImage.image = icon;
 self.modalImage.hidden = NO;
 } else {
 self.modalImage.hidden = YES;
 }
 
 [UIView animateWithDuration: 1 animations:^{
 self.messageView.alpha = 1;
 } completion:^(BOOL finished) {
 if (!close) {
 [UIView animateWithDuration: duration animations:^{
 self.messageView.alpha = 0;
 } completion:^(BOOL finished) {
 [self.messageView setHidden: YES];
 }];
 }
 }];
 }*/

- (void) startDelayForHidingControls {
    if (delayHideControls) {
        [delayHideControls invalidate];
        delayHideControls = nil;
    }
    delayHideControls = [NSTimer scheduledTimerWithTimeInterval:self.displayButtonTime target: self selector: @selector(closeControls) userInfo: nil repeats: NO];
}

- (void) openControls {
    if (controlsVisible)
        return;
    
    [self upLocalVideo: YES];
    
    // CGPoint cvCenter = self.controlsView.center;
    // cvCenter.y -= height;
    
    // for moving up (not in requirement)
    // CGFloat height = self.controlsView.frame.size.height + 20;
    // constraintControlsContainer.constant = constraintControlsContainer.constant - height;
    [self.controlsView setAlpha: 0];
    [self.controlsView setHidden: NO];
    self.controlsView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration: 0.5 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
        // self.controlsView.center = cvCenter;
        // [self.view layoutIfNeeded];
        [self.controlsView setAlpha: 1.0];
        self.controlsView.userInteractionEnabled = YES;
    } completion:^(BOOL finished) {
    }];
    
    if ([self.displayNameMode isEqualToString:@"atScreenTouch"]) {
        [self.topView setAlpha: 0];
        [self.topView setHidden: NO];
        [UIView animateWithDuration: 0.5 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
            [self.topView setAlpha: 1.0];
        } completion:^(BOOL finished) {
        }];
    }
    
    controlsVisible = !controlsVisible;
    
    if (!IsCameraPermissionChecked) {
        BOOL b = [self checkedCameraPermission];
        if (b) {
            [self setMuteCameraButtonState];
            IsCameraPermissionChecked = YES;
            
            if (![theLinphoneManager isCameraMuted]) {
                [[self getLocalVideoView] setHidden: NO];
            }
        }
    }
    if (!IsMicrophonePermissionChecked) {
        BOOL b = [self checkMicrophonePermission];
        if (IsMicrophonePermissionChecked && b) {
            [self setMuteButtonState];
        }
    }
    
    // hide disabled output device status buttons
    [self.imgViewDisabledOutputDevice1 setHidden: YES];
    [self.imgViewDisabledOutputDevice2 setHidden: YES];
}

- (void) closeControls {
    if (delayHideControls) {
        [delayHideControls invalidate];
        delayHideControls = nil;
    }
    
    if (!controlsVisible)
        return;
    if (delayHideControlsFirstTimeAfterAppear) {
        [delayHideControlsFirstTimeAfterAppear invalidate];
        delayHideControlsFirstTimeAfterAppear = nil;
    }
    
    [self upLocalVideo: NO];
    
    // CGPoint cvCenter = self.controlsView.center;
    // cvCenter.y += height;
    
    // for moving down (not in requirement)
    // CGFloat height = self.controlsView.frame.size.height + 20;
    // constraintControlsContainer.constant = constraintControlsContainer.constant + height;
    
    self.controlsView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration: 0.5 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        // self.controlsView.center = cvCenter;
        // [self.view layoutIfNeeded];
        [self.controlsView setAlpha: 0.0f];
    } completion:^(BOOL finished) {
        [self.controlsView setHidden: YES];
        self.controlsView.userInteractionEnabled = YES;
        
        // show disabled output device status buttons
        [self.imgViewDisabledOutputDevice1 setHidden: NO];
        [self.imgViewDisabledOutputDevice2 setHidden: NO];
    }];
    
    if ([self.displayNameMode isEqualToString:@"atScreenTouch"]) {
        [UIView animateWithDuration: 0.5 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
            [self.topView setAlpha: 0.0];
        } completion:^(BOOL finished) {
        }];
    }
    
    controlsVisible = !controlsVisible;
    
    [self checkDisabledOutputDevice];
}

- (void) switchControls {
    if (controlsVisible) {
        [self closeControls];
    } else {
        [self openControls];
    }
}

- (void) checkDisabledOutputDevice {
    if (muteButtonContainer.buttonState == VOICE_MUTED) {
        [imgViewDisabledOutputDevice1 setImage:[UIImage imageNamed:@"status-muted.png"]];
        if (muteCameraButtonContainer.buttonState == CAMERA_MUTED || muteCameraButtonContainer.buttonState == CAMERA_NOT_ALLOWED) {
            [imgViewDisabledOutputDevice2 setImage:[UIImage imageNamed:@"status-muted-camera.png"]];
        } else {
            [imgViewDisabledOutputDevice2 setImage:nil];
        }
    } else {
        // check if camera is disabled
        if (muteCameraButtonContainer.buttonState == CAMERA_MUTED || muteCameraButtonContainer.buttonState == CAMERA_NOT_ALLOWED) {
            [imgViewDisabledOutputDevice1 setImage:[UIImage imageNamed:@"status-muted-camera.png"]];
            [imgViewDisabledOutputDevice2 setImage:nil];
        } else {
            [imgViewDisabledOutputDevice1 setImage:nil];
            [imgViewDisabledOutputDevice2 setImage:nil];
        }
    }
}

- (IBAction)openControlsClicked: (id) sender {
    [self switchControls];
}

/*
 - (IBAction)onSwipeUpRemote: (id) sender {
 [self openControls];
 }
 
 - (IBAction)onSwipeDown: (id) sender {
 [self closeControls];
 }
 
 - (IBAction)onSwipeUp: (id) sender {
 [self openControls];
 }*/

#pragma mark - View Tap Event Action

- (IBAction)onViewTapped:(UITapGestureRecognizer*)tapGestureRecognizer {
    CGPoint point = [tapGestureRecognizer locationInView:self.view];
    UIView *tappedView = [self.view hitTest:point withEvent:nil];
    UIView *smallVideoView = [self getSmallVideoView];
    
    if (tappedView == smallVideoView || tappedView.superview == smallVideoView) {
        /*CGSize targetVideoViewFrameSize = [self getRemoteVideoView].bounds.size;
         
         if ([view1 isEqual:[self getLocalVideoView]]) {
         [self.theLinphoneManager resizePreviewVideoSize: CGSizeMake(200, 100)];
         } else {
         [self.theLinphoneManager resizePreviewVideoSize: targetVideoViewFrameSize];
         }*/
        [self switchVideoView];
        return;
    }
    
    if (!controlsVisible) {
        [self openControls];
    } else {
        //[self startDelayForHidingControls];
        [self closeControls];
    }
}


- (void)swipeUp: (UIGestureRecognizer*)gestureRecognizer {
    [self swipeSmallVideo:UISwipeGestureRecognizerDirectionUp];
}

- (void)swipeDown: (UIGestureRecognizer*)gestureRecognizer {
    [self swipeSmallVideo:UISwipeGestureRecognizerDirectionDown];
}

- (void)swipeRight: (UIGestureRecognizer*)gestureRecognizer {
    [self swipeSmallVideo:UISwipeGestureRecognizerDirectionRight];
}

- (void)swipeLeft: (UIGestureRecognizer*)gestureRecognizer {
    [self swipeSmallVideo:UISwipeGestureRecognizerDirectionLeft];
}

- (void)switchVideoView {
    
//    [[self getSmallVideoView] removeGestureRecognizer:swipeGestureUp];
//    [[self getSmallVideoView] removeGestureRecognizer:swipeGestureDown];
//    [[self getSmallVideoView] removeGestureRecognizer:swipeGestureLeft];
//    [[self getSmallVideoView] removeGestureRecognizer:swipeGestureRight];
    
    [[self getSmallVideoView] removeGestureRecognizer:panRecognizer];
    
    UIView *view1 = [self getSmallVideoView];
    UIView *view2 = [self getLargeVideoView];
    
    [view1.layer setBorderWidth:0];
    [view2.layer setBorderWidth:1];
    [view2.layer setBorderColor:[UIColor darkGrayColor].CGColor];
    
    view2.frame = view1.frame;
    view1.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [self.portraitView bringSubviewToFront:view2];
    [self.portraitView sendSubviewToBack:view1];
    [UIView animateWithDuration:0.5f animations:^{
        view1.frame = self.view.frame;
    } completion:^(BOOL finished) {
        if (finished) {
            NSLog(@"expanding animation completed");
        }
    }];
    
    [[self getSmallVideoView] addGestureRecognizer:panRecognizer];
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureUp];
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureDown];
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureLeft];
//    [[self getSmallVideoView] addGestureRecognizer:swipeGestureRight];
    
}

#pragma mark - Get Video View Function

- (UIView *)getSmallVideoView {
    if ([self.portraitView.subviews objectAtIndex:1] == [self getLocalVideoView]) {
        return [self getLocalVideoView];
    } else {
        return [self getRemoteVideoView];
    }
}

- (UIView *)getLargeVideoView {
    if ([self.portraitView.subviews objectAtIndex:1] == [self getLocalVideoView]) {
        return [self getRemoteVideoView];
    } else {
        return [self getLocalVideoView];
    }
}

- (UIView *)getLocalVideoView {
    return [self.portraitView viewWithTag:1];
}

- (UIView *)getRemoteVideoView {
    return [self.portraitView viewWithTag:2];
}

- (void) finishCall {
    [self getLocalVideoView].hidden = YES;
//    [self stopCallTimer];
    // [self.portraitView viewWithTag:1].transform = CGAffineTransformMakeScale(1, 1);
}

+ (NSString*) resolveImageResource:(NSString*)resource {
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    BOOL isLessThaniOS4 = ([systemVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedAscending);
    
    if (isLessThaniOS4) {
        return [NSString stringWithFormat:@"%@.png", resource];
    } else {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.00) {
            return [NSString stringWithFormat:@"%@@2x.png", resource];
        }
    }
    
    return resource;//if all else fails
}

- (void)viewDidLayoutSubviews {
//    return;
    // large video view
    [self getLargeVideoView].frame = self.view.frame;
    
    // small video view
    CGRect smallVideoFrame = [self getSmallVideoView].frame;
    CGFloat endX = smallVideoFrame.origin.x + smallVideoFrame.size.width;
    CGFloat endY = smallVideoFrame.origin.y + smallVideoFrame.size.height;
    if (CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)) {
        if (smallVideoFrame.size.width > smallVideoFrame.size.height) {
            [[self getSmallVideoView] setFrame:CGRectMake(endX - smallVideoFrame.size.height, endY - smallVideoFrame.size.width, smallVideoFrame.size.height, smallVideoFrame.size.width)];
        }
    } else {
        if (smallVideoFrame.size.height > smallVideoFrame.size.width) {
            [[self getSmallVideoView] setFrame:CGRectMake(endX - smallVideoFrame.size.height, endY - smallVideoFrame.size.width, smallVideoFrame.size.height, smallVideoFrame.size.width)];
        }
    }
    
    
}

- (void)dealloc {
}

#pragma mark - Recording Relation
- (IBAction)onRecordingClose:(id)sender {
    self.recordView.hidden = YES;
    [self animateHideRecordView];
}

- (void) chatArrived{
    LinphoneManager * linphoneManager = [LinphoneManager instance];
    badgeNum = (int)linphoneManager.badgeNum;
    if (badgeNum != 0) {
        self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d" , badgeNum];
        self.chatBtn.badgeBGColor = [UIColor redColor];
    }else{
        [self clearBadge];
    }
}

- (void) clearBadge{
    badgeNum = 0;
    self.chatBtn.badgeValue = 0;
    self.chatBtn.badgeBGColor = [UIColor redColor];
}

- (void) updateDownloadBandwidth : (float) downloadBandwidth UploadBandwidth: (float) uploadBandwidth CallQuality: (float) callQuality{

}

@end
