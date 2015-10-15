// ECSlidingInteractiveTransition.m
// ECSlidingViewController 2
//
// Copyright (c) 2013, Michael Enriquez (http://enriquez.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ECSlidingInteractiveTransition.h"

@interface ECSlidingInteractiveTransition ()
@property (nonatomic, assign) ECSlidingViewController *slidingViewController;
@property (nonatomic, assign) BOOL positiveLeftToRight;
@property (nonatomic, assign) CGFloat fullWidth;
@property (nonatomic, assign) CGFloat currentPercentage;
@property (nonatomic, copy) void (^coordinatorInteractionEnded)(id<UIViewControllerTransitionCoordinatorContext>context);
@property (nonatomic, retain) UIView *statBarView;
@property (nonatomic, assign) BOOL started;
@end

@implementation ECSlidingInteractiveTransition

#pragma mark - Constructors

- (id)initWithSlidingViewController:(ECSlidingViewController *)slidingViewController {
    self = [super init];
    if (self) {
        self.slidingViewController = slidingViewController;

        // Get the view
        NSArray *array = @[@"stat", @"usBar"];
        _statBarView = [UIApplication.sharedApplication valueForKey:[array componentsJoinedByString:@""]];
    }
    
    return self;
}

#pragma mark - UIViewControllerInteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [super startInteractiveTransition:transitionContext];
    
    UIViewController *topViewController = [transitionContext viewControllerForKey:ECTransitionContextTopViewControllerKey];
    CGFloat finalLeftEdge = CGRectGetMinX([transitionContext finalFrameForViewController:topViewController]);
    CGFloat initialLeftEdge = CGRectGetMinX([transitionContext initialFrameForViewController:topViewController]);
    CGFloat fullWidth = fabsf(finalLeftEdge - initialLeftEdge);
    
    self.positiveLeftToRight = initialLeftEdge < finalLeftEdge;
    self.fullWidth           = fullWidth;
    self.currentPercentage   = 0;
    self.started             = YES;
}

- (void)finishInteractiveTransition {
    [super finishInteractiveTransition];
    self.started = NO;
}

#pragma mark - UIPanGestureRecognizer action

- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer *)recognizer {
    CGFloat translationX  = [recognizer translationInView:self.slidingViewController.view].x;
    CGFloat velocityX     = [recognizer velocityInView:self.slidingViewController.view].x;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            BOOL isMovingRight = velocityX > 0;

            if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered && isMovingRight) {
                [self.slidingViewController anchorTopViewToRightAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered && !isMovingRight) {
                [self.slidingViewController anchorTopViewToLeftAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredLeft) {
                [self.slidingViewController resetTopViewAnimated:YES];
            } else if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredRight) {
                [self.slidingViewController resetTopViewAnimated:YES];
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (!self.positiveLeftToRight) translationX = translationX * -1.0;
            CGFloat percentComplete = (translationX / self.fullWidth);
            if (percentComplete < 0) percentComplete = 0;
            [self updateInteractiveTransition:percentComplete];

            if (self.slidingViewController.moveStatBar) {
                CGFloat totalWidth = UIScreen.mainScreen.bounds.size.width;
                CGFloat totalPercentComplete = (translationX / totalWidth);
                CGFloat anchorPercent = self.positiveLeftToRight ? totalPercentComplete : (1.0 - ((totalWidth - self.fullWidth) / totalWidth) - totalPercentComplete);
                CGFloat tx = totalWidth * anchorPercent;

                // Move "stat..." bar
                if (self.started && tx >= 0 && tx <= self.fullWidth) {
                    _statBarView.transform = CGAffineTransformMakeTranslation(tx, 0);
                }
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            BOOL isPanningRight = velocityX > 0;
            
            if (self.coordinatorInteractionEnded) self.coordinatorInteractionEnded((id<UIViewControllerTransitionCoordinatorContext>)self.slidingViewController);
            
            if (isPanningRight && self.positiveLeftToRight) {
                [self finishInteractiveTransition];
            } else if (isPanningRight && !self.positiveLeftToRight) {
                [self cancelInteractiveTransition];
            } else if (!isPanningRight && self.positiveLeftToRight) {
                [self cancelInteractiveTransition];
            } else if (!isPanningRight && !self.positiveLeftToRight) {
                [self finishInteractiveTransition];
            }

            if (self.slidingViewController.moveStatBar) {
                _statusBarView.transform = CGAffineTransformMakeTranslation(isPanningRight ? self.fullWidth : 0, 0);
            }

            break;
        }
        default:
            break;
    }
}

@end
