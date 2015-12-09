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


@interface DrawView() <UIGestureRecognizerDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) Line *currentLine;
@property (nonatomic,weak) Line *selectedLine;
@property (nonatomic,strong) Round *currentRound;
@property (nonatomic,strong) NSMutableArray *finishedLines;
@property (nonatomic,strong) NSMutableArray *finishedRounds;
@property (nonatomic,strong) UIPanGestureRecognizer *moveRecognizer;

/*多点画图,要解决两个问题
 *1 要能同时保存多个触摸事件都应的起点位置
 *2 多个事件的终点和已经记录的起点要一一对应不能混淆
 */
@property (nonatomic,strong) NSMutableDictionary *linesProgress;
@property (nonatomic,strong) NSMutableDictionary *touchPoints;

@property (nonatomic) CGFloat lineBezierPathWidth;
@end

@implementation DrawView

#pragma mark - 初始化
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
    //添加手势识别
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    //延迟touchsBegin事件,这样开始双击时才不会在第一击的时候触发该事件
    doubleTapRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:doubleTapRecognizer];
    
    //单击的时候并不会触发touchesBegan:withEvent等事件,所以也就不会在点击的时候出现一个点(极短的线)
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    //设置requireGestureRecognizerToFail:doubleTapRecognizer可以实现双击的时候不会在第一击触发单击手势
    //[tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [self addGestureRecognizer:tapRecognizer];
    
    //长按
    UILongPressGestureRecognizer *pressRecongnizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:pressRecongnizer];
    
    self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
    self.moveRecognizer.delegate = self;
    //设置成NO(默认是YES)之后,触摸事件被该手势识别对象识别后,视图还能继续收到触摸事件,例如此处是移动手势,则移动的时候还可以收到touchesBegan:withEvent:,touchesMoved:withEvent:,touchesEnded:withEvent:事件.所以下面代码如果去掉的话,则视图不会接受到这些消息,也就无法画出线了.
    self.moveRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_moveRecognizer];
    
    //三个手指向上
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [swipeRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
    swipeRecognizer.numberOfTouchesRequired  = 3;
    [self addGestureRecognizer:swipeRecognizer];
    
    _linesProgress = [[NSMutableDictionary alloc] init];
    _touchPoints = [[NSMutableDictionary alloc] init];
    _finishedRounds = [[NSMutableArray alloc] init];
    _lineBezierPathWidth = 10;
    self.backgroundColor = [UIColor grayColor];
    self.multipleTouchEnabled = YES;
}
//序列化,反序列化
- (void)encodeWithCoder:(NSCoder *)encoder{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.finishedLines forKey:@"finishedLines"];
}
#pragma mark - 处理手势委托

-(void)doubleTap:(UIGestureRecognizer *)gr{
    NSLog(@"Double tap");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"操作" message:@"是否清空所有线段?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
    [alertView show];
}

