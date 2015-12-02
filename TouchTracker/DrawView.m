//
//  DrawView.m
//  TouchTracker
//
//  Created by 郑克明 on 15/12/2.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import "DrawView.h"
#import "Line.h"

@interface DrawView()

@property (nonatomic,strong) Line *currentLine;
@property (nonatomic,strong) NSMutableArray *finishedLines;

@end

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
    }
    return self;
}

- (void)strokeLine:(Line *)line{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect{
    //已经绘制过的点用黑色画出
    [[UIColor blackColor] set];
    for (Line *l in self.finishedLines) {
        [self strokeLine:l];
    }
    if (self.currentLine) {
        [[UIColor redColor] set];
        [self strokeLine:self.currentLine];
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *t = [touches anyObject];
    CGPoint location = [t locationInView:self];
    self.currentLine = [[Line alloc] init];
    self.currentLine.begin = location;
    self.currentLine.end = location;
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *t = [touches anyObject];
    CGPoint location = [t locationInView:self];
    self.currentLine.end = location;
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.finishedLines addObject:self.currentLine];
    self.currentLine = nil;
    [self setNeedsDisplay];
}

@end
