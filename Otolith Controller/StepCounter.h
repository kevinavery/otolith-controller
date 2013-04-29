//
//  StepCounter.h
//  Otolith Controller
//
//  Created by Kevin Avery on 4/28/13.
//  Copyright (c) 2013 SAHA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StepCounter : NSObject

@property (assign) int latestStepCount;
@property (assign) int totalStepCount;

-(void)resetStepCount;
-(void)updateWithCount: (int)newCount;


@end
