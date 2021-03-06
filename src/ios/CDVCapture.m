/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import "CDVCapture.h"
#import "CDVFile.h"
#import "RecordingView.h"
#import <Cordova/CDVAvailability.h>
#import <Photos/Photos.h>
#import <CoreMedia/CoreMedia.h>
#import "VideoRecordingViewController.h"

#define kW3CMediaFormatHeight @"height"
#define kW3CMediaFormatWidth @"width"
#define kW3CMediaFormatCodecs @"codecs"
#define kW3CMediaFormatBitrate @"bitrate"
#define kW3CMediaFormatDuration @"duration"
#define kW3CMediaModeType @"type"

@implementation NSBundle (PluginExtensions)

+ (NSBundle *)pluginBundle:(CDVPlugin *)plugin {
  NSBundle *bundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:NSStringFromClass([plugin class]) ofType: @"bundle"]];
  return bundle;
}
@end

#define PluginLocalizedString(plugin, key, comment) [[NSBundle pluginBundle:(plugin)] localizedStringForKey:(key) value:nil table:nil]

@implementation CDVImagePicker

@synthesize quality;
@synthesize callbackId;
@synthesize mimeType;

- (uint64_t)accessibilityTraits
{
  return UIAccessibilityTraitStartsMediaSession;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
  return nil;
}

- (void)viewWillAppear:(BOOL)animated {
  SEL sel = NSSelectorFromString(@"setNeedsStatusBarAppearanceUpdate");
  if ([self respondsToSelector:sel]) {
    [self performSelector:sel withObject:nil afterDelay:0];
  }
  
  [super viewWillAppear:animated];
}

@end

@implementation CDVCapture
@synthesize inUse;

- (void)pluginInitialize
{
  self.inUse = NO;
}

- (void)captureAudio:(CDVInvokedUrlCommand *)command
{
  NSString *callbackId = command.callbackId;
  NSDictionary *options = [command argumentAtIndex:0];
  
  if ([options isKindOfClass:[NSNull class]]) {
    options = [NSDictionary dictionary];
  }
  
  NSNumber *duration = [options objectForKey:@"duration"];
  // the default value of duration is 0 so use nil (no duration) if default value
  if (duration) {
    duration = [duration doubleValue] == 0 ? nil : duration;
  }
  CDVPluginResult *result = nil;
  
  if (NSClassFromString(@"AVAudioRecorder") == nil) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NOT_SUPPORTED];
  } else if (self.inUse == YES) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_APPLICATION_BUSY];
  } else {
    // all the work occurs here
    CDVAudioRecorderViewController *audioViewController = [[CDVAudioRecorderViewController alloc] initWithCommand:self duration:duration callbackId:callbackId];
    
    // Now create a nav controller and display the view...
    CDVAudioNavigationController *navController = [[CDVAudioNavigationController alloc] initWithRootViewController:audioViewController];
    self.inUse = YES;
    [self.viewController presentViewController:navController animated:YES completion:nil];
  }
  
  if (result) {
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
  }
}

- (void)captureImage:(CDVInvokedUrlCommand*)command
{
  NSString *callbackId = command.callbackId;
  NSDictionary *options = [command argumentAtIndex:0];
  
  if ([options isKindOfClass:[NSNull class]]) {
    options = [NSDictionary dictionary];
  }
  
  // options could contain limit and mode neither of which are supported at this time
  // taking more than one picture (limit) is only supported if provide own controls via cameraOverlayView property
  // can support mode in OS
  
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    NSLog(@"Capture.imageCapture: camera not available.");
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NOT_SUPPORTED];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
  } else {
    if (pickerController == nil) {
      pickerController = [[CDVImagePicker alloc] init];
    }
    
    [self showAlertIfAccessProhibited];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerController.quality = UIImagePickerControllerQualityTypeHigh;
    pickerController.allowsEditing = NO;
    if ([pickerController respondsToSelector:@selector(mediaTypes)]) {
      // iOS 3.0
      pickerController.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, nil];
    }

    // CDVImagePicker specific property
    pickerController.callbackId = callbackId;
    pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.viewController presentViewController:pickerController animated:YES completion:nil];
  }
}

/* Process a still image from the camera.
 * IN:
 *  UIImage* image - the UIImage data returned from the camera
 *  NSString* callbackId
 */
