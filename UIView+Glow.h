//
//  UIView+Glow.m
//
//  Created by Jon Manning on 29/05/12.
//  Copyright (c) 2012 Secret Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Glow)

@property (nonatomic, readonly) UIView* glowView;
@property (nonatomic, readonly) BOOL isGlowing;

// Fade up, then down.
- (void) glowForDuration:(int64_t)duration;

// Useful for indicating "this object should be over there"
- (void) glowOnceAtLocation:(CGPoint)point inView:(UIView*)view;

- (void) startGlowing;
- (void) startGlowingWithColor:(UIColor*)color intensity:(CGFloat)intensity;
- (void)startGlowingWithColor:(UIColor *)color intensity:(CGFloat)intensity duration:(float)duration;
- (void)startGlowingWithColor:(UIColor *)color intensity:(CGFloat)intensity duration:(float)duration repeat:(BOOL)repeat;
- (void) startGlowingWithColor:(UIColor*)color fromIntensity:(CGFloat)fromIntensity toIntensity:(CGFloat)toIntensity duration:(float)duration repeat:(BOOL)repeat;

- (void) removeGlow;
- (void) setGlow;
- (void) setGlowWithColor:(UIColor*)color;
- (void) setGlowWithColor:(UIColor*)color intensity:(float)intensity;


- (void) stopGlowing;
- (void) stopGlowingWithDuration:(float)duration;

@end
