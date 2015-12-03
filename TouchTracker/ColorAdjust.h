//
//  ColorAdjust.h
//  TouchTracker
//
//  Created by 郑克明 on 15/12/3.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorAdjust : NSObject

//根据传入角度(-180=>180),返回不同的颜色
+(UIColor *)makeUIColorFrom:(UIColor *)fColor to:(UIColor *)tColor forAngle:(float)angle;
@end