- (CDVPluginResult *)processImage:(UIImage *)image type:(NSString *)mimeType forCallbackId:(NSString *)callbackId
{
  CDVPluginResult *result = nil;
  
  // save the image to photo album
  UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  
  NSData *data = nil;
  if (mimeType && [mimeType isEqualToString:@"image/png"]) {
    data = UIImagePNGRepresentation(image);
  } else {
    data = UIImageJPEGRepresentation(image, 0.5);
  }
  
  // write to temp directory and return URI
  NSString *docsPath = [NSTemporaryDirectory() stringByStandardizingPath];   // use file system temporary directory
  NSError *err = nil;
  NSFileManager *fileMgr = [[NSFileManager alloc] init];
  
  // generate unique file name
  NSString *filePath;
  int i = 1;
  do {
    filePath = [NSString stringWithFormat:@"%@/photo_%03d.jpg", docsPath, i++];
  } while ([fileMgr fileExistsAtPath:filePath]);
  
  if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageToErrorObject:CAPTURE_INTERNAL_ERR];
    if (err) {
      NSLog(@"Error saving image: %@", [err localizedDescription]);
    }
  } else {
    // create MediaFile object
    
    NSDictionary *fileDict = [self getMediaDictionaryFromPath:filePath ofType:mimeType];
    NSArray *fileArray = [NSArray arrayWithObject:fileDict];
    
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
  }
  
  return result;
}


- (void)recordingFinishedWithURL:(NSURL *)url {
  NSLog(@"url:%@", url);
  NSError *error;
  NSFileManager *manager = [NSFileManager defaultManager];
  CDVPluginResult *result = [self processVideo:[url absoluteString] forCallbackId:self.videoCallbackId];
  [self.commandDelegate sendPluginResult:result callbackId:self.videoCallbackId];
  [manager removeItemAtPath:[url absoluteString] error:&error];
}

- (void)shouldStartRecording {
  NSLog(@"start recording");
  [self.ckVideoSession recordWithUrl:nil :^void(NSURL *url) {
    [self recordingFinishedWithURL:url];
  } error:^void(NSError *error) {
    NSLog(@"error: %@", error);
  }];
  
}

- (void)shouldEndRecording {
  [self.ckVideoSession stopRecording];
}

- (void)shouldSwitchCameras {
  CameraPosition position = self.ckVideoSession.cameraPosition;
  
  if (position == CameraPositionFront) {
    [self.ckVideoSession setCameraPosition:CameraPositionBack];
  } else {
    [self.ckVideoSession setCameraPosition:CameraPositionFront];
  }
}

- (void)shouldSaveRecording {

}

