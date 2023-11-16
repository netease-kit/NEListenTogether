// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEOrderSong/NEOrderSong-Swift.h>
#import <SDWebImage/SDWebImage.h>
#import "NEListenTogetherInnerSingleton.h"
#import "NEListenTogetherLocalized.h"
#import "NEListenTogetherPickSongEngine.h"
#import "NEListenTogetherToast.h"
#import "NEListenTogetherUI.h"
#import "NEListenTogetherUILog.h"
#import "NEListenTogetherUIManager.h"
#import "NEListenTogetherViewController+Seat.h"
#import "NEListenTogetherViewController+Utils.h"
#import "NEVoiceRoomKit/NEVoiceRoomKit-Swift.h"
#import "NSArray+NEListenTogetherUIExtension.h"
#import "UIView+NEListenTogetherUIToast.h"
@import NEOrderSong;

@implementation NEListenTogetherViewController (Utils)
- (void)joinRoom {
  self.roomHeaderView.title = self.detail.liveModel.liveTopic;
  NEJoinVoiceRoomParams *param = [NEJoinVoiceRoomParams new];
  param.nick = NEListenTogetherUIManager.sharedInstance.nickname;
  param.roomUuid = self.detail.liveModel.roomUuid;
  param.role = self.role;
  if (self.role == NEVoiceRoomRoleHost) {
    [self.micQueueView singleListen];
  } else {
    [self.micQueueView togetherListen];
  }
  param.liveRecordId = self.detail.liveModel.liveRecordId;
  NEListenTogetherInnerSingleton.singleton.roomInfo = self.detail;
  __weak typeof(self) weakSelf = self;
  [NEVoiceRoomKit.getInstance
      joinRoom:param
       options:[NEJoinVoiceRoomOptions new]
      callback:^(NSInteger code, NSString *_Nullable msg, NEVoiceRoomInfo *_Nullable info) {
        weakSelf.detail = info;
        if (code != 0) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [NEListenTogetherToast showToast:msg];
          });
          [weakSelf closeRoom];
          return;
        }
        // 版权设置为听歌场景
        [[NEOrderSong getInstance] setSongScene:TYPE_LISTENING_TO_MUSIC];
        // 开启音量上报
        [NEVoiceRoomKit.getInstance enableAudioVolumeIndicationWithEnable:true interval:1000];
        [[NEOrderSong getInstance] configRoomSetting:weakSelf.detail.liveModel.roomUuid
                                        liveRecordId:weakSelf.detail.liveModel.liveRecordId];
        /// 内部使用
        NEListenTogetherInnerSingleton.singleton.roomInfo = info;
        dispatch_async(dispatch_get_main_queue(), ^{
          weakSelf.roomHeaderView.title = info.liveModel.liveTopic;
          weakSelf.roomHeaderView.onlinePeople = NEVoiceRoomKit.getInstance.allMemberList.count;
        });
        // 默认的查询动作
        [weakSelf getSeatInfoWhenRejoinChatRoom];
      }];
}
- (void)unmuteAudio:(BOOL)showToast {
  [NEVoiceRoomKit.getInstance
      unmuteMyAudio:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (code != 0) {
            [NEListenTogetherToast showToast:NELocalizedString(@"麦克风打开失败")];
          } else {
            [self getSeatInfo];
            if (!showToast) return;
            [NEListenTogetherToast showToast:NELocalizedString(@"麦克风已打开")];
          }
        });
      }];
}

/// 关闭麦克风
- (void)muteAudio:(BOOL)showToast {
  [NEVoiceRoomKit.getInstance
      muteMyAudio:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (code != 0) {
            if (code != 1021) {
              [NEListenTogetherToast showToast:NELocalizedString(@"静音失败")];
            }
            return;
          }
          [self getSeatInfo];
          if (!showToast) return;
          [NEListenTogetherToast showToast:NELocalizedString(@"麦克风已关闭")];
        });
      }];
}
- (void)addNetworkObserver {
  [self.reachability startNotifier];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(networkStatusChange)
                                             name:kNEListenTogetherReachabilityChangedNotification
                                           object:nil];
}
- (void)destroyNetworkObserver {
  [self.reachability stopNotifier];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}
- (void)networkStatusChange {
  // 无网络
  if ([self.reachability currentReachabilityStatus] != NotReachable) {
    [NEListenTogetherUILog infoLog:ListenTogetherUILog desc:@"网络变化  有网"];

  } else {
    [NEListenTogetherUILog infoLog:ListenTogetherUILog desc:@"网络变化  有网"];
    [NEListenTogetherToast showToast:NELocalizedString(@"网络断开")];
  }
}
- (void)checkMicAuthority {
  [NEListenTogetherAuthorityHelper checkMicAuthority];
}
- (NSArray<NEVoiceRoomSeatItem *> *)simulatedSeatData {
  NSMutableArray *datas = @[].mutableCopy;
  for (NSInteger i = 0; i < 8; i++) {
    NEVoiceRoomSeatItem *item = [[NEVoiceRoomSeatItem alloc] init];
    item.index = i + 2;
    [datas addObject:item];
  }
  return datas.copy;
}

- (BOOL)isAnchor {
  return self.role == NEVoiceRoomRoleHost;
}

- (void)handleMuteOperation:(BOOL)isMute {
  if (isMute) {
    if ([self isAnchor]) {
      [self muteAudio:YES];
    } else {
      if (NEVoiceRoomKit.getInstance.localMember.isAudioBanned) {
        [NEListenTogetherToast
            showToast:NELocalizedString(@"您已被主播屏蔽语音，暂不能操作麦克风")];
      } else {
        [self muteAudio:YES];
      }
    }
  } else {
    if ([self isAnchor]) {
      [self unmuteAudio:YES];
    } else {
      if (NEVoiceRoomKit.getInstance.localMember.isAudioBanned) {
        [NEListenTogetherToast
            showToast:NELocalizedString(@"您已被主播屏蔽语音，暂不能操作麦克风")];
      } else {
        [self unmuteAudio:YES];
      }
    }
  }
}

- (NSString *)fetchLyricContentWithSongId:(NSString *)songId channel:(SongChannel)channel {
  return [[NEOrderSong getInstance] getLyric:songId channel:channel];
}
- (NSString *)fetchPitchContentWithSongId:(NSString *)songId channel:(SongChannel)channel {
  return [[NEOrderSong getInstance] getPitch:songId channel:channel];
}
- (NSString *)fetchOriginalFilePathWithSongId:(NSString *)songId channel:(SongChannel)channel {
  return [[NEOrderSong getInstance] getSongURI:songId channel:channel songResType:TYPE_ORIGIN];
}
- (NSString *)fetchAccompanyFilePathWithSongId:(NSString *)songId channel:(SongChannel)channel {
  return [[NEOrderSong getInstance] getSongURI:songId channel:channel songResType:TYPE_ACCOMP];
}

/// 获取观众userUuid
- (NSString *)getAnotherAccount {
  NSString *anotherUuid;
  for (NEVoiceRoomMember *member in [NEVoiceRoomKit getInstance].allMemberList) {
    if (![member.account isEqualToString:self.detail.anchor.userUuid]) {
      anotherUuid = member.account;
      break;
    }
  }
  return anotherUuid;
}
@end
