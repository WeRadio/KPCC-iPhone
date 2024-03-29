//
//  SCPRMasterViewController.m
//  KPCC
//
//  Created by John Meeker on 8/8/14.
//  Copyright (c) 2014 SCPR. All rights reserved.
//

#import "SCPRMasterViewController.h"

#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface SCPRMasterViewController () <AudioManagerDelegate, ContentProcessor>

@end

@implementation SCPRMasterViewController


#pragma mark - UIViewController

// Allows for interaction with system audio controls.
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    // Handle remote audio control events.
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay ||
            event.subtype == UIEventSubtypeRemoteControlPause ||
            event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self playOrPauseTapped:nil];
        } else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
            [self rewindFifteen];
        } else if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
            [self fastForwardFifteen];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Set the current view to receive events from the AudioManagerDelegate.
    [AudioManager shared].delegate = self;

}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Fetch program info and update audio control state.
    [self updateDataForUI];

    // Observe when the application becomes active again, and update UI if need-be.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDataForUI) name:UIApplicationWillEnterForegroundNotification object:nil];

    // Make sure the system follows our playback status - to support the playback when the app enters the background mode.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Once the view has appeared we can register to begin receiving system audio controls.
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self updateControlsAndUI:YES];
}

- (IBAction)playOrPauseTapped:(id)sender {
    if (_seekRequested) {
        _seekRequested = NO;
    }

    if (![[AudioManager shared] isStreamPlaying]) {
        if ([[AudioManager shared] isStreamBuffering]) {
            [[AudioManager shared] stopAllAudio];
        } else {
            [self playStream];
        }
    } else {
        [self pauseStream];
    }
}

- (IBAction)rewindToStartTapped:(id)sender {
    if (_currentProgram) {
        _seekRequested = YES;
        [[AudioManager shared] seekToDate:_currentProgram.starts_at];
    }
}

- (void)playStream {
    [[AudioManager shared] startStream];
}

- (void)pauseStream {
    [[AudioManager shared] pauseStream];
}

- (void)rewindFifteen {
    _seekRequested = YES;
    [[AudioManager shared] backwardSeekFifteenSeconds];
}

- (void)fastForwardFifteen {
    _seekRequested = YES;
    [[AudioManager shared] forwardSeekFifteenSeconds];
}

- (void)receivePlayerStateNotification {
    [self updateControlsAndUI:YES];
}

- (void)updateDataForUI {
    [[NetworkManager shared] fetchProgramInformationFor:[NSDate date] display:self];
}

- (void)updateControlsAndUI:(BOOL)animated {

    // First set contents of background, live-status labels, and play button.
    [self setUIContents:animated];

    // Set positioning of UI elements.
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            [self setUIPositioning];
        }];
    } else {
        [self setUIPositioning];
    }

}

- (void)setUIContents:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.1 animations:^{
            [self.playPauseButton setAlpha:0.0];

            if ([[AudioManager shared] isStreamPlaying] || [[AudioManager shared] isStreamBuffering]) {
                [self.liveDescriptionLabel setText:@"LIVE"];
                [self.rewindToShowStartButton setAlpha:0.0];
            } else {
                [self.liveDescriptionLabel setText:@"ON NOW"];
                [self.liveRewindAltButton setAlpha:0.0];
            }

        } completion:^(BOOL finished) {

            CGAffineTransform t;// = CGAffineTransformMakeScale(1.2, 1.2);
            double transformRate = 0.0;
            
            if ([[AudioManager shared] isStreamPlaying] || [[AudioManager shared] isStreamBuffering]) {
                [self.playPauseButton setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];

                t = CGAffineTransformMakeScale(1.2, 1.2);
                transformRate = 1.2;

            } else {
                [self.playPauseButton setImage:[UIImage imageNamed:@"btn_play_large"] forState:UIControlStateNormal];

                t = CGAffineTransformMakeScale(1.0, 1.0);
                transformRate = 1.0;
            }
            
            //CGAffineTransform translate = CGAffineTransformMakeTranslation(self.programImageView.frame.origin.x - ((self.view.frame.size.width * transformRate - self.view.frame.size.width)/2) ,self.programImageView.frame.origin.y);
            //CGAffineTransform scale = t;//CGAffineTransformMakeScale(0.6, 0.6);
            //CGAffineTransform transform =  CGAffineTransformConcat(translate, scale);
            //transform = CGAffineTransformRotate(transform, degreesToRadians(-10));
            
            CGPoint center = self.programImageView.center;
            CATransform3D transform = CATransform3DIdentity;
            transform = CATransform3DTranslate(transform, self.view.center.x,  self.view.center.y, 0);
            transform = CATransform3DScale(transform, transformRate, transformRate, 1);
            
            [UIView beginAnimations:@"MoveAndRotateAnimation" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:2.0];
            
            self.programImageView.layer.transform = transform;
            self.programImageView.center = center;
            
            [UIView commitAnimations];
            
            [UIView animateWithDuration:.5 animations:^{
                self.programImageView.layer.transform = CATransform3DIdentity;
            }];


            [UIView animateWithDuration:0.1 animations:^{
                [self.playPauseButton setAlpha:1.0];
            }];
        }];

    } else {
        if ([[AudioManager shared] isStreamPlaying] || [[AudioManager shared] isStreamBuffering]) {
            [self.liveDescriptionLabel setText:@"LIVE"];
            [self.rewindToShowStartButton setAlpha:0.0];
        } else {
            [self.liveDescriptionLabel setText:@"ON NOW"];
            [self.liveRewindAltButton setAlpha:0.0];
        }

        if ([[AudioManager shared] isStreamPlaying] || [[AudioManager shared] isStreamBuffering]) {
            [self.playPauseButton setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        } else {
            [self.playPauseButton setImage:[UIImage imageNamed:@"btn_play_large"] forState:UIControlStateNormal];
        }
    }
}

