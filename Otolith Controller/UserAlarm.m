//
//  UserAlarm.m
//  Otolith Controller
//
//  Created by Kevin Avery on 4/28/13.
//  Copyright (c) 2013 SAHA. All rights reserved.
//

#import "UserAlarm.h"

@implementation UserAlarm

-(id)init
{
    self = [super init];
    if (self)
    {
        [self setAlarmTime:0];
    }
    return self;
}

@end