- (void)captureVideo:(CDVInvokedUrlCommand *)command
{
  self.videoCallbackId = command.callbackId;
  self.ckVideoSession = [[CKFVideoSession alloc] initWithPosition: CameraPositionBack];
  
  void (^callback)(NSURL *) = ^void(NSURL *url) {
    NSLog(@"url:%@", url);
  };
  
  void (^error)(NSError *) = ^void(NSError *err) {
    NSLog(@"err:%@", err);
  };
  
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  
  // Get canonical version of localPath
  NSURL *documentsURL = [[fileMgr URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
  
  NSURL *moviesURL = [documentsURL URLByAppendingPathComponent:@"movies/"];
  
  NSURL *moviePath = [moviesURL URLByAppendingPathComponent: @"tmp-movie"];
  [fileMgr removeItemAtPath:[moviePath absoluteString] error:nil];
  [self.ckVideoSession recordWithUrl:moviePath :callback error:error];
  
  NSDictionary *options = [command argumentAtIndex:0];
  NSNumber *duration = [options objectForKey:@"duration"];
  NSString *callbackId = command.callbackId;
  VideoRecordingViewController *videoVC = [[VideoRecordingViewController alloc] initWithCommand:command duration:duration callbackId:callbackId];
  videoVC.targetDurationInSeconds = [duration doubleValue];
  videoVC.delegate = self;
  self.ckVideoSession = [[CKFVideoSession alloc] initWithPosition:CameraPositionBack];
  videoVC.videoSession = self.ckVideoSession;
  // Now create a nav controller and display the view...
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:videoVC];
  
  self.inUse = YES;
  
  [self.viewController presentViewController:navController animated:YES completion:nil];
}

- (CDVPluginResult*)processVideo:(NSString*)moviePath forCallbackId:(NSString*)callbackId
{
  // save the movie to photo album (only avail as of iOS 3.1)
  
  /* don't need, it should automatically get saved
   NSLog(@"can save %@: %d ?", moviePath, UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath));
   if (&UIVideoAtPathIsCompatibleWithSavedPhotosAlbum != NULL && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath) == YES) {
   NSLog(@"try to save movie");
   UISaveVideoAtPathToSavedPhotosAlbum(moviePath, nil, nil, nil);
   NSLog(@"finished saving movie");
   }*/
  // create MediaFile object
  NSDictionary* fileDict = [self getMediaDictionaryFromPath:moviePath ofType:nil];
  NSArray *fileArray = [NSArray arrayWithObject:fileDict];
  
  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
}

- (void)showAlertIfAccessProhibited
{
  if (![self hasCameraAccess]) {
    [self showPermissionsAlert];
  }
}

- (BOOL)hasCameraAccess
{
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  
  return status != AVAuthorizationStatusDenied && status != AVAuthorizationStatusRestricted;
}

- (void)showPermissionsAlert
{
  __weak CDVCapture *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle]
                                         objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                message:NSLocalizedString(@"Access to the camera has been prohibited; please enable it in the Settings app to continue.", nil)
                               delegate:weakSelf
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:NSLocalizedString(@"Settings", nil), nil] show];
  });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
  }
  
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_PERMISSION_DENIED];
  
  [[pickerController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  [self.commandDelegate sendPluginResult:result callbackId:pickerController.callbackId];
  pickerController = nil;
  self.inUse = NO;
}

- (void)getMediaModes:(CDVInvokedUrlCommand*)command
{
  // NSString* callbackId = [command argumentAtIndex:0];
  // NSMutableDictionary* imageModes = nil;
  NSArray *imageArray = nil;
  NSArray *movieArray = nil;
  NSArray *audioArray = nil;
  
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    // there is a camera, find the modes
    // can get image/jpeg or image/png from camera
    
    /* can't find a way to get the default height and width and other info
     * for images/movies taken with UIImagePickerController
     */
    NSDictionary *jpg = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
                         [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
                         @"image/jpeg", kW3CMediaModeType,
                         nil];
    NSDictionary *png = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
                         [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
                         @"image/png", kW3CMediaModeType,
                         nil];
    imageArray = [NSArray arrayWithObjects:jpg, png, nil];
    
    if ([UIImagePickerController respondsToSelector:@selector(availableMediaTypesForSourceType:)]) {
      NSArray *types = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
      
      if ([types containsObject:(NSString*)kUTTypeMovie]) {
        NSDictionary* mov = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:0], kW3CMediaFormatHeight,
                             [NSNumber numberWithInt:0], kW3CMediaFormatWidth,
                             @"video/quicktime", kW3CMediaModeType,
                             nil];
        movieArray = [NSArray arrayWithObject:mov];
      }
    }
  }
  NSDictionary *modes = [NSDictionary dictionaryWithObjectsAndKeys:
                         imageArray ? (NSObject*)                          imageArray:[NSNull null], @"image",
                         movieArray ? (NSObject*)                          movieArray:[NSNull null], @"video",
                         audioArray ? (NSObject*)                          audioArray:[NSNull null], @"audio",
                         nil];
  
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:modes options:0 error:nil];
  NSString* jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  
  NSString *jsString = [NSString stringWithFormat:@"navigator.device.capture.setSupportedModes(%@);", jsonStr];
  [self.commandDelegate evalJs:jsString];
}

