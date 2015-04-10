//
//  QYViewController.m
//  AVAudioPlayerDemo
//
//  Created by qingyun on 15-4-7.
//  Copyright (c) 2015年 hnqingyun.com. All rights reserved.
//

#import "QYViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface QYViewController () <AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UISlider *volumnSlider;
@property (weak, nonatomic) IBOutlet UISlider *durationSlider;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation QYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 1. 创建并配置player
    NSURL *songFileURL = [[NSBundle mainBundle] URLForResource:@"红颜劫" withExtension:@"mp3"];
    
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:songFileURL error:nil];
    
    self.player = player;
    
    self.player.delegate = self;
    
    self.player.enableRate = YES;
    
    [self.player prepareToPlay];
    
    // 2. 配置UI
    self.durationSlider.minimumValue = 0;
    self.durationSlider.maximumValue = self.player.duration;
    
    self.volumnSlider.minimumValue = 0;
    self.volumnSlider.maximumValue = 1;
    self.volumnSlider.value = self.player.volume;
    
    // 3. 设置音频支持后台播放
    [self setAudio2SupportBackgroundPlay];
    
    // 4. 设置锁屏歌曲信息
    [self setupLockScreenSongInfos];
}


- (void)setupLockScreenSongInfos
{
    // 设置锁屏歌曲专辑图片
    MPMediaItemArtwork *artWork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"红颜劫.jpg"]];
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{
                                                              MPMediaItemPropertyPlaybackDuration:@(_player.duration),
                                                              MPMediaItemPropertyTitle:@"红颜劫",
                                                              MPMediaItemPropertyArtist:@"姚贝娜",
                                                              MPMediaItemPropertyArtwork:artWork,
                                                              MPNowPlayingInfoPropertyPlaybackRate:@(1.0f)
                                                              };
}

- (void)setAudio2SupportBackgroundPlay
{
    UIDevice *device = [UIDevice currentDevice];
    
    if (![device respondsToSelector:@selector(isMultitaskingSupported)]) {
        NSLog(@"Unsupported device!");
        return;
    }
    
    if (!device.multitaskingSupported) {
        NSLog(@"Unsupported multiTasking!");
        return;
    }
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *error;
    
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateDurationSlider) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

// 接收远程控制事件
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self playOrPause:nil];
                break;
                
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updatePlayOrPauseBtn:(BOOL)isPlaying
{
    if (isPlaying) {
        [self.playOrPauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [self.playOrPauseBtn setTitle:@"暂停" forState:UIControlStateHighlighted];
    } else {
        [self.playOrPauseBtn setTitle:@"播放" forState:UIControlStateNormal];
        [self.playOrPauseBtn setTitle:@"播放" forState:UIControlStateHighlighted];
    }
}

- (IBAction)playOrPause:(id)sender {
    
    // 重置播放速率
    self.player.rate = 1;
    
    if (self.player.isPlaying) {
        // 正在播放，则暂停，并更新button
        [self.player pause];
        
        // 暂停定时器
        self.timer.fireDate = [NSDate distantFuture];
        
        [self updatePlayOrPauseBtn:NO];
    } else {
        [self.player play];
        
        // fire定时器
        self.timer.fireDate = [NSDate date]; // 设置定时器触发时间为现在
        [self.timer fire]; // 触发
        
        [self updatePlayOrPauseBtn:YES];
    }
}
- (IBAction)adjustDuration:(id)sender {
    self.player.currentTime = self.durationSlider.value;
}

- (void)updateDurationSlider
{
    self.durationSlider.value = self.player.currentTime;
}

- (IBAction)adjustVolumn:(id)sender {
    self.player.volume = self.volumnSlider.value;
}
- (IBAction)halfRatePlay:(id)sender {
    self.player.rate = 0.5;
}
- (IBAction)doubleRatePlay:(id)sender {
    self.player.rate = 2;
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        [self updatePlayOrPauseBtn:NO];
    }
}

@end