- (void)setUIPositioning {
    if (!_seekRequested) {
        
        if ([[AudioManager shared] isStreamPlaying] || [[AudioManager shared] isStreamBuffering]) {
            [self.horizDividerLine setAlpha:0.4];
            [self.liveRewindAltButton setAlpha:1.0];
            
            [self.playPauseButton setFrame:CGRectMake(_playPauseButton.frame.origin.x,
                                                      385.0,
                                                      _playPauseButton.frame.size.width,
                                                      _playPauseButton.frame.size.height)];
            
            [self.liveDescriptionLabel setFrame:CGRectMake(_liveDescriptionLabel.frame.origin.x,
                                                           286.0,
                                                           _liveDescriptionLabel.frame.size.width,
                                                           _liveDescriptionLabel.frame.size.height)];
            
            [self.programTitleLabel setFrame:CGRectMake(_programTitleLabel.frame.origin.x,
                                                        303.0,
                                                        _programTitleLabel.frame.size.width,
                                                        _programTitleLabel.frame.size.height)];
            
        } else {
            [self.rewindToShowStartButton setAlpha:1.0];
            [self.horizDividerLine setAlpha:0.0];
            
            [self.playPauseButton setFrame:CGRectMake(_playPauseButton.frame.origin.x,
                                                      225.0,
                                                      _playPauseButton.frame.size.width,
                                                      _playPauseButton.frame.size.height)];
            
            [self.liveDescriptionLabel setFrame:CGRectMake(_liveDescriptionLabel.frame.origin.x,
                                                           95.0,
                                                           _liveDescriptionLabel.frame.size.width,
                                                           _liveDescriptionLabel.frame.size.height)];
            
            [self.programTitleLabel setFrame:CGRectMake(_programTitleLabel.frame.origin.x,
                                                        113.0,
                                                        _programTitleLabel.frame.size.width,
                                                        _programTitleLabel.frame.size.height)];
        }
    } else {
        _seekRequested = NO;
    }
}

- (void)updateUIWithProgram:(Program*)program {
    if (!program) {
        return;
    }

    if ([program title]) {
        if ([program title].length <= 14) {
            [self.programTitleLabel setFont:[self.programTitleLabel.font fontWithSize:46.0]];
        } else if ([program title].length > 14 && [program title].length <= 18) {
            [self.programTitleLabel setFont:[self.programTitleLabel.font fontWithSize:35.0]];
        } else {
            [self.programTitleLabel setFont:[self.programTitleLabel.font fontWithSize:30.0]];
        }
        [self.programTitleLabel setText:[program title]];
    }
}

- (void)updateNowPlayingInfoWithProgram:(Program*)program {
    if (!program) {
        return;
    }

    NSDictionary *audioMetaData = @{ MPMediaItemPropertyArtist : @"89.3 KPCC",
                                     MPMediaItemPropertyTitle : program.title//,
                                     /*MPNowPlayingInfoPropertyPlaybackRate : [[NSNumber alloc] initWithFloat:10],
                                     MPMediaItemPropertyAlbumTitle : @"LIVE",
                                     MPNowPlayingInfoPropertyElapsedPlaybackTime: [[NSNumber alloc] initWithDouble:40]*/ };

    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:audioMetaData];
}


#pragma mark - AudioManagerDelegate

- (void)onRateChange {
    [self updateControlsAndUI:YES];
}


#pragma mark - ContentProcessor 

- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
    if ([content count] == 0) {
        return;
    }

    // Create Program and insert into managed object context
    if ([content objectAtIndex:0]) {
        NSDictionary *programDict = [content objectAtIndex:0];

        Program *programObj = [Program insertNewObjectIntoContext:[[ContentManager shared] managedObjectContext]];

        if ([programDict objectForKey:@"title"]) {
            programObj.title = [programDict objectForKey:@"title"];
        }

        if ([[programDict objectForKey:@"program"] objectForKey:@"slug"]) {
            programObj.program_slug = [[programDict objectForKey:@"program"] objectForKey:@"slug"];
        }
        
        [self loadProgramImage:programObj.program_slug];
        [self updateUIWithProgram:programObj];

        self.currentProgram = programObj;
        [self updateNowPlayingInfoWithProgram:programObj];

        // Save the Program to persistant storage.
        [[ContentManager shared] saveContext];
    }
}

- (void)loadProgramImage:(NSString *)slug {

    // Load JSON with program image urls.
    NSError *fileError = nil;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[@"program_image_urls" stringByDeletingPathExtension] ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    
    NSDictionary *dict = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&fileError];

    NSLog(@"DICT! %@", dict);
    NSString *slug2x = [NSString stringWithFormat:@"%@-2x", slug];
    NSLog(@"slug2x - %@", slug2x);
    
    // Async request to fetch image and set in background tile view. Via AFNetworking.
    if ([dict objectForKey:slug2x]) {
        NSURL *imageUrl = [NSURL URLWithString:[dict objectForKey:slug2x]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageUrl];
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.programImageView setAlpha:0.0];
        }];
        UIImageView *programIV = self.programImageView;
        [self.programImageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            programIV.image = image;
            [UIView animateWithDuration:0.15 animations:^{
                [programIV setAlpha:1.0];
            }];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {

        }];
    }

}

- (void)dealloc {
    //End receiving events.
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
