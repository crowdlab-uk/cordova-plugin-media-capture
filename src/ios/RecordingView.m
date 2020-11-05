//
//  RecordingView.m
//  Engage
//
//  Created by Thomas Lee on 15/10/2019.
//

#import "RecordingView.h"

@implementation RecordingView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init
{
  self = [super init];
  if (self) {
    [self setup];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self setup];
  }
  return self;
}

- (void)setTimerVisibility:(BOOL)timerIsVisible {
  [self.timeLabel setHidden:!timerIsVisible];
}

- (void)updateTimerWithTime:(NSString *)newTime {
  [self.timeLabel setText:newTime];
}

- (void)setup
{
  CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
  [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

  [self.waveformView setWaveColor: [UIColor whiteColor]];
  [self.waveformView setPrimaryWaveLineWidth: 3.0f];
  [self.waveformView setSecondaryWaveLineWidth: 1.0];

  [self bringSubviewToFront:self.timeLabel];
  self.recordButton.layer.cornerRadius = 10;
}

- (void)updateMeters
{
  CGFloat normalizedValue;
  [self.recorder updateMeters];
  normalizedValue = [self _normalizedPowerLevelFromDecibels:[self.recorder averagePowerForChannel:0]];
  [self.waveformView updateWithLevel:normalizedValue];
}

- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
  if (decibels < -60.0f || decibels == 0.0f) {
    return 0.0f;
  }
  return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

- (IBAction)recordButtonPressed:(UIButton *)sender {
  if (self.delegate == nil) {
    return;
  }
  [self.delegate recordingButtonPressed: sender];
}
@end
