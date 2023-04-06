// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEListenTogetherUIKit/NEListenTogetherUIManager.h>
#import <NEOrderSong/NEOrderSong-Swift.h>
#import "AppDelegate+VoiceRoom.h"
#import "AppKey.h"
@interface AppDelegate (VoiceRoom) <NEListenTogetherUIDelegate>

@end

@implementation AppDelegate (VoiceRoom)
- (NSString *)getAppkey {
  if (isOverSea) {
    return APP_KEY_OVERSEA;
  } else {
    return APP_KEY_MAINLAND;
  }
}
- (void)vr_setupLoginSDK {
  [[NEListenTogetherUIManager sharedInstance]
   loginWithAccount:accountId
   token:accessToken
   nickname:@"nickname"
   resumeLogin:NO
   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){
    if (code == 0) {
      /// 登录后初始化点歌台的配置
      [[NEOrderSong getInstance] loginInitConfig:accountId
                                           token:accessToken
                                        callback:nil];
    }
  }];
}

- (void)vr_setupVoiceRoom {
  BOOL isOutsea = isOverSea;
  NEListenTogetherKitConfig *listenTogetherConfig = [[NEListenTogetherKitConfig alloc] init];
  listenTogetherConfig.appKey = [self getAppkey];
  if (isOutsea) {
    listenTogetherConfig.extras = @{@"serverUrl" : @"oversea"};
  }
  [[NEListenTogetherUIManager sharedInstance]
   initializeWithConfig:listenTogetherConfig
   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable objc){
    if (code != 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self vr_setupLoginSDK];
    });
  }];
  [NEListenTogetherUIManager sharedInstance].delegate = self;
  
  /// 点歌台属配置初始化
  NEOrderSongConfig *orderSongConfig = [[NEOrderSongConfig alloc] init];
  orderSongConfig.appKey = [self getAppkey];
  if (isOutsea) {
    orderSongConfig.extras = @{@"serverUrl" : @"oversea"};
  }
  [[NEOrderSong getInstance]
   initializeWithConfig:orderSongConfig
   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable objc){
    
  }];
}

@end
