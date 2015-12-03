//
//  Line.m
//  TouchTracker
//
//  Created by 郑克明 on 15/12/2.
//  Copyright © 2015年 郑克明. All rights reserved.
//

#import "Line.h"

@implementation Line

- (instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super init];
    if (self) {
        NSValue *value = [decoder decodeObjectForKey:@"begin"];
        self.begin = [value CGPointValue];
        value = [decoder decodeObjectForKey:@"end"];
        self.end = [value CGPointValue];
    }
    return self;
}

//序列化,反序列化
- (void)encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:[NSValue valueWithCGPoint:self.begin] forKey:@"begin"];
    [encoder encodeObject:[NSValue valueWithCGPoint:self.end] forKey:@"end"];
}

@end