- (void)getFormatData:(CDVInvokedUrlCommand*)command
{
  NSString *callbackId = command.callbackId;
  // existence of fullPath checked on JS side
  NSString *fullPath = [command argumentAtIndex:0];
  // mimeType could be null
  NSString *mimeType = nil;
  
  if ([command.arguments count] > 1) {
    mimeType = [command argumentAtIndex:1];
  }
  BOOL bError = NO;
  CDVCaptureError errorCode = CAPTURE_INTERNAL_ERR;
  CDVPluginResult *result = nil;
  
  if (!mimeType || [mimeType isKindOfClass:[NSNull class]]) {
    // try to determine mime type if not provided
    id command = [self.commandDelegate getCommandInstance:@"File"];
    bError = !([command isKindOfClass:[CDVFile class]]);
    if (!bError) {
      CDVFile *cdvFile = (CDVFile *)command;
      mimeType = [cdvFile getMimeTypeFromPath:fullPath];
      if (!mimeType) {
        // can't do much without mimeType, return error
        bError = YES;
        errorCode = CAPTURE_INVALID_ARGUMENT;
      }
    }
  }
  if (!bError) {
    // create and initialize return dictionary
    NSMutableDictionary *formatData = [NSMutableDictionary dictionaryWithCapacity:5];
    [formatData setObject:[NSNull null] forKey:kW3CMediaFormatCodecs];
    [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatBitrate];
    [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatHeight];
    [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatWidth];
    [formatData setObject:[NSNumber numberWithInt:0] forKey:kW3CMediaFormatDuration];
    
    if ([mimeType rangeOfString:@"image/"].location != NSNotFound) {
      UIImage* image = [UIImage imageWithContentsOfFile:fullPath];
      if (image) {
        CGSize imgSize = [image size];
        [formatData setObject:[NSNumber numberWithInteger:imgSize.width] forKey:kW3CMediaFormatWidth];
        [formatData setObject:[NSNumber numberWithInteger:imgSize.height] forKey:kW3CMediaFormatHeight];
      }
    } else if (([mimeType rangeOfString:@"video/"].location != NSNotFound) && (NSClassFromString(@"AVURLAsset") != nil)) {
      NSURL *movieURL = [NSURL fileURLWithPath:fullPath];
      AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:movieURL options:nil];
      CMTime duration = [movieAsset duration];
      [formatData setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(duration)]  forKey:kW3CMediaFormatDuration];
      
      NSArray *allVideoTracks = [movieAsset tracksWithMediaType:AVMediaTypeVideo];
      if ([allVideoTracks count] > 0) {
        AVAssetTrack *track = [[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        CGSize size = [track naturalSize];
        
        [formatData setObject:[NSNumber numberWithFloat:size.height] forKey:kW3CMediaFormatHeight];
        [formatData setObject:[NSNumber numberWithFloat:size.width] forKey:kW3CMediaFormatWidth];
        // not sure how to get codecs or bitrate???
        // AVMetadataItem
        // AudioFile
      } else {
        NSLog(@"No video tracks found for %@", fullPath);
      }
    } else if ([mimeType rangeOfString:@"audio/"].location != NSNotFound) {
      if (NSClassFromString(@"AVAudioPlayer") != nil) {
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        NSError *err = nil;
        
        AVAudioPlayer *avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&err];
        if (!err) {
          // get the data
          [formatData setObject:[NSNumber numberWithDouble:[avPlayer duration]] forKey:kW3CMediaFormatDuration];
          if ([avPlayer respondsToSelector:@selector(settings)]) {
            NSDictionary *info = [avPlayer settings];
            NSNumber *bitRate = [info objectForKey:AVEncoderBitRateKey];
            if (bitRate) {
              [formatData setObject:bitRate forKey:kW3CMediaFormatBitrate];
            }
          }
        } // else leave data init'ed to 0
      }
    }
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:formatData];
    // NSLog(@"getFormatData: %@", [formatData description]);
  }
  if (bError) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:(int)errorCode];
  }
  if (result) {
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
  }
}

- (NSDictionary*)getMediaDictionaryFromPath:(NSString *)fullPath ofType:(NSString *)type
{
  NSFileManager *fileMgr = [[NSFileManager alloc] init];
  NSMutableDictionary *fileDict = [NSMutableDictionary dictionaryWithCapacity:5];
  
  CDVFile *fs = [self.commandDelegate getCommandInstance:@"File"];
  
  // Get canonical version of localPath
  NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", fullPath]];
  NSURL *resolvedFileURL = [fileURL URLByResolvingSymlinksInPath];
  NSString *path = [resolvedFileURL path];
  
  CDVFilesystemURL *url = [fs fileSystemURLforLocalPath:path];
  
  [fileDict setObject:[fullPath lastPathComponent] forKey:@"name"];
  [fileDict setObject:fullPath forKey:@"fullPath"];
  if (url) {
    [fileDict setObject:[url absoluteURL] forKey:@"localURL"];
  }
  // determine type
  if (!type) {
    id command = [self.commandDelegate getCommandInstance:@"File"];
    if ([command isKindOfClass:[CDVFile class]]) {
      CDVFile *cdvFile = (CDVFile*)command;
      NSString *mimeType = [cdvFile getMimeTypeFromPath:fullPath];
      [fileDict setObject:(mimeType != nil ? (NSObject*)mimeType : [NSNull null]) forKey:@"type"];
    }
  }
  NSDictionary *fileAttrs = [fileMgr attributesOfItemAtPath:fullPath error:nil];
  [fileDict setObject:[NSNumber numberWithUnsignedLongLong:[fileAttrs fileSize]] forKey:@"size"];
  NSDate *modDate = [fileAttrs fileModificationDate];
  NSNumber *msDate = [NSNumber numberWithDouble:[modDate timeIntervalSince1970] * 1000];
  [fileDict setObject:msDate forKey:@"lastModifiedDate"];
  
  return fileDict;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
  // older api calls new one
  [self imagePickerController:picker didFinishPickingMediaWithInfo:editingInfo];
}

