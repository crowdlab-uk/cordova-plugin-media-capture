//
//  VideoRecordingView.m
//  Engage iOS
//
//  Created by Thomas Lee on 13/10/2020.
//

#import "CDVCapture.h"
#import <Cordova/CDVPlugin.h>
#import <CameraKit_iOS/CameraKit_iOS-Swift.h>
#import "VideoRecordingViewController.h"
#import "RecordButton.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>


@implementation TimeView {}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.layer.cornerRadius = 4;
    [self setBackgroundColor:UIColor.blackColor];
    [self setAlpha:0.6];
    
    self.timeLabel = [UILabel new];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.timeLabel setTextColor:UIColor.whiteColor];
    [self addSubview:self.timeLabel];
    
    NSLayoutConstraint *timeLabelMarginTop = [NSLayoutConstraint constraintWithItem:self.safeAreaLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.timeLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-4];
    NSLayoutConstraint *timeLabelMarginLeft = [NSLayoutConstraint constraintWithItem:self.safeAreaLayoutGuide attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.timeLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-4];
    NSLayoutConstraint *timeLabelMarginBottom = [NSLayoutConstraint constraintWithItem:self.safeAreaLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.timeLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:4];
    NSLayoutConstraint *timeLabelMarginRight = [NSLayoutConstraint constraintWithItem:self.safeAreaLayoutGuide attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.timeLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:4];
    
    [timeLabelMarginTop setActive:YES];
    [timeLabelMarginLeft setActive:YES];
    [timeLabelMarginBottom setActive:YES];
    [timeLabelMarginRight setActive:YES];
  }
  return self;
}

- (void)setText:(NSString *)text {
  [self.timeLabel setText:text];
}


@end
    

@implementation VideoRecordingViewController {
  bool isCameraPositionBack;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval {
  NSDate *endingDate = [NSDate date];
   
  NSDate *startingDate = [endingDate dateByAddingTimeInterval:(-timeInterval)];
  NSCalendar *calendar = NSCalendar.currentCalendar;


  NSDateComponents *componentsNow = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:startingDate toDate:endingDate options:@{}];
  
  NSInteger minutes = [componentsNow minute];
  NSInteger seconds = [componentsNow second];
            
  return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
}

- (VideoRecordingViewController *)initWithCommand:(CDVInvokedUrlCommand *)command duration:(NSNumber *)duration callbackId:(NSString *)callbackId {
  return self;
}

- (void)viewDidLayoutSubviews {
  [self.previewView.previewLayer setVideoGravity: kCAGravityResizeAspectFill];
  
}


