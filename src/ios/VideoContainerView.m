//
//  VideoContainerView.m
//  SipVideoPluginTest
//
//  Created by Tomasson on 12/19/16.
//
//

#import "VideoContainerView.h"

@implementation VideoContainerView

- (void) setupGradientLayer {
    CGRect frame = self.superview.frame;
    CAGradientLayer *gradient1 = [CAGradientLayer layer];
    gradient1.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height / 4);
    gradient1.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    gradient1.opacity = 1;
    [self.superview.layer addSublayer:gradient1];
    
    CAGradientLayer *gradient2 = [CAGradientLayer layer];
    gradient2.frame = CGRectMake(frame.origin.x, frame.size.height * 3.0 / 4, frame.size.width, frame.size.height / 4);
    gradient2.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] CGColor], nil];
    gradient2.opacity = 1;
    [self.superview.layer addSublayer:gradient2];
    
    self.gradient1 = gradient1;
    self.gradient2 = gradient2;
}

- (void)layoutSubviews {
    NSLog(@"setupGradientLayer called on VideoContainerView");
    [super layoutSubviews];
    
    if (self.gradient1 && self.gradient2) {
        CGRect frame = self.superview.frame;
        self.gradient1.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height / 4);
        self.gradient2.frame = CGRectMake(frame.origin.x, frame.size.height * 3.0 / 4, frame.size.width, frame.size.height / 4);
        
    }
    
    
}

@end