/* Called when image/movie is finished recording.
 * Calls success or error code as appropriate
 * if successful, result  contains an array (with just one entry since can only get one image unless build own camera UI) of MediaFile object representing the image
 *      name
 *      fullPath
 *      type
 *      lastModifiedDate
 *      size
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  CDVImagePicker *cameraPicker = (CDVImagePicker*)picker;
  NSString *callbackId = cameraPicker.callbackId;
  
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  
  CDVPluginResult *result = nil;
  
  UIImage *image = nil;
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  if (!mediaType || [mediaType isEqualToString:(NSString*)kUTTypeImage]) {
    // mediaType is nil then only option is UIImagePickerControllerOriginalImage
    if ([UIImagePickerController respondsToSelector:@selector(allowsEditing)] &&
        (cameraPicker.allowsEditing && [info objectForKey:UIImagePickerControllerEditedImage])) {
      image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
      image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
  }
  if (image != nil) {
    // mediaType was image
    result = [self processImage:image type:cameraPicker.mimeType forCallbackId:callbackId];
  } else if ([mediaType isEqualToString:(NSString*)kUTTypeMovie]) {
    // process video
    NSString* moviePath = [(NSURL *)[info objectForKey:UIImagePickerControllerMediaURL] path];
    if (moviePath) {
      result = [self processVideo:moviePath forCallbackId:callbackId];
    }
  }
  if (!result) {
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_INTERNAL_ERR];
  }
  [self.commandDelegate sendPluginResult:result callbackId:callbackId];
  pickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  CDVImagePicker *cameraPicker = (CDVImagePicker*)picker;
  NSString *callbackId = cameraPicker.callbackId;
  
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:CAPTURE_NO_MEDIA_FILES];
  [self.commandDelegate sendPluginResult:result callbackId:callbackId];
  pickerController = nil;
}

@end

@implementation CDVAudioNavigationController

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  // delegate to CVDAudioRecorderViewController
  return [self.topViewController supportedInterfaceOrientations];
}
#else
- (NSUInteger)supportedInterfaceOrientations
{
  // delegate to CVDAudioRecorderViewController
  return [self.topViewController supportedInterfaceOrientations];
}
#endif

@end

@interface CDVAudioRecorderViewController () {
  UIStatusBarStyle _previousStatusBarStyle;
}
@end

@implementation CDVAudioRecorderViewController

- (void)recordingButtonPressed:(UIButton *)button {
  
  if (self.avRecorder.recording) {
    UIApplication.sharedApplication.idleTimerDisabled = NO;
    // stop recording
    [self.avRecorder stop];
    self.isTimed = NO;  // recording was stopped via button so reset isTimed
    // view cleanup will occur in audioRecordingDidFinishRecording
  } else {
    // begin recording
    __block NSError *error = nil;
    
    __weak CDVAudioRecorderViewController *weakSelf = self;
    UIApplication.sharedApplication.idleTimerDisabled = YES;
    
    void (^startRecording)(void) = ^{
      [weakSelf.avSession setCategory:AVAudioSessionCategoryRecord error:&error];
      [weakSelf.avSession setActive:YES error:&error];
      if (error) {
        // can't continue without active audio session
        weakSelf.errorCode = CAPTURE_INTERNAL_ERR;
        [weakSelf dismissAudioView:nil];
      } else {
        if (weakSelf.duration) {
          weakSelf.isTimed = true;
          [weakSelf.avRecorder recordForDuration:[self.duration doubleValue]];
        } else {
          [weakSelf.avRecorder record];
        }
        [weakSelf updateTime];
        //[weakSelf.recordingView updateTimerWithTime:@"0.00"];
        [button setSelected: TRUE];
        weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:weakSelf selector:@selector(updateTime) userInfo:nil repeats:YES];
        weakSelf.doneButton.enabled = NO;
      }
      UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    };
    
    SEL rrpSel = NSSelectorFromString(@"requestRecordPermission:");
    if ([self.avSession respondsToSelector:rrpSel])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self.avSession performSelector:rrpSel withObject:^(BOOL granted){
        if (granted) {
          startRecording();
        } else {
          NSLog(@"Error creating audio session, microphone permission denied.");
          weakSelf.errorCode = CAPTURE_INTERNAL_ERR;
          [weakSelf dismissAudioView:nil];
        }
      }];
#pragma clang diagnostic pop
    } else {
      startRecording();
    }
  }
}

- (id)initWithCommand:(CDVCapture *)theCommand duration:(NSNumber *)theDuration callbackId:(NSString *)theCallbackId
{
  if ((self = [super init])) {
    self.captureCommand = theCommand;
    self.duration = theDuration;
    self.callbackId = theCallbackId;
    self.errorCode = CAPTURE_NO_MEDIA_FILES;
    self.isTimed = self.duration != nil;
    _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    
    return self;
  }
  
  return nil;
}

- (void)loadView
{
  if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    self.edgesForExtendedLayout = UIRectEdgeNone;
  }
  
  // create view and display
  CGRect viewRect = [[UIScreen mainScreen] bounds];
  UIView *tmp = [[UIView alloc] initWithFrame:viewRect];
  
  NSBundle *cdvBundle = [NSBundle bundleForClass:[CDVCapture class]];
  self.recordingView = [[cdvBundle loadNibNamed:@"WaveView"
                                          owner:self
                                        options:nil] objectAtIndex:0];
  [self.recordingView setFrame:CGRectMake(0, 0, viewRect.size.width, viewRect.size.height)];
  
  [self.recordingView setDelegate:self];
  
  [tmp addSubview:self.recordingView];
  
  // make and add done button to navigation bar
  self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAudioView:)];
  [self.doneButton setStyle:UIBarButtonItemStyleDone];
  self.navigationItem.rightBarButtonItem = self.doneButton;
  
  [self setView:tmp];
  [self updateTime];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  NSError *error = nil;
  
  if (self.avSession == nil) {
    // create audio session
    self.avSession = [AVAudioSession sharedInstance];
    if (error) {
      // return error if can't create recording audio session
      NSLog(@"error creating audio session: %@", [[error userInfo] description]);
      self.errorCode = CAPTURE_INTERNAL_ERR;
      [self dismissAudioView:nil];
    }
  }
  
  // create file to record to in temporary dir
  
  NSString *docsPath = [NSTemporaryDirectory() stringByStandardizingPath]; // use file system temporary directory
  NSError *err = nil;
  NSFileManager *fileMgr = [[NSFileManager alloc] init];
  
  // generate unique file name
  NSString *filePath;
  int i = 1;
  do {
    filePath = [NSString stringWithFormat:@"%@/audio_%03d.wav", docsPath, i++];
  } while ([fileMgr fileExistsAtPath:filePath]);
  
  NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
  
  // create AVAudioPlayer
  NSDictionary *settings = @{
    AVSampleRateKey: @44100.0,
    AVFormatIDKey:[NSNumber numberWithInt: kAudioFormatLinearPCM],
    AVNumberOfChannelsKey: @2,
    AVEncoderAudioQualityKey:[NSNumber numberWithInt: AVAudioQualityMax],
    AVLinearPCMBitDepthKey:@16,
    AVLinearPCMIsFloatKey:@NO,
    AVLinearPCMIsBigEndianKey:@NO
  };
  self.avRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:settings error:&err];
  [self.avRecorder setDelegate:self];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&err];
  [self.recordingView setRecorder:self.avRecorder];
  [self.recordingView setDelegate:self];
  
  if (err) {
    NSLog(@"Failed to initialize AVAudioRecorder: %@\n", [err localizedDescription]);
    self.avRecorder = nil;
    // return error
    self.errorCode = CAPTURE_INTERNAL_ERR;
    [self dismissAudioView:nil];
  } else {
    [self.avRecorder prepareToRecord];
    [self.avRecorder setMeteringEnabled:YES];
    
    self.recordButton.enabled = YES;
    self.doneButton.enabled = YES;
  }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  UIInterfaceOrientationMask orientation = UIInterfaceOrientationMaskPortrait;
  UIInterfaceOrientationMask supported = [self.captureCommand.viewController supportedInterfaceOrientations];
  
  orientation = orientation | (supported & UIInterfaceOrientationMaskPortraitUpsideDown);
  return orientation;
}
#else
- (NSUInteger)supportedInterfaceOrientations
{
  NSUInteger orientation = UIInterfaceOrientationMaskPortrait; // must support portrait
  NSUInteger supported = [captureCommand.viewController supportedInterfaceOrientations];
  
  orientation = orientation | (supported & UIInterfaceOrientationMaskPortraitUpsideDown);
  return orientation;
}
#endif

- (void)viewDidUnload
{
  [self setView:nil];
  [self.captureCommand setInUse:NO];
}

/*
 * helper method to clean up when stop recording
 */
