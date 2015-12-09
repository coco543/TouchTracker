//
//  DrawViewController.m
//  TouchTracker
//
//  Created by 郑克明 on 15/12/2.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import "DrawViewController.h"
#import "DrawView.h"
@interface DrawViewController ()

@end

@implementation DrawViewController

-(void)loadView{
    NSLog(@"Invoke loadView");
    //必须先将视图赋值给一个变量view.不能直接赋值给self.view,如果赋值给self.view的是nil,那么再对self.view做if判断的时候,系统又将重新调用loadView这个方法,造成死循环
    UIView  *view = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]];
    if (!view) {
        view = [[DrawView alloc] initWithFrame:CGRectZero];
    }
    self.view = view;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"View didload");
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSLog(@"View disappear");
    [NSKeyedArchiver archiveRootObject:self.view toFile:[self filePath]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//获取保存文件的路径
- (NSString *)filePath
{
    NSString *path =[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FinishedLines.archiver"];
    NSLog(@"Path is :%@",path);
    return path;
}

@end
