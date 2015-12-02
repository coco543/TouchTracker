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
    self.view = [[DrawView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