- (void)viewDidLoad {
  isCameraPositionBack = true;
  [self.view setBackgroundColor:UIColor.blackColor];
  
  self.previewView = [[CKFPreviewView alloc] initWithFrame:self.view.frame];
  [self.previewView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self.previewView setSession:self.videoSession];
  self.previewView.backgroundColor = UIColor.blueColor;
  [self.view addSubview:self.previewView];
  
  NSLayoutConstraint *previewCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.previewView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
  NSLayoutConstraint *previewCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.previewView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
  NSLayoutConstraint *previewMinimumWidthConstraint = [NSLayoutConstraint constraintWithItem:self.previewView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
  
  CGFloat screenProportion = self.view.safeAreaLayoutGuide.layoutFrame.size.height / self.view.safeAreaLayoutGuide.layoutFrame.size.width;
  
  NSLayoutConstraint *previewProportionConstraint = [NSLayoutConstraint constraintWithItem:self.previewView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:screenProportion constant:0];
  
  self.videoSession.delegate = self;
  self.captureButton = [RecordButton new];
  [self.captureButton setBackgroundColor:UIColor.redColor];
  
  [self.captureButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self.captureButton setEnabled:YES];
  
  [self.view addSubview:self.captureButton];
  [self.view bringSubviewToFront:self.captureButton];
  [self.captureButton addTarget:self action: @selector(recordButtonPressed) forControlEvents: UIControlEventTouchUpInside];
  
  NSLayoutConstraint *recordButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.captureButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20];
  NSLayoutConstraint *recordButtonCenterConstraint = [NSLayoutConstraint constraintWithItem:self.captureButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
  NSLayoutConstraint *recordButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:self.captureButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44];
  NSLayoutConstraint *recordButtonHeightConstraint = [NSLayoutConstraint constraintWithItem:self.captureButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44];
  
  [recordButtonBottomConstraint setActive:YES];
  [recordButtonCenterConstraint setActive:YES];
  [recordButtonWidthConstraint setActive:YES];
  [recordButtonHeightConstraint setActive:YES];
  
  [previewMinimumWidthConstraint setActive:YES];
  [previewProportionConstraint setActive:YES];
  [previewCenterXConstraint setActive:YES];
  [previewCenterYConstraint setActive:YES];
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
  [doneButton setStyle:UIBarButtonItemStyleDone];
  self.navigationItem.rightBarButtonItem = doneButton;
  
  UIBarButtonItem *switchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(switchButtonPressed)];
  
  
  self.timeView = [TimeView new];
  self.timeView.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:self.timeView];
  
  NSLayoutConstraint *timeLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.timeView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-8];
  NSLayoutConstraint *timeLabelCenterConstraint = [NSLayoutConstraint constraintWithItem:self.timeView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
  
  [timeLabelTopConstraint setActive:YES];
  [timeLabelCenterConstraint setActive:YES];
  
  self.navigationItem.leftBarButtonItem = switchButton;
  
  //  self.toolbarItems = @[barButton];
}

- (void)recordButtonPressed {
  NSLog(@"recordbutton: %d", self.captureButton.selected);
  bool isRecording = self.captureButton.selected;
  
  
  [self.captureButton setSelected:!isRecording];
  if (isRecording) {
    [self.delegate shouldEndRecording];
    [self.timer invalidate];
  } else {
    [self.delegate shouldStartRecording];
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                          target: self
                          selector:@selector(onTick)
                          userInfo:nil repeats:YES];
    self.timerStartDate = [NSDate date];
  }
}

- (void)onTick {
  NSLog(@"self.timer.fireDate: %@", self.timer.fireDate);
  NSLog(@"date: %@", [[NSDate date] dateByAddingTimeInterval:self.targetDurationInSeconds]);
  
  NSTimeInterval timeRecorded = [[NSDate date] timeIntervalSinceDate: self.timerStartDate];
  
  if (self.targetDurationInSeconds == 0) {
    [self.timeView setText:[self stringFromTimeInterval:timeRecorded]];
  
  } else {
    [self.timeView setText:[NSString stringWithFormat:@"%@ / %@", [self stringFromTimeInterval:timeRecorded], [self stringFromTimeInterval:self.targetDurationInSeconds]]];
    
    if ([self.timer.fireDate compare:[self.timerStartDate dateByAddingTimeInterval:self.targetDurationInSeconds]] == NSOrderedDescending) {
      
      [self.delegate shouldEndRecording];
      [self.captureButton setSelected:false];
      [self.timer invalidate];
    }
  }
  
}

- (void)switchButtonPressed {
  [self.delegate shouldSwitchCameras];
}

- (void)doneButtonPressed {
  [self.delegate shouldSaveRecording];
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  [self.videoSession start];
  
  NSLog(@"duration: %f", self.targetDurationInSeconds);
  if (self.targetDurationInSeconds == 0) {
    [self.timeView setText:@"0:00"];
  } else {
    [self.timeView setText:[NSString stringWithFormat:@"0:00 / %@", [self stringFromTimeInterval:self.targetDurationInSeconds]]];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
}

- (void)viewDidDisappear:(BOOL)animated {
  [self.videoSession stop];
}

- (void)didChangeValueWithSession:(CKFSession * _Nonnull)session value:(id _Nonnull)value key:(NSString * _Nonnull)key {
  //  if ([key equals:@"zoom" ]) {
  //      self.zoomLabel.text = String(format: "%.1fx", value as! Double)
  //  }
}


@end
