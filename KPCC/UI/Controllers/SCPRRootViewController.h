//
//  SCPRRootViewController.h
//  KPCC
//
//  Created by John Meeker on 4/1/14.
//  Copyright (c) 2014 SCPR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioManager.h"
#import "NetworkManager.h"

@interface SCPRRootViewController : UIViewController
{
@private
    NSTimer *timer;
}

- (void)updateNowPlayingInfoWithProgram:(NSString*)program;
@end
