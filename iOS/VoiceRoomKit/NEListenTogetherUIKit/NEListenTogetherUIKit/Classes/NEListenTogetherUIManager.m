// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEListenTogetherUIManager.h"
#import <NEVoiceRoomKit/NEVoiceRoomLog.h>
#import "NEListenTogetherUILog.h"

@interface NEListenTogetherUIManager () <NEVoiceRoomAuthListener>

@end

@implementation NEListenTogetherUIManager

+ (NEListenTogetherUIManager *)sharedInstance {
  static NEListenTogetherUIManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEListenTogetherUIManager alloc] init];
  });
  return instance;
}
- (instancetype)init {
  self = [super init];
  if (self) {
  }
  return self;
}
- (void)initializeWithConfig:(NEVoiceRoomKitConfig *)config
                    configId:(NSInteger)configId
                    callback:(void (^)(NSInteger, NSString *_Nullable, id _Nullable))callback {
  self.config = config;
  self.configId = configId;
  [NEVoiceRoomKit.getInstance initializeWithConfig:config callback:callback];
  [NEVoiceRoomLog setUp:config.appKey];
  [NEListenTogetherUILog setUp:config.appKey];
}

- (void)loginWithAccount:(NSString *)account
                   token:(NSString *)token
                nickname:(NSString *)nickname
                callback:(void (^)(NSInteger, NSString *_Nullable, id _Nullable))callback {
  self.nickname = nickname;
  [NEVoiceRoomKit.getInstance login:account token:token callback:callback];
}

- (void)logoutWithCallback:(void (^)(NSInteger, NSString *_Nullable, id _Nullable))callback {
  [NEVoiceRoomKit.getInstance logoutWithCallback:callback];
}

- (bool)isLoggedIn {
  return [[NEVoiceRoomKit getInstance] isLoggedIn];
}

- (void)onVoiceRoomAuthEvent:(enum NEVoiceRoomAuthEvent)event {
  if ([self.delegate respondsToSelector:@selector(onListenTogetherClientEvent:)]) {
    [self.delegate onListenTogetherClientEvent:(NEListenTogetherClientEvent)event];
  }
}

- (UINavigationController *)createViewController {
  UINavigationController *c =
      [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
  c.modalPresentationStyle = UIModalPresentationFullScreen;
  return c;
}

- (UINavigationController *)roomListViewController {
  UINavigationController *c =
      [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
  if (@available(iOS 13.0, *)) {
    c.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
  }
  c.modalPresentationStyle = UIModalPresentationFullScreen;
  return c;
}

@end