-(void)tap:(UIGestureRecognizer *)gr{
    NSLog(@"Single tap");
    
    CGPoint location = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:location];
    
    if (self.selectedLine) {
        
        [self becomeFirstResponder];
        //一个APP只能有一个UIMenuController
        UIMenuController *menu = [UIMenuController sharedMenuController];
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems = @[deleteItem];
        
        //设置菜单的显示区域
        [menu setTargetRect:CGRectMake(location.x, location.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }else{
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
}

/**
 *  长按开始,结束都会触发
 *
 *  @param gr 长按手势子对象
 */
-(void)longPress:(UIGestureRecognizer *)gr{
    NSLog(@"Long press");
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:p];
        //如果选中了,则移除正在画的线
        if (self.selectedLine) {
            //[self.linesProgress removeAllObjects];
        }
    }else if (gr.state == UIGestureRecognizerStateEnded){
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

/**
 *  拖动手势会触发该方法
 *
 *  @param gr 因为代码要使用到拖动手势对象(手势对象的子对象)的拖动时当前位置的方法,所以声明时必须使用UIPanGestureRecognizer
 */
-(void)moveLine:(UIPanGestureRecognizer *)gr{
    NSLog(@"Move gesture");
    //速度
    CGPoint velocity = [gr velocityInView:self];
    CGFloat vlcX = fabs(velocity.x) , vlcY = fabs(velocity.y);
    CGFloat maxValue = vlcX > vlcY ? vlcX : vlcY;
    CGFloat pathWidth = 2 * maxValue / 200;
    if (pathWidth < 5.0) {
        pathWidth = 5.0;
    }else if (pathWidth > 100){
        pathWidth = 100;
    }
    self.lineBezierPathWidth = pathWidth;
    //NSLog(@"Velocity:%@",[NSValue valueWithCGPoint:velocity]);
    
    if (!self.selectedLine || [UIMenuController sharedMenuController].isMenuVisible == YES) {
        return;
    }
    if (gr.state == UIGestureRecognizerStateChanged) {
        //该座标记录了离拖动起始座标的偏移量,所以每一次拖动之后,必须把拖动的当前位置设置为拖动起始座标的偏移量,不然每一次的增量会累计了上一次的增量,造成增加速度比手指移动速度快)
        CGPoint translation = [gr translationInView:self];
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y +=translation.y;
        end.x +=translation.x;
        end.y +=translation.y;
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        [self setNeedsDisplay];
        [gr setTranslation:CGPointZero inView:self];
    }
}

-(void)swipe:(UISwipeGestureRecognizer *)gr{
    NSLog(@"Three finger swipe up");
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    return NO;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    switch (buttonIndex) {
        case 1: //YES应该做的事
            NSLog(@"Alert YES");
            [self.finishedRounds removeAllObjects];
            [self.finishedLines removeAllObjects];
//            self.finishedLines = [[NSMutableArray alloc] init];
            [self.linesProgress removeAllObjects];
            self.currentRound = nil;
            [self setNeedsDisplay];
            break;
        case 0://NO应该做的事
            NSLog(@"Alert NO");
            break;
    }
}

#pragma mark - 绘制与判断绘制内容
- (void)strokeLine:(Line *)line{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

#pragma mark - 绘制与判断绘制内容
- (void)strokeLine:(Line *)line withLineWidth:(CGFloat)width{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = width;
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

-(Line *)lineAtPoint:(CGPoint)p{
    //根据余弦定理求出触摸点和线段构成的三角形对应的角的度数
    for (Line *l in self.finishedLines) {
//        CGPoint begin = l.begin,end = l.end;
//        //先求出三条线长度:记触摸点为P,begin点为A,end点为B,角A对应边长a,角B对应边长b,角P对应边长p
//        CGFloat a = hypot(p.x - end.x, p.y - end.y);
//        CGFloat b = hypot(p.x - begin.x, p.y - begin.y);
//        CGFloat p = hypot(begin.x - end.x, begin.y - end.y);
//        CGFloat cosP = (a*a + b*b - p*p) / 2*a*b;
//        CGFloat angleP = acos(cosP) * 180 / M_PI;
        
        CGPoint start = l.begin;
        CGPoint end = l.end;
        for (float t = 0; t <= 1.0; t +=0.05) {
            float x = start.x + t*(end.x - start.x);
            float y = start.y + t*(end.y - start.y);
            if (hypot(x - p.x, y - p.y) < 20.0) {
                return l;
            }
        }
    }
    return nil;
}

-(void)deleteLine:(id)sender{
    [self.finishedLines removeObject:self.selectedLine];
    [self setNeedsDisplay];
}

-(int)numberOfLine{
    int count;
    if (self.finishedLines && self.linesProgress) {
        count = [self.finishedLines count] + [self.linesProgress count];
    }
    return count;
}

- (void)drawRect:(CGRect)rect{
//    已经绘制过的点用黑色画出
//    [[UIColor blackColor] set];
    for (Line *l in self.finishedLines) {
        //计算绘制线的弧度
        CGFloat angle = atan2( (l.end.y - l.begin.y), (l.end.x - l.begin.x));
        UIColor *start = [UIColor redColor];
        UIColor *end = [UIColor greenColor];
        [[ColorAdjust makeUIColorFrom:start to:end forAngle:angle] set];
        [self strokeLine:l];
    }
    for (Round *round in self.finishedRounds) {
        [self strokeRound:round];
    }
    
    if (self.linesProgress.count > 0) {
        [[UIColor redColor] set];
        for (NSValue *key in self.linesProgress) {
            [self strokeLine:self.linesProgress[key] withLineWidth:self.lineBezierPathWidth];
        }
    }
    self.currentRound = [self makeRound];
    if (self.currentRound) {
        [self strokeRound:self.currentRound];
    }
    
    if (self.selectedLine) {
        [[UIColor blueColor] set];
        [self strokeLine:self.selectedLine];
    }
//    if (self.currentLine) {
//        [[UIColor redColor] set];
//        [self strokeLine:self.currentLine];
//    }
//    [path addArcWithCenter:center radius:currentRadius startAngle:0.0 endAngle:2*M_PI clockwise:YES];

//    float f = 0.0;
//    for (int i = 0; i < 1000000; i++) {
//        f = f + sin(sin(sin(time(NULL) + i)));
//    }
//    NSLog(@"f = %f",f);
}

/**
 *  根据线的位置,返回一个以线段为对角线所在的正方形对应的内接圆
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
    //可使用C函数 hypot
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

#pragma mark - 处理UIResponder

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //向控制台打印触摸事件
    NSLog(@"%@",NSStringFromSelector(_cmd));
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        Line *l = [[Line alloc] init];
        l.begin = location;
        l.end = location;
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesProgress[key] = l;
        
        //只捕获多点中的两个点,其他点自动舍弃
        if([self.touchPoints count] < 2){
            self.touchPoints[key] = [NSValue valueWithCGPoint:location];
        }
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
        Line *line =  self.linesProgress[key];
        if (line) {
            [self.finishedLines addObject:line];
        }
//        line.containingArray = self.finishedLines;
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

//强调可以成为第一响应者之后才能设置成为第一响应者
-(BOOL)canBecomeFirstResponder{
    return YES;
}

@end

