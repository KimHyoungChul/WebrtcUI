//
//  EFSignalBarView.m
//  TestSignalBarView
//
//  Created by arnoldmac on 11/17/17.
//  Copyright © 2017 phemium. All rights reserved.
//

#import "EFSignalBarView.h"


@implementation EFSignalBarView

@synthesize firstSignalBarColor;
@synthesize secondSignalBarColor;
@synthesize thirdSignalBarColor;
@synthesize fourthSignalBarColor;
@synthesize fifthSignalBarColor;

@synthesize baseColor;
@synthesize lowSignalColor;
@synthesize moderateSignalColor;
@synthesize excellentSignalColor;

@synthesize signal;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(NSInteger) signal{
    return signal;
}

-(void) setSignal:(NSInteger)newValue{
    signal = newValue;
}

-(void) baseInit {
    firstSignalBarColor = [[UIColor alloc] init];
    secondSignalBarColor = [[UIColor alloc] init];
    thirdSignalBarColor = [[UIColor alloc] init];
    fourthSignalBarColor = [[UIColor alloc] init];
    fifthSignalBarColor = [[UIColor alloc] init];
    
    baseColor = [UIColor grayColor];
    lowSignalColor = [UIColor redColor];
    moderateSignalColor = [UIColor orangeColor];
    excellentSignalColor = [UIColor greenColor];
    
    [self addObserver:self forKeyPath:@"signal" options:NSKeyValueObservingOptionNew context:nil];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    NSLog(@"keypath %@ updated", keyPath);
    [self setNeedsDisplay];
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit];
    }
    return self;
}


-(void) drawRoundedRect: (CAShapeLayer * ) shapeLayer horizontalSpacing :(CGFloat) horizontalSpacing signalBar:(UIBezierPath *) signalBar  barColor: (UIColor *) barColor{
    [shapeLayer removeFromSuperlayer];
    shapeLayer.path = [signalBar CGPath];
    shapeLayer.strokeColor = [barColor CGColor];
    shapeLayer.lineWidth = horizontalSpacing * 0.5;
    shapeLayer.fillColor = [[UIColor blueColor] CGColor];
    shapeLayer.lineCap = kCALineCapRound;
    [shapeLayer removeFromSuperlayer];
    [self.layer addSublayer: shapeLayer];
}

