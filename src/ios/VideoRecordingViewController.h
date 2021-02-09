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

@protocol VideoRecordingViewControllerDelegate
- (void)shouldStartRecording;
- (void)shouldEndRecording;
- (void)shouldSwitchCameras;
- (void)shouldSaveRecording;
@end

@interface VideoRecordingViewController : UIViewController<CKFSessionDelegate>

@property (strong, nonatomic) CKFPreviewView *previewView;
@property (strong, nonatomic) IBOutlet UIButton *captureButton;
@property (weak) IBOutlet UILabel *zoomLabel;
@property (weak, nonatomic) UIViewController <VideoRecordingViewControllerDelegate> *delegate;

@property (strong, nonatomic) CKFSession *videoSession;

- (VideoRecordingViewController *)initWithCommand:(CDVInvokedUrlCommand *)command duration:(NSNumber *)duration callbackId:(NSString *)callbackId;

@end

NS_ASSUME_NONNULL_END
