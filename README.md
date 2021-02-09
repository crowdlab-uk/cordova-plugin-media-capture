<?xml version="1.0" encoding="UTF-8"?>
<!--
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
-->

<plugin xmlns="http://apache.org/cordova/ns/plugins/1.0"
xmlns:android="http://schemas.android.com/apk/res/android"
           id="cordova-plugin-media-capture"
      version="3.0.4-dev">
    <name>Capture</name>

    <description>Cordova Media Capture Plugin</description>
    <license>Apache 2.0</license>
    <keywords>cordova,media,capture</keywords>
    <repo>https://github.com/apache/cordova-plugin-media-capture</repo>
    <issue>https://github.com/apache/cordova-plugin-media-capture/issues</issue>

    <engines>
        <engine name="cordova-android" version=">=6.3.0" />
    </engines>

    <dependency id="cordova-plugin-file" version="^6.0.0" />

    <js-module src="www/CaptureAudioOptions.js" name="CaptureAudioOptions">
        <clobbers target="CaptureAudioOptions" />
    </js-module>

    <js-module src="www/CaptureImageOptions.js" name="CaptureImageOptions">
        <clobbers target="CaptureImageOptions" />
    </js-module>

    <js-module src="www/CaptureVideoOptions.js" name="CaptureVideoOptions">
        <clobbers target="CaptureVideoOptions" />
    </js-module>

    <js-module src="www/CaptureError.js" name="CaptureError">
        <clobbers target="CaptureError" />
    </js-module>

    <js-module src="www/MediaFileData.js" name="MediaFileData">
        <clobbers target="MediaFileData" />
    </js-module>

    <js-module src="www/MediaFile.js" name="MediaFile">
        <clobbers target="MediaFile" />
    </js-module>

    <js-module src="www/helpers.js" name="helpers">
        <runs />
    </js-module>

    <js-module src="www/capture.js" name="capture">
        <clobbers target="navigator.device.capture" />
    </js-module>

    <!-- android -->
    <platform name="android">
        <config-file target="res/xml/config.xml" parent="/*">
            <feature name="Capture" >
                <param name="android-package" value="org.apache.cordova.mediacapture.Capture"/>
            </feature>
        </config-file>

        <config-file target="AndroidManifest.xml" parent="/*">
            <uses-permission android:name="android.permission.RECORD_AUDIO" />
            <uses-permission android:name="android.permission.RECORD_VIDEO"/>
            <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
            <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
        </config-file>

        <source-file src="src/android/Capture.java" target-dir="src/org/apache/cordova/mediacapture" />
        <source-file src="src/android/FileHelper.java" target-dir="src/org/apache/cordova/mediacapture" />
        <source-file src="src/android/PendingRequests.java" target-dir="src/org/apache/cordova/mediacapture" />

        <js-module src="www/android/init.js" name="init">
            <runs />
        </js-module>
    </platform>

    <!-- ios -->
    <platform name="ios">
        <config-file target="config.xml" parent="/*">
            <feature name="Capture">
                <param name="ios-package" value="CDVCapture" />
            </feature>
        </config-file>
        <header-file src="src/ios/CDVCapture.h" />
        <source-file src="src/ios/CDVCapture.m" />
        <header-file src="src/ios/RecordButton.h" />
        <source-file src="src/ios/RecordButton.m" />
        <header-file src="src/ios/RecordingView.h" />
        <source-file src="src/ios/RecordingView.m" />
        <header-file src="src/ios/VideoRecordingViewController.h" />
        <source-file src="src/ios/VideoRecordingViewController.m" />
        <header-file src="src/ios/SCSiriWaveformView.h" />
        <source-file src="src/ios/SCSiriWaveformView.m" />
        <resource-file src="src/ios/WaveView.xib" />
        <resource-file src="src/ios/CDVCapture.bundle" />

        <framework src="CoreGraphics.framework" />
        <framework src="MobileCoreServices.framework" />
        <pods-config ios-min-version="12.0" use-frameworks="true">
        </pods-config>
        <pod name="CameraKit-iOS" />
    </platform>

    <!-- windows -->
    <platform name="windows">

        <config-file target="package.appxmanifest" parent="/Package/Capabilities">
            <DeviceCapability Name="microphone" />
            <DeviceCapability Name="webcam" />
        </config-file>

        <js-module src="src/windows/MediaFile.js" name="MediaFile2">
            <merges target="MediaFile" />
        </js-module>

        <js-module src="src/windows/CaptureProxy.js" name="CaptureProxy">
            <runs />
        </js-module>
    </platform>

    <!-- browser -->
    <platform name="browser">
        <!-- this overrides navigator.device.capture namespace with browser-specific implementation -->
        <js-module src="src/browser/CaptureProxy.js" name="CaptureProxy">
            <runs />
        </js-module>
    </platform>

</plugin>
