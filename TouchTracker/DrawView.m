//
//  DrawView.m
//  TouchTracker
//
//  Created by 郑克明 on 15/12/2.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import "DrawView.h"
#import "Line.h"
#import "Round.h"
#import "ColorAdjust.h"

@interface DrawView()

@property (nonatomic,strong) Line *currentLine;
@property (nonatomic,strong) Round *currentRound;
@property (nonatomic,strong) NSMutableArray *finishedLines;
@property (nonatomic,strong) NSMutableArray *finishedRounds;

/*多点同时划线,要解决两个问题
 *1 要能同时保存多个触摸事件都应的起点位置
 *2 多个事件的终点和已经记录的起点要一一对应不能混淆
 */
@property (nonatomic,strong) NSMutableDictionary *linesProgress;
@property (nonatomic,strong) NSMutableDictionary *touchPoints;
@end

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        NSFileManager *fileMgr = [NSFileManager defaultManager];
//        [fileMgr removeItemAtPath:path error:nil];
        _finishedLines = [[NSMutableArray alloc] init];
        [self initOther];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        _finishedLines = [decoder decodeObjectForKey:@"finishedLines"];
        [self initOther];
    }
    return self;
}

- (void)initOther{
    _linesProgress = [[NSMutableDictionary alloc] init];
    _touchPoints = [[NSMutableDictionary alloc] init];
    _finishedRounds = [[NSMutableArray alloc] init];
    self.backgroundColor = [UIColor grayColor];
    self.multipleTouchEnabled = YES;
}
//序列化,反序列化
- (void)encodeWithCoder:(NSCoder *)encoder{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.finishedLines forKey:@"finishedLines"];
}

- (void)strokeLine:(Line *)line{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

-(void)strokeRound:(Round *)round{
    NSLog(@"Draw round:%@",round);
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    [bp addArcWithCenter:round.center radius:round.radius startAngle:0.0 endAngle:2*M_PI clockwise:YES];
    [bp stroke];
    
}

- (void)drawRect:(CGRect)rect{
//    已经绘制过的点用黑色画出
//    [[UIColor blackColor] set];
    for (Line *l in self.finishedLines) {
        //计算绘制线的弧度
        CGFloat angle = atan2( (l.end.y - l.begin.y), (l.end.x - l.begin.x));
        [[ColorAdjust makeUIColorFrom:[UIColor redColor] to:[UIColor greenColor] forAngle:angle] set];
        [self strokeLine:l];
    }
    for (Round *round in self.finishedRounds) {
        [self strokeRound:round];
    }
    
    if (self.linesProgress.count > 0) {
        [[UIColor redColor] set];
        for (NSValue *key in self.linesProgress) {
            [self strokeLine:self.linesProgress[key]];
        }
    }
    self.currentRound = [self makeRound];
    if (self.currentRound) {
        [self strokeRound:self.currentRound];
    }
//    if (self.currentLine) {
//        [[UIColor redColor] set];
//        [self strokeLine:self.currentLine];
//    }
//    [path addArcWithCenter:center radius:currentRadius startAngle:0.0 endAngle:2*M_PI clockwise:YES];
}

/**
 *  根据线的位置,返回一个以线段为对角线所在的正方形对应的内接圆的圆形和半径
 *
 *  @return Round *
 */
- (Round *)makeRound{
    if ([self.touchPoints count] !=2) {
        return nil;
    }
    NSArray *allKey = [self.touchPoints allKeys];
    NSValue *firstValue = self.touchPoints[allKey[0]];
    NSValue *secondValue = self.touchPoints[allKey[1]];
    CGPoint begin = [firstValue CGPointValue];
    CGPoint end = [secondValue CGPointValue];;
    CGFloat x1 = begin.x;
    CGFloat x2 = end.x;
    CGFloat y1 = begin.y;
    CGFloat y2 = end.y;
    CGFloat lienLength = sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
    CGFloat radius = lienLength/2.0 * sin(M_PI_4);
    CGFloat xFixed = 0;
    CGFloat yFixed = 0;
    
    //恢复圆心偏差,
    if (x2 < x1) {
        xFixed = x2;
    }else{
        xFixed = x1;
    }
    if (y2 < y1) {
        yFixed = y2;
    }else{
        yFixed = y1;
    }
    CGPoint center = CGPointMake( xFixed + fabs(x2-x1) / 2, yFixed + fabs(y2-y1) / 2 );
    Round *round = [[Round alloc] init];
    round.center = center;
    round.radius = radius;
    
    return round;
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //向控制台打印触摸事件
    NSLog(@"%@",NSStringFromSelector(_cmd));
    int touchsCount = 0;
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        Line *l = [[Line alloc] init];
        l.begin = location;
        l.end = location;
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesProgress[key] = l;
        
        if(touchsCount < 2){
            self.touchPoints[key] = [NSValue valueWithCGPoint:location];
        }
        if (touchsCount == 2) {
            NSLog(@"tow");
        }
        touchsCount++;
    }
//    UITouch *t = [touches anyObject];
//    CGPoint location = [t locationInView:self];
//    self.currentLine = [[Line alloc] init];
//    self.currentLine.begin = location;
//    self.currentLine.end = location;
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //向控制台打印触摸事件
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        Line *l = self.linesProgress[key];
        l.end = location;
        
        if ([[self.touchPoints allKeys] containsObject:key]) {
            self.touchPoints[key] = [NSValue valueWithCGPoint:location];
        }
    }
//    UITouch *t = [touches anyObject];
//    CGPoint location = [t locationInView:self];
//    self.currentLine.end = location;
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //向控制台打印触摸事件
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.finishedLines addObject:self.linesProgress[key]];
        [self.linesProgress removeObjectForKey:key];
        [self.touchPoints removeObjectForKey:key];
    }
    if (self.currentRound) {
        [self.finishedRounds addObject:self.currentRound];
        self.currentRound = nil;
    }
//    [self.finishedLines addObject:self.currentLine];
//    self.currentLine = nil;
    [self setNeedsDisplay];
    
}

//触摸突然被中断时.
-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //向控制台打印触摸事件
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.linesProgress removeObjectForKey:key];
        [self.touchPoints removeObjectForKey:key];
    }
    
}

@end

