//
//  ColorAdjust.m
//  TouchTracker
//
//  Created by 郑克明 on 15/12/3.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import "ColorAdjust.h"

@implementation ColorAdjust


+(UIColor *)makeUIColorFrom:(UIColor *)fColor to:(UIColor *)tColor forAngle:(CGFloat)angle {
    //弧度转角度
    angle = angle * 180 /M_PI;
    if (angle < 0) {
        angle = fabsf(angle) * 2;
    }
    if (angle > 360) {
        angle = 360;
    }
	CGColorRef fColorRef = fColor.CGColor;
    CGColorRef tColorRef = tColor.CGColor;
    
    CGFloat *fcomponents = (CGFloat *)CGColorGetComponents(fColorRef);
    CGFloat *tcomponents = (CGFloat *)CGColorGetComponents(tColorRef);
    CGFloat gradient[] = {0,0,0,0};
    
    gradient[0] = [ColorAdjust makeGradientFromValue:fcomponents[0] toValue:tcomponents[0] step:360 index:angle];
    gradient[1] = [ColorAdjust makeGradientFromValue:fcomponents[1] toValue:tcomponents[1] step:360 index:angle];
    gradient[2] = [ColorAdjust makeGradientFromValue:fcomponents[2] toValue:tcomponents[2] step:360 index:angle];
    gradient[3] = 1.0;
    UIColor *gradientUIColor = [[UIColor alloc] initWithCGColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), gradient)];
    
    return gradientUIColor;
}

/**
 *  生成均匀渐变值
 *
 *  @param valueA 起始值
 *  @param valueB 结束值
 *  @param step   渐变体积总数
 *  @param index  当前渐变位置
 *
 *  @return 渐变值
 */
+(CGFloat)makeGradientFromValue:(CGFloat)valueA toValue:(CGFloat)valueB step:(CGFloat)step index:(CGFloat)index{
    //优化运算速度,将除法后置
    return valueA + (valueB - valueA) * index /step;
}
@end
