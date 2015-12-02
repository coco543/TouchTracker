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

- (void)viewDidLoad {
    self.view = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]];
    if (!self.view) {
        self.view = [[DrawView alloc] initWithFrame:CGRectZero];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
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
