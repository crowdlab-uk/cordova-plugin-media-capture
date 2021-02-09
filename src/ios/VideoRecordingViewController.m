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


@implementation VideoRecordingViewController {
  bool isCameraPositionBack;
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
  
  CGFloat screenProportion = self.view.safeAreaLayoutGuide.layoutFrame.size.height / self.view.safeAreaLayoutGuide.layoutFrame.size.width ;
  
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
  
 
  self.navigationItem.leftBarButtonItem = switchButton;
  
  //  self.toolbarItems = @[barButton];
}

- (void)recordButtonPressed {
  NSLog(@"recordbutton: %d", self.captureButton.selected);
  bool isRecording = self.captureButton.selected;
  [self.captureButton setSelected:!isRecording];
  if (isRecording) {
    [self.delegate shouldEndRecording];
  } else {
    [self.delegate shouldStartRecording];
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