-(void) drawRect:(CGRect)rect{
    int horizontalSpacing = [self bounds].size.width / 8;
    CGPoint firstStartPoint = CGPointMake(horizontalSpacing, [self bounds].size.height * 0.85);
    CGPoint secondStartPoint = CGPointMake(horizontalSpacing * 2 , [self bounds].size.height * 0.85);
    CGPoint thirdStartPoint = CGPointMake(horizontalSpacing * 3, [self bounds].size.height * 0.85);
    CGPoint fourthStartPoint = CGPointMake(horizontalSpacing * 4, [self bounds].size.height * 0.85);
    CGPoint fifthStartPoint = CGPointMake(horizontalSpacing * 5, [self bounds].size.height * 0.85);
    
    
    int verticalHeightIncrement = [self bounds].size.height;
    CGPoint firstEndPoint = CGPointMake(horizontalSpacing,  verticalHeightIncrement * 0.8);
    CGPoint secondEndPoint = CGPointMake(horizontalSpacing*2, verticalHeightIncrement*0.6);
    CGPoint thirdEndPoint = CGPointMake(horizontalSpacing*3, verticalHeightIncrement*0.4);
    CGPoint fourthEndPoint = CGPointMake(horizontalSpacing*4, verticalHeightIncrement*0.2);
    CGPoint fifthEndPoint = CGPointMake(horizontalSpacing*5, 0);
    
    UIBezierPath * firstSignalBar = [[UIBezierPath alloc] init];
    UIBezierPath * secondSignalBar = [[UIBezierPath alloc] init];
    UIBezierPath * thirdSignalBar = [[UIBezierPath alloc] init];
    UIBezierPath * fourthSignalBar = [[UIBezierPath alloc] init];
    UIBezierPath * fifthSignalBar = [[UIBezierPath alloc] init];
    
    [firstSignalBar moveToPoint:firstStartPoint];
    [firstSignalBar addLineToPoint:firstEndPoint];
    
    [secondSignalBar moveToPoint:secondStartPoint];
    [secondSignalBar addLineToPoint:secondEndPoint];
    
    [thirdSignalBar moveToPoint:thirdStartPoint];
    [thirdSignalBar addLineToPoint:thirdEndPoint];
    
    [fourthSignalBar moveToPoint:fourthStartPoint];
    [fourthSignalBar addLineToPoint:fourthEndPoint];
    
    [fifthSignalBar moveToPoint:fifthStartPoint];
    [fifthSignalBar addLineToPoint:fifthEndPoint];
    
    switch (signal) {
        case 5:
            firstSignalBarColor = excellentSignalColor;
            secondSignalBarColor = excellentSignalColor;
            thirdSignalBarColor = excellentSignalColor;
            fourthSignalBarColor = excellentSignalColor;
            fifthSignalBarColor = excellentSignalColor;
            break;
        case 4:
            firstSignalBarColor = moderateSignalColor;
            secondSignalBarColor = moderateSignalColor;
            thirdSignalBarColor = moderateSignalColor;
            fourthSignalBarColor = moderateSignalColor;
            fifthSignalBarColor = baseColor;
            break;
        case 3:
            firstSignalBarColor = moderateSignalColor;
            secondSignalBarColor = moderateSignalColor;
            thirdSignalBarColor = moderateSignalColor;
            fourthSignalBarColor = baseColor;
            fifthSignalBarColor = baseColor;
            break;
        case 2:
            firstSignalBarColor = lowSignalColor;
            secondSignalBarColor = lowSignalColor;
            thirdSignalBarColor = baseColor;
            fourthSignalBarColor = baseColor;
            fifthSignalBarColor = baseColor;
            break;
        case 1:
            firstSignalBarColor = lowSignalColor;
            secondSignalBarColor = baseColor;
            thirdSignalBarColor = baseColor;
            fourthSignalBarColor = baseColor;
            fifthSignalBarColor = baseColor;
            break;
        case 0:
            firstSignalBarColor = baseColor;
            secondSignalBarColor = baseColor;
            thirdSignalBarColor = baseColor;
            fourthSignalBarColor = baseColor;
            fifthSignalBarColor = baseColor;
            break;
        default:
            break;
    }
    
    CAShapeLayer * shapeLayer = [[CAShapeLayer alloc] init];
    [self drawRoundedRect:shapeLayer horizontalSpacing:horizontalSpacing signalBar:firstSignalBar barColor:firstSignalBarColor];
    
    CAShapeLayer * shapeLayer2 = [[CAShapeLayer alloc] init];
    [self drawRoundedRect:shapeLayer2 horizontalSpacing:horizontalSpacing signalBar:secondSignalBar barColor:secondSignalBarColor];
    
    CAShapeLayer * shapeLayer3 = [[CAShapeLayer alloc] init];
    [self drawRoundedRect:shapeLayer3 horizontalSpacing:horizontalSpacing signalBar:thirdSignalBar barColor:thirdSignalBarColor];
    
    CAShapeLayer * shapeLayer4 = [[CAShapeLayer alloc] init];
    [self drawRoundedRect:shapeLayer4 horizontalSpacing:horizontalSpacing signalBar:fourthSignalBar barColor:fourthSignalBarColor];
    
   CAShapeLayer * shapeLayer5 = [[CAShapeLayer alloc] init];
    [self drawRoundedRect:shapeLayer5 horizontalSpacing:horizontalSpacing signalBar:fifthSignalBar barColor:fifthSignalBarColor];
}

@end
