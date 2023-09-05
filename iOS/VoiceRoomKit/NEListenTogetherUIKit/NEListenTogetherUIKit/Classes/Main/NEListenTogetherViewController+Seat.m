// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECoreKit/NSObject+YXModel.h>
#import <NEOrderSong/NEOrderSong-Swift.h>
#import "NEListenTogetherInnerSingleton.h"
#import "NEListenTogetherLocalized.h"
#import "NEListenTogetherPickSongEngine.h"
#import "NEListenTogetherToast.h"
#import "NEListenTogetherViewController+Seat.h"
#import "NEListenTogetherViewController+Utils.h"
#import "NSArray+NEListenTogetherUIExtension.h"
#import "UIView+NEListenTogetherUIToast.h"

@implementation NEListenTogetherViewController (Seat)

- (void)getSeatInfo {
  [NEVoiceRoomKit.getInstance getSeatInfo:^(NSInteger code, NSString *_Nullable msg,
                                            NEVoiceRoomSeatInfo *_Nullable seatInfo) {
    if (code == 0 && seatInfo) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.micQueueView setAnchorMicInfo:[NEListenTogetherInnerSingleton.singleton
                                                fetchAnchorItem:seatInfo.seatItems]];
        self.micQueueView.datas =
            [NEListenTogetherInnerSingleton.singleton fetchAudienceSeatItems:seatInfo.seatItems];
      });
    }
  }];
}

