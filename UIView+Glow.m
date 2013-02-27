//
//  UIView+Glow.m
//
//  Created by Jon Manning on 29/05/12.
//  Copyright (c) 2012 Secret Lab. All rights reserved.
//

#import "UIView+Glow.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// Used to identify the associating glowing view
static char* GLOWVIEW_KEY = "GLOWVIEW";

@implementation UIView (Glow)

// Get the glowing view attached to this one.
- (UIView*) glowView {
    return objc_getAssociatedObject(self, GLOWVIEW_KEY);
}

// Attach a view to this one, which we'll use as the glowing view.
- (void) setGlowView:(UIView*)glowView {
    objc_setAssociatedObject(self, GLOWVIEW_KEY, glowView, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL) isGlowing {
  return ([self glowView] ? YES : NO);
}

// The glow image is taken from the current view's appearance.
// As a side effect, if the view's content, size or shape changes,
// the glow won't update.
- (UIView*)createGlowView:(UIColor*)color {
  UIImage* image;
  
  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale); {
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    
    [color setFill];
    
    [path fillWithBlendMode:kCGBlendModeSourceAtop alpha:1.0];
    
    
    image = UIGraphicsGetImageFromCurrentImageContext();
  } UIGraphicsEndImageContext();
  
  
  // Make the glowing view itself, and position it at the same
  // point as ourself. Overlay it over ourself.
  UIView* glowView = [[UIImageView alloc] initWithImage:image];
  glowView.center = self.center;
  [self.superview insertSubview:glowView aboveSubview:self];
  
  // We don't want to show the image, but rather a shadow created by
  // Core Animation. By setting the shadow to white and the shadow radius to
  // something large, we get a pleasing glow.
  glowView.alpha = 0;
  glowView.layer.shadowColor = color.CGColor;
  glowView.layer.shadowOffset = CGSizeZero;
  glowView.layer.shadowRadius = 10;
  glowView.layer.shadowOpacity = 1.0;
  
  // Finally, keep a reference to this around so it can be removed later
  [self setGlowView:glowView];
  return glowView;
}

// Create a pulsing, glowing view based on this one.
- (void) startGlowing {
  [self startGlowingWithColor:[UIColor whiteColor] intensity:0.6];
}

- (void)startGlowingWithColor:(UIColor *)color intensity:(CGFloat)intensity {
    [self startGlowingWithColor:color intensity:intensity duration:0.3];
}

- (void)startGlowingWithColor:(UIColor *)color intensity:(CGFloat)intensity duration:(float)duration {
  [self startGlowingWithColor:color intensity:intensity duration:duration repeat:0];
}

- (void)startGlowingWithColor:(UIColor *)color intensity:(CGFloat)intensity duration:(float)duration repeat:(NSInteger)repeat {
  [self startGlowingWithColor:color fromIntensity:0 toIntensity:intensity duration:duration repeat:repeat];
}

- (void) startGlowingWithColor:(UIColor*)color fromIntensity:(CGFloat)fromIntensity toIntensity:(CGFloat)toIntensity duration:(float)duration repeat:(NSInteger)repeat {
  // If we're already glowing, don't bother
  if ([self glowView])
      return;

  if (repeat < 0) {
    repeat = HUGE_VALF;
  }
  UIView *glowView = [self createGlowView:color];
  BOOL reverse = repeat > 0;
  glowView.layer.opacity = (reverse ? fromIntensity : toIntensity);
  
  // Create an animation that slowly fades the glow view in and out forever.
  NSString *timingFuncName = (repeat ? kCAMediaTimingFunctionEaseInEaseOut : kCAMediaTimingFunctionEaseIn);
  CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.fromValue = @(fromIntensity);
  animation.toValue = @(toIntensity);
  animation.repeatCount = repeat;
  animation.duration = duration;
  animation.autoreverses = reverse;
  animation.timingFunction = [CAMediaTimingFunction functionWithName:timingFuncName];
  [CATransaction begin]; {
    [CATransaction setCompletionBlock:^(void){
      [self removeGlow];
    }];
    [glowView.layer addAnimation:animation forKey:@"pulse"];
  } [CATransaction commit];
}


- (void) stopGlowing {
  [self stopGlowingWithDuration:0.3];
}

- (void) stopGlowingWithDuration:(float)duration {
  // Create an animation that slowly fades the glow view out.
  CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  if (self.glowView.layer.presentationLayer) {
    animation.fromValue = @([self.glowView.layer.presentationLayer opacity]);
  } else {
    animation.fromValue = @([self.glowView.layer opacity]);
  }
  animation.toValue = @(0);
  animation.duration = duration;
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  self.glowView.layer.opacity = 0;
  [CATransaction begin]; {
    [CATransaction setCompletionBlock:^(void){
      [self removeGlow];
    }];
     [self.glowView.layer removeAnimationForKey:@"pulse"];
     [self.glowView.layer addAnimation:animation forKey:@"fadeout"];
  } [CATransaction commit];
}

- (void) glowOnceAtLocation:(CGPoint)point inView:(UIView*)view {
    [self startGlowingWithColor:[UIColor whiteColor] fromIntensity:0 toIntensity:0.6 duration:1.0 repeat:YES];
    
    [self glowView].center = point;
    [view addSubview:[self glowView]];
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self removeGlow];
    });
}

- (void)glowForDuration:(int64_t)duration {
    [self startGlowingWithColor:[UIColor whiteColor] intensity:0.6 duration:0.3 repeat:NO];
  
    if (duration > 0) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,  duration * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self stopGlowing];
        });
    }
}

// Stop glowing by removing the glowing view from the superview
// and removing the association between it and this object.
- (void) removeGlow {
  [[self glowView] removeFromSuperview];
  [self.glowView.layer removeAllAnimations];
  [self setGlowView:nil];
}

- (void) setGlow {
  [self setGlowWithColor:[UIColor whiteColor]];
}

- (void) setGlowWithColor:(UIColor*)color {
  [self setGlowWithColor:color intensity:0.6];
}

- (void) setGlowWithColor:(UIColor*)color intensity:(float)intensity {
  if ([self glowView])
    return;
  UIView *glowView = [self createGlowView:color];
  glowView.layer.opacity = intensity;
}

@end
