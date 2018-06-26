//
//  ControlContainerView.m
//  SipVideoPluginTest
//
//  Created by SCNDev1 on 12/21/16.
//
//

#import "ControlContainerView.h"

@implementation ControlContainerView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backButton.layer.cornerRadius = self.backButton.frame.size.width / 2;
    self.backButton.layer.shadowColor = [UIColor blackColor].CGColor;
    [self.backButton.layer setShadowOffset:CGSizeMake(1, 1)];
    [self.backButton.layer setShadowOpacity:0.2];
    
}

- (void)setBackColor:(UIColor *)backgroundColor {
    self.backButton.backgroundColor = backgroundColor;
}

- (void)setButtonState:(BUTTON_STATE)buttonState {
    switch(buttonState) {
        case CAMERA_NOT_ALLOWED:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-unmute-camera.png"]];
            self.userInteractionEnabled = NO;
            self.alpha = 0.5;
            [self.backButton setAlpha:0.5f];
            break;
        case CAMERA_MUTE:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-mute-camera.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            break;
        case CAMERA_MUTED:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-unmute-camera.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            break;
        case VOICE_MUTE:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-mute.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            break;
        case VOICE_MUTED:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-unmute.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            break;
        case SWITCH_CAMERA:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-switch-camera.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            [self.backButton setAlpha:1.0f];
            break;
        case SWITCH_CAMERA_NOT_ALLOWED:
            [self.buttonImage setImage:[UIImage imageNamed:@"videocall-switch-camera.png"]];
            self.userInteractionEnabled = NO;
            self.alpha = 0.5;
            [self.backButton setAlpha:0.5f];
            break;
        case END_CALL:
            [self.buttonImage setImage:[UIImage imageNamed:@"close.png"]];
            self.userInteractionEnabled = YES;
            self.alpha = 1;
            break;
        default:
            break;
    }
    self->_buttonState = buttonState;
}

@end