- (void)stopRecordingCleanup
{
  if (self.avRecorder.recording) {
    [self.avRecorder stop];
  }
  [self.recordingView.recordButton setSelected:FALSE];
  self.doneButton.enabled = YES;
  if (self.avSession) {
    // deactivate session so sounds can come through
    [self.avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.avSession setActive:NO error:nil];
  }
  if (self.duration && self.isTimed) {
    // VoiceOver announcement so user knows timed recording has finished
    //BOOL isUIAccessibilityAnnouncementNotification = (&UIAccessibilityAnnouncementNotification != NULL);
    if (UIAccessibilityAnnouncementNotification) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500ull * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, PluginLocalizedString(self.captureCommand, @"timed recording complete", nil));
      });
    }
  } else {
    // issue a layout notification change so that VO will reannounce the button label when recording completes
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [self dismissAudioView:self];
  [self stopRecordingCleanup];
}

- (void)dismissAudioView:(id)sender
{
  // called when done button pressed or when error condition to do cleanup and remove view
  [[self.captureCommand.viewController.presentedViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  
  if (!self.pluginResult) {
    // return error
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:(int)self.errorCode];
  }
  
  self.avRecorder = nil;
  [self.avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
  [self.avSession setActive:NO error:nil];
  [self.captureCommand setInUse:NO];
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  // return result
  [self.captureCommand.commandDelegate sendPluginResult:self.pluginResult callbackId:self.callbackId];
  
  if (IsAtLeastiOSVersion(@"7.0")) {
    [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle];
  }
}

- (void)updateTime
{
  NSString *timeToOutput = nil;
  
  if (self.isTimed) {
    timeToOutput = [NSString stringWithFormat:@"%@ / %@", [self formatTime:self.avRecorder.currentTime], [self formatTime: [self.duration doubleValue]]];
  } else {
    timeToOutput = [self formatTime:self.avRecorder.currentTime];
  }
  
  // update the label with the elapsed time
  [self.recordingView updateTimerWithTime:timeToOutput];
}

- (NSString *)formatTime:(int)interval
{
  // is this format universal?
  int secs = interval % 60;
  int min = interval / 60;
  
  if (interval < 60) {
    return [NSString stringWithFormat:@"0:%02d", interval];
  } else {
    return [NSString stringWithFormat:@"%d:%02d", min, secs];
  }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
  // may be called when timed audio finishes - need to stop time and reset buttons
  [self.timer invalidate];
  [self stopRecordingCleanup];
  [self.doneButton setEnabled:TRUE];
  // generate success result
  if (flag) {
    NSString *filePath = [self.avRecorder.url path];
    // NSLog(@"filePath: %@", filePath);
    NSDictionary *fileDict = [self.captureCommand getMediaDictionaryFromPath:filePath ofType:@"audio/wav"];
    NSArray *fileArray = [NSArray arrayWithObject:fileDict];
    
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
  } else {
    self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageToErrorObject:CAPTURE_INTERNAL_ERR];
  }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder*)recorder error:(NSError*)error
{
  [self.timer invalidate];
  [self stopRecordingCleanup];
  [self.recordingView.recordButton setEnabled: FALSE];
  [self.doneButton setEnabled:TRUE];
  
  NSLog(@"error recording audio");
  self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageToErrorObject:CAPTURE_INTERNAL_ERR];
  [self dismissAudioView:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated
{
  if (IsAtLeastiOSVersion(@"7.0")) {
    [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
  }
  [super viewWillAppear:animated];
}

@end
