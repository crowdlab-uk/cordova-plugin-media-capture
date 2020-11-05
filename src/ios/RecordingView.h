//
//  RecordingView.h
//  Engage
//
//  Created by Thomas Lee on 15/10/2019.
//

#import <UIKit/UIKit.h>
#import "SCSiriWaveformView.h"
#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RecordingViewDelegate

- (void)recordingButtonPressed:(UIButton *)button;

@end


@interface RecordingView : UIView

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
- (IBAction)recordButtonPressed:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet SCSiriWaveformView *waveformView;
@property (weak, nonatomic) AVAudioRecorder *recorder;

@property (weak, nonatomic) id <RecordingViewDelegate> delegate;

- (void)setTimerVisibility:(BOOL)timerIsVisible;
- (void)updateTimerWithTime:(NSString *)newTime;

@end


NS_ASSUME_NONNULL_END