- (void)getSeatInfoWhenRejoinChatRoom {
  [[NEOrderSong getInstance] getSongTokenWithCallback:^(NSInteger code, NSString *_Nullable msg,
                                                        NEOrderSongDynamicToken *_Nullable token) {
    if (code == 0) {
      [[NEOrderSong getInstance] renewToken:token.accessToken];
    }
  }];
  // 获取房间内播放歌曲
  [[NEOrderSong getInstance] queryPlayingSongInfo:^(NSInteger code, NSString *_Nullable msg,
                                                    NEOrderSongPlayMusicInfo *_Nullable songModel) {
    if (code == NEVoiceRoomErrorCode.success) {
      NEOrderSongSongModel *model = [[NEOrderSongSongModel alloc] init];
      model.playMusicInfo = songModel;
      BOOL sameSong = NO;
      if ([NEListenTogetherPickSongEngine sharedInstance].currrentSongModel.playMusicInfo.songId &&
          [[NEListenTogetherPickSongEngine sharedInstance].currrentSongModel.playMusicInfo.songId
              isEqualToString:songModel.songId]) {
        sameSong = YES;
      }
      [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel = model;
      /// 做同步处理，等同中途加入，不需要ready
      if (songModel.oc_musicStatus == 3) {
        // 一方已经ready，需要发送ready
        self.playingAction = PlayingAction_default;
      } else {
        self.playingAction = PlayingAction_join_half_way;
      }
      /// 获取已点列表数据
      [[NEListenTogetherPickSongEngine sharedInstance]
          getKaraokeSongOrderedList:^(NSError *_Nullable error) {
            /// 判断当前房间是否存在播放中歌曲
            if (songModel.songId.length > 0) {
              // 房间内存在播放中歌曲
              if (sameSong) {
                /// 房间内播放歌曲和本地播放中的是同一首
                /// 同步进度
                NSString *userUuid;
                if (self.isAnchor) {
                  /// 是主播
                  userUuid = [self getAnotherAccount];
                } else {
                  /// 是连麦者
                  userUuid = self.detail.anchor.userUuid;
                }
                if (!userUuid) {
                  return;
                }
                NSString *dataString =
                    @{@"userUuid" : NEVoiceRoomKit.getInstance.localMember.account}
                        .yx_modelToJSONString;
                [[NEVoiceRoomKit getInstance] sendCustomMessage:userUuid
                                                      commandId:NEOrderSongCustomActionGetPosition
                                                           data:dataString
                                                       callback:nil];
              } else {
                BOOL matched = NO;
                for (NEOrderSongResponse *model in [NEListenTogetherPickSongEngine sharedInstance]
                         .pickedSongArray) {
                  if (matched) {
                    // 预加载歌曲
                    [[NEOrderSong getInstance] preloadSong:model.orderSong.songId
                                                   channel:(int)model.orderSong.oc_channel
                                                   observe:self];
                  }
                  if ([model.orderSong.songId isEqualToString:songModel.songId] &&
                      (model.orderSong.oc_channel == songModel.oc_channel)) {
                    matched = YES;
                    // 当前存在播放中歌曲
                    [[NEOrderSong getInstance] preloadSong:songModel.songId
                                                   channel:(int)songModel.oc_channel
                                                   observe:self];
                  }
                }
              }
            }
          }];
    }
  }];
}
- (void)updateAudienceToast:(NSArray *)seatItems {
  if (![self isAnchor]) {
    // 观众
    [self configSelfSeatStatusWithSeatItems:seatItems];
    bool audienceOnSeat = false;
    for (NEVoiceRoomSeatItem *item in seatItems) {
      if ([item.user isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
        /// 当前用户
        audienceOnSeat = true;
        if (item.status == NEVoiceRoomSeatItemStatusTaken) {
          /// 已上麦，上麦行为
          [self.view dismissToast];
        } else if (item.status == NEVoiceRoomSeatItemStatusWaiting) {
          /// 不做任何操作
        }
        break;
      }
    }
    if (!audienceOnSeat) {
      /// 如果不在麦上，则处理 toast
      [self.view dismissToast];
    }
  }
}
- (void)anchorOperationSeatItem:(NEVoiceRoomSeatItem *)seatItem {
  // 主播点击自己
  if ([seatItem.user
          isEqualToString:NEListenTogetherInnerSingleton.singleton.roomInfo.anchor.userUuid])
    return;
  NSMutableArray *actionTypes = @[].mutableCopy;
  switch (seatItem.status) {
    case NEVoiceRoomSeatItemStatusInitial: {  // 麦上无人
      // 抱麦、关闭
      [actionTypes
          addObjectsFromArray:@[ @(NEUIAlertActionTypeInviteMic), @(NEUIAlertActionTypeCloseMic) ]];
    } break;
    case NEVoiceRoomSeatItemStatusTaken: {  // 麦位被占
      NEVoiceRoomMember *member = [self getMemberOnTheSeat:seatItem];
      if (member.isAudioBanned) {
        // 踢人、解除音频、关闭
        [actionTypes addObjectsFromArray:@[
          @(NEUIAlertActionTypeKickMic), @(NEUIAlertActionTypeCancelMaskMic),
          @(NEUIAlertActionTypeCloseMic)
        ]];
      } else {
        // 踢人、屏蔽音频、关闭
        [actionTypes addObjectsFromArray:@[
          @(NEUIAlertActionTypeKickMic), @(NEUIAlertActionTypeFinishedMaskMic),
          @(NEUIAlertActionTypeCloseMic)
        ]];
      }
    } break;
    case NEVoiceRoomSeatItemStatusClosed: {  // 麦位关闭
      [actionTypes addObject:@(NEUIAlertActionTypeOpenMic)];
    } break;
    default:
      break;
  }
  [self.alertView showWithTypes:actionTypes info:seatItem];
}
- (void)audienceOperationSeatItem:(NEVoiceRoomSeatItem *)seatItem {
  switch (seatItem.status) {
    case NEVoiceRoomSeatItemStatusWaiting: {  // 等待中
      if (![seatItem.user isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
        [NEListenTogetherToast
            showToast:[NSString stringWithFormat:@"%@ %@", seatItem.userName,
                                                 NELocalizedString(@"正在申请该麦位")]];
      }
      return;
    }
    case NEVoiceRoomSeatItemStatusTaken: {  // 被占
      if ([seatItem.user isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
        [self.alertView showWithTypes:@[ @(NEUIAlertActionTypeDropMic) ] info:seatItem];
      }
    } break;
    case NEVoiceRoomSeatItemStatusClosed: {  // 关闭
      [NEListenTogetherToast showToast:NELocalizedString(@"该麦位已关闭")];
      return;
    } break;
    case NEVoiceRoomSeatItemStatusInitial: {  // 无人
      switch (self.selfStatus) {
        case NEVoiceRoomSeatItemStatusInitial: {
          // 申请上麦
          __weak typeof(self) weakSelf = self;
          [NEVoiceRoomKit.getInstance
              submitSeatRequest:seatItem.index
                      exclusive:YES
                       callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                           if (code == 0) {
                             [weakSelf.view
                                 showToastWithMessage:NELocalizedString(@"已申请上麦，等待通过...")
                                                state:NEUIToastCancel
                                               cancel:^{
                                                 [weakSelf.alertView showWithTypes:@[
                                                   @(NEUIAlertActionTypeCancelOnMicRequest)
                                                 ]
                                                                              info:seatItem];
                                               }];
                           } else {
                             [NEListenTogetherToast
                                 showToast:NELocalizedString(@"该麦位正在被操作")];
                           }
                         });
                       }];
        } break;
        case NEVoiceRoomSeatItemStatusWaiting: {
          [NEListenTogetherToast
              showToast:NELocalizedString(@"该麦位正在被申请,请尝试申请其他麦位")];
        } break;
        default:
          break;
      }
    } break;
    default:
      break;
  }
}

#pragma mark------------------------ NEVoiceRoomListener ------------------------

- (void)onSeatListChanged:(NSArray<NEVoiceRoomSeatItem *> *)seatItems {
  [self configSelfSeatStatusWithSeatItems:seatItems];
  // 刷新UI
  [self.micQueueView
      setAnchorMicInfo:[NEListenTogetherInnerSingleton.singleton fetchAnchorItem:seatItems]];
  self.micQueueView.datas =
      [NEListenTogetherInnerSingleton.singleton fetchAudienceSeatItems:seatItems];
  dispatch_async(dispatch_get_main_queue(), ^{
    if (![self isAnchor]) {
      NEVoiceRoomSeatItem *selfSeat = [seatItems ne_find:^BOOL(NEVoiceRoomSeatItem *obj) {
        return [obj.user isEqualToString:[NEVoiceRoomKit getInstance].localMember.account];
      }];
      if (selfSeat && selfSeat.status == NEVoiceRoomSeatItemStatusTaken) {
        // 自己已经在麦上，更新底部工具栏
        [self.roomFooterView updateAudienceOperatingButton:YES];
        self.context.rtcConfig.micOn = [NEVoiceRoomKit getInstance].localMember.isAudioOn;
      } else {
        [self.roomFooterView updateAudienceOperatingButton:NO];
      }
    }
  });
}

- (void)onSeatLeave:(NSInteger)seatIndex account:(NSString *)account {
  [self notifityMessage:NELocalizedString(@"已下麦") account:account];
  if (![self isAnchor] && [self isSelfWithSeatAccount:account]) {
    [NEListenTogetherToast showToast:NELocalizedString(@"您已下麦")];
    [self.roomFooterView updateAudienceOperatingButton:NO];
  }
}
- (void)onSeatKicked:(NSInteger)seatIndex
             account:(NSString *)account
           operateBy:(NSString *)operateBy {
  [self notifityMessage:NELocalizedString(@"已被主播请下麦位") account:account];
  if ([self isAnchor]) {
    NEVoiceRoomMember *member =
        [NEVoiceRoomKit.getInstance.allMemberList ne_find:^BOOL(NEVoiceRoomMember *obj) {
          return [account isEqualToString:obj.account];
        }];
    if (!member) return;
    [NEListenTogetherToast
        showToast:[NSString
                      stringWithFormat:NELocalizedString(@"已将\"%@\"踢下麦位"), member.name]];
    return;
  }
  if ([self isSelfWithSeatAccount:account]) {
    [NEListenTogetherToast showToast:NELocalizedString(@"您已被主播踢下麦")];
    [self.view dismissToast];
    [self.roomFooterView updateAudienceOperatingButton:NO];
  }
  NSLog(@"从麦位上被踢");
}

- (void)onSeatRequestCancelled:(NSInteger)seatIndex account:(NSString *)account {
  NSLog(@"取消申请麦位");
  [self notifityMessage:NELocalizedString(@"已取消申请上麦") account:account];
  if ([account isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
    [self.view dismissToast];
  }
}
- (void)onSeatRequestSubmitted:(NSInteger)seatIndex account:(NSString *)account {
  [self notifityMessage:[NSString stringWithFormat:@"%@(%zd)", NELocalizedString(@"申请上麦"),
                                                   seatIndex - 1]
                account:account];
  // 房主
  if ([self isAnchor]) {
    if ([account isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) return;
  }
}
- (void)onSeatRequestApproved:(NSInteger)seatIndex
                      account:(NSString *)account
                    operateBy:(NSString *)operateBy
                  isAutoAgree:(BOOL)isAutoAgree {
  [self notifityMessage:NELocalizedString(@"已上麦") account:account];
  if (![account isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) return;
  [self.view dismissToast];
  [self.roomFooterView updateAudienceOperatingButton:YES];
  NSLog(@"房主同意请求");
}
- (void)onSeatRequestRejected:(NSInteger)seatIndex
                      account:(NSString *)account
                    operateBy:(NSString *)operateBy {
  [self notifityMessage:NELocalizedString(@"申请麦位已被拒绝") account:account];
  [self getSeatInfo];
  if ([self isAnchor]) return;
  if (![account isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) return;
  [NEListenTogetherToast showToast:NELocalizedString(@"你的申请已被拒绝")];
  [self.view dismissToast];
  NSLog(@"房主拒绝请求");
}
- (void)onSeatInvitationAccepted:(NSInteger)seatIndex
                         account:(NSString *)account
                     isAutoAgree:(BOOL)isAutoAgree {
  [self notifityMessage:NELocalizedString(@"已上麦") account:account];
  if ([self isAnchor]) {
    NEVoiceRoomMember *member =
        [NEVoiceRoomKit.getInstance.allMemberList ne_find:^BOOL(NEVoiceRoomMember *obj) {
          return [account isEqualToString:obj.account];
        }];
    if (!member) return;
    return;
  }
  if ([self isSelfWithSeatAccount:account]) {
    [self.roomFooterView updateAudienceOperatingButton:YES];
    [self.view dismissToast];
  }
}

- (void)onMemberAudioMuteChanged:(NEVoiceRoomMember *)member
                            mute:(BOOL)mute
                       operateBy:(NEVoiceRoomMember *)operateBy {
  [self getSeatInfo];
}
- (void)onMemberAudioBanned:(NEVoiceRoomMember *)member banned:(BOOL)banned {
  self.micQueueView.datas = self.micQueueView.datas;
  NSString *anchorTitle = banned ? NELocalizedString(@"该麦位语音已被屏蔽，无法发言")
                                 : NELocalizedString(@"该麦位已\"解除语音屏蔽\"");
  if ([self isAnchor]) {
    [NEListenTogetherToast showToast:anchorTitle];
    return;
  }
  if (![NEVoiceRoomKit.getInstance.localMember.account isEqualToString:member.account]) {
    return;
  }
  NSString *audienceTitle =
      banned ? NELocalizedString(@"该麦位被主播\"屏蔽语音\"\n现在您已无法进行语音互动")
             : NELocalizedString(@"该麦位被主播\"解除语音屏蔽\"\n现在您可以在此进行语音互动了");
  if ([self isSelfWithSeatAccount:member.account]) {
    [NEListenTogetherToast showToast:audienceTitle];
  }
}
- (NEVoiceRoomMember *_Nullable)getMemberOnTheSeat:(NEVoiceRoomSeatItem *)seatItem {
  for (NEVoiceRoomMember *member in NEVoiceRoomKit.getInstance.allMemberList) {
    if ([member.account isEqualToString:seatItem.user]) {
      return member;
    }
  }
  return nil;
}
// 设置自己的麦位状态
- (void)configSelfSeatStatusWithSeatItems:(NSArray<NEVoiceRoomSeatItem *> *)seatItems {
  for (NEVoiceRoomSeatItem *item in seatItems) {
    if ([item.user isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
      self.selfStatus = item.status;
      return;
    }
  }
  self.selfStatus = NEVoiceRoomSeatItemStatusInitial;
}

// 麦位上是否是自己
- (BOOL)isSelfWithSeatAccount:(NSString *)account {
  if ([NEVoiceRoomKit.getInstance.localMember.account isEqualToString:account]) {
    return YES;
  }
  return NO;
}

- (void)notifityMessage:(NSString *)msg account:(NSString *)account {
  NEVoiceRoomMember *member =
      [NEVoiceRoomKit.getInstance.allMemberList ne_find:^BOOL(NEVoiceRoomMember *obj) {
        return [account isEqualToString:obj.account];
      }];
  if (!member) return;

  NSMutableArray *messages = @[].mutableCopy;
  NESocialChatroomNotiMessage *message = [NESocialChatroomNotiMessage new];
  message.notification = [NSString stringWithFormat:@"%@ %@", member.name, msg];
  [messages addObject:message];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.chatView addMessages:messages];
  });
}
@end
