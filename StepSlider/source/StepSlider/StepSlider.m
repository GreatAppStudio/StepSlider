//
//  StepSlider.m
//  StepSlider
//
//  Created by Nick on 10/15/15.
//  Copyright © 2015 spromicky. All rights reserved.
//

#import "StepSlider.h"
#import "TrackCircleView.h"

#define GENERATE_ACCESS(PROPERTY, LAYER_PROPERTY, TYPE, SETTER, GETTER, UPDATER) \
- (void)SETTER:(TYPE)PROPERTY { \
    if (LAYER_PROPERTY != PROPERTY) { \
        LAYER_PROPERTY = PROPERTY; \
        [self UPDATER]; \
    } \
} \
\
- (TYPE)GETTER { \
    return LAYER_PROPERTY; \
}

@interface StepSlider ()
{
    CAShapeLayer     *_trackLayer;
    CAShapeLayer     *_sliderCircleLayer;
    NSMutableArray   *_trackCirclesArray;
}

@end

@implementation StepSlider

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self generalSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self generalSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self generalSetup];
    }
    return self;
}

- (void)generalSetup
{
    _trackCirclesArray = [[NSMutableArray alloc] init];
    _trackLayer = [CAShapeLayer layer];
    _sliderCircleLayer = [CAShapeLayer layer];
    
    
    [self.layer addSublayer:_sliderCircleLayer];
    [self.layer addSublayer:_trackLayer];
    
    
    self.maxCount           = 4;
    self.index              = 2;
    self.trackHeight        = 4.f;
    self.trackCircleRadius  = 5.f;
    self.sliderCircleRadius = 12.5f;
    self.trackColor         = [UIColor colorWithWhite:0.41f alpha:1.f];
    self.sliderCircleColor  = [UIColor whiteColor];
    
    [self layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentFrame = CGRectMake([self maxRadius], 0.f, self.bounds.size.width - 2 * [self maxRadius], self.bounds.size.height);
    
    CGFloat stepWidth       = contentFrame.size.width / (self.maxCount - 1);
    CGFloat circleY         = contentFrame.size.height / 2.f - self.trackCircleRadius;
    CGFloat circleFrameSide = self.trackCircleRadius * 2.f;
    CGFloat sliderFrameSide = self.sliderCircleRadius * 2.f;
    
    _sliderCircleLayer.frame     = CGRectMake(0.f, 0.f, sliderFrameSide, sliderFrameSide);
    _sliderCircleLayer.path      = [UIBezierPath bezierPathWithRoundedRect:_sliderCircleLayer.bounds cornerRadius:sliderFrameSide / 2].CGPath;
    _sliderCircleLayer.lineWidth = 0.f;
    _sliderCircleLayer.fillColor = [self.sliderCircleColor CGColor];
    _sliderCircleLayer.position  = CGPointMake(contentFrame.origin.x + stepWidth * self.index , contentFrame.size.height / 2.f);
    
    
    _trackLayer.frame = CGRectMake(contentFrame.origin.x,
                                   (contentFrame.size.height - self.trackHeight) / 2.f,
                                   contentFrame.size.width,
                                   self.trackHeight);    
    _trackLayer.path            = [self fillingPath];
    _trackLayer.backgroundColor = [self.trackColor CGColor];
    _trackLayer.lineWidth       = 0.f;
    _trackLayer.fillColor       = [self.tintColor CGColor];

    
    if (_trackCirclesArray.count > self.maxCount) {
        NSArray *circlesToDelete = [_trackCirclesArray subarrayWithRange:NSMakeRange(self.maxCount - 1, _trackCirclesArray.count - self.maxCount)];
        
        for (TrackCircleView *trackCircle in circlesToDelete) {
            [trackCircle removeFromSuperview];
        }
    }
    
    for (NSUInteger i = 0; i < self.maxCount; i++) {
        TrackCircleView *trackCircle;
        
        if (i < _trackCirclesArray.count) {
            trackCircle = _trackCirclesArray[i];
        } else {
            trackCircle = [[TrackCircleView alloc] init];
            trackCircle.sliderView = self;
            
            [self addSubview:trackCircle];
            [_trackCirclesArray addObject:trackCircle];
        }
        
        CGFloat trackCircleX = stepWidth * i - self.trackCircleRadius;
        
        trackCircle.frame = CGRectMake(contentFrame.origin.x + trackCircleX, circleY, circleFrameSide, circleFrameSide);
        [trackCircle setNeedsDisplay];
    }
    
    [_sliderCircleLayer removeFromSuperlayer];
    [self.layer addSublayer:_sliderCircleLayer];
}

- (CGPathRef)fillingPath
{
    CGRect fillRect     = _trackLayer.bounds;
    fillRect.size.width = [self sliderPosition];
    
    return [UIBezierPath bezierPathWithRect:fillRect].CGPath;
}

- (CGFloat)maxRadius
{
    return fmaxf(self.trackCircleRadius, self.sliderCircleRadius);
}

- (CGFloat)sliderPosition
{
    return _sliderCircleLayer.position.x - [self maxRadius];
}

- (CGFloat)indexCalculate
{
    return [self sliderPosition] / (_trackLayer.bounds.size.width / (self.maxCount - 1));
}

#pragma mark - Touches

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    return CGRectContainsPoint(_sliderCircleLayer.frame, [touch locationInView:self]);
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGFloat maxRadius = fmaxf(self.trackCircleRadius, self.sliderCircleRadius);
    CGFloat position = [touch locationInView:self].x;
    CGFloat limitedPosition = fminf(fmaxf(position, maxRadius), self.bounds.size.width - maxRadius);
    
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    _sliderCircleLayer.position = CGPointMake(limitedPosition, _sliderCircleLayer.position.y);
    [CATransaction commit];
    
    _trackLayer.path = [self fillingPath];
    
    NSUInteger index = [self indexCalculate];
    if (_index != index) {
        for (TrackCircleView *trackCircle in _trackCirclesArray) {
            [trackCircle setNeedsDisplay];
        }
        _index = index;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.index = roundf([self indexCalculate]);
    [self setNeedsLayout];
}

#pragma mark - Access methods

- (void)setIndex:(NSUInteger)index
{
    if (_index != index) {
        _index = index;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
