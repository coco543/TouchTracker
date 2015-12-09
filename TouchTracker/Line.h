//
//  Line.h
//  TouchTracker
//
//  Created by 郑克明 on 15/12/2.
//  Copyright © 2015年 郑克明. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface Line : NSObject <NSCoding>

@property (nonatomic) CGPoint begin;
@property (nonatomic) CGPoint end;

//@property (nonatomic,strong) NSMutableArray *containingArray;

@end
