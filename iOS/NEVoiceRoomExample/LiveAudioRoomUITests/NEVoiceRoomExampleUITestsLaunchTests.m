// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@interface NEVoiceRoomExampleUITestsLaunchTests : XCTestCase

@end

@implementation NEVoiceRoomExampleUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
  return YES;
}

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)testLaunch {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  [app launch];

  // Insert steps here to perform after app launch but before taking a screenshot,
  // such as logging into a test account or navigating somewhere in the app

  XCTAttachment *attachment =
      [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
  attachment.name = @"Launch Screen";
  attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
  [self addAttachment:attachment];
}

@end
