//
//  VideoRecordingView.h
//  Engage iOS
//
//  Created by Thomas Lee on 13/10/2020.
//

#import <UIKit/UIKit.h>
#import <CameraKit_iOS/CameraKit_iOS-Swift.h>
#import <CameraKit_iOS/CameraKit-iOS-umbrella.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeView : UIView
@property (strong, nonatomic) UILabel *timeLabel;

- (void)setText:(NSString *)text;

@end

@protocol VideoRecordingViewControllerDelegate
- (void)shouldStartRecording;
- (void)shouldEndRecording;
- (void)shouldSwitchCameras;
- (void)shouldSaveRecording;
@end

@interface VideoRecordingViewController : UIViewController<CKFSessionDelegate>

@property (strong, nonatomic) CKFPreviewView *previewView;
@property (strong, nonatomic) IBOutlet UIButton *captureButton;
@property (strong, nonatomic) NSTimer *timer;
@property double targetDurationInSeconds;
@property (weak) IBOutlet UILabel *zoomLabel;
@property (weak, nonatomic) UIViewController <VideoRecordingViewControllerDelegate> *delegate;
@property (strong, nonatomic) TimeView *timeView;
@property (strong, nonatomic) NSDate *timerStartDate;

@property (strong, nonatomic) CKFSession *videoSession;

- (VideoRecordingViewController *)initWithCommand:(CDVInvokedUrlCommand *)command duration:(NSNumber *)duration callbackId:(NSString *)callbackId;
- (void)onTick;


@end

NS_ASSUME_NONNULL_END
