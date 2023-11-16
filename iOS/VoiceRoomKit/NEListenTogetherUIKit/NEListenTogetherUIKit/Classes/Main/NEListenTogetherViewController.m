// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEListenTogetherViewController.h"
#import <NECopyrightedMedia/NECopyrightedMedia.h>
#import <NECoreKit/NSObject+YXModel.h>
#import <NEUIKit/NEUIBaseNavigationController.h>
#import <NEUIKit/UIView+NEUIExtension.h>
#import "NEListenTogetherGlobalMacro.h"
#import "NEListenTogetherLocalized.h"
#import "NEListenTogetherPickSongEngine.h"
#import "NEListenTogetherPickSongView.h"
#import "NEListenTogetherRoomListViewController.h"
#import "NEListenTogetherSendGiftViewController.h"
#import "NEListenTogetherToast.h"
#import "NEListenTogetherUI.h"
#import "NEListenTogetherUIActionSheetNavigationController.h"
#import "NEListenTogetherUIDeviceSizeInfo.h"
#import "NEListenTogetherUILog.h"
#import "NEListenTogetherUIManager.h"
#import "NEListenTogetherUIMoreFunctionVC.h"
#import "NEListenTogetherViewController+Seat.h"
#import "NEListenTogetherViewController+UI.h"
#import "NEListenTogetherViewController+Utils.h"
#import "UIColor+NEUIExtension.h"
#import "UIImage+ListenTogether.h"
@import NEVoiceRoomBaseUIKit;
@import NESocialUIKit;

@interface NEListenTogetherViewController () <NEListenTogetherHeaderDelegate,
                                              NEListenTogetherFooterFunctionAreaDelegate,
                                              NEUIMoreSettingDelegate,
                                              NEUIKeyboardToolbarDelegate,
                                              NEListenTogetherMicQueueViewDelegate,
                                              NEUIConnectListViewDelegate,
                                              NEListenTogetherSendGiftViewtDelegate,
                                              NEListenTogetherLyricActionViewDelegate,
                                              NESongPointProtocol,
                                              NEListenTogetherPickSongViewProtocol,
                                              NEListenTogetherLyricControlViewDelegate,
                                              NEVoiceRoomListener,
                                              NEOrderSongListener>

@property(nonatomic, strong) NEListenTogetherPickSongView *pickSongView;
@property(nonatomic, strong) NSArray<NESocialGiftModel *> *defaultGifts;
@end

@implementation NEListenTogetherViewController
- (instancetype)initWithRole:(NEVoiceRoomRole)role detail:(NEVoiceRoomInfo *)detail {
  if (self = [super init]) {
    self.detail = detail;
    self.role = role;
    self.context.role = role;
    self.audioManager = [[NEAudioEffectManager alloc] init];
    self.defaultGifts = [NESocialGiftModel defaultGifts];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBar.hidden = YES;
}

- (void)dealloc {
  NSLog(@"============ NEListenTogetherViewController dealloc");
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
  [NEVoiceRoomKit.getInstance removeVoiceRoomListener:self];
  [[NEOrderSong getInstance] removeOrderSongListener:self];
  [self destroyNetworkObserver];
  [[NEListenTogetherPickSongEngine sharedInstance] removeObserve:self];
  [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel = nil;

  if ([[NEListenTogetherUIManager sharedInstance].delegate
          respondsToSelector:@selector(onListenTogetherLeaveRoom)]) {
    [[NEListenTogetherUIManager sharedInstance].delegate onListenTogetherLeaveRoom];
  }
}
- (void)viewDidLoad {
  [super viewDidLoad];
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  if ([[NEListenTogetherUIManager sharedInstance].delegate
          respondsToSelector:@selector(onListenTogetherJoinRoom)]) {
    [[NEListenTogetherUIManager sharedInstance].delegate onListenTogetherJoinRoom];
  }

  self.playingStatus = PlayingStatus_default;
  self.playingAction = PlayingAction_default;
  // Do any additional setup after loading the view.
  [NEVoiceRoomKit.getInstance addVoiceRoomListener:self];
  [[NEOrderSong getInstance] addOrderSongListener:self];
  [self addSubviews];
  [self joinRoom];
  [self observeKeyboard];
  [self addNetworkObserver];
  [self checkMicAuthority];
  [[NEListenTogetherPickSongEngine sharedInstance] addObserve:self];

  // 禁止返回
  id traget = self.navigationController.interactivePopGestureRecognizer.delegate;
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:traget action:nil];
  [self.view addGestureRecognizer:pan];
}

- (void)closeRoom:(void (^)(void))complete {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.role == NEVoiceRoomRoleHost) {
      __weak typeof(self) weakSelf = self;
      UIAlertController *alert =
          [UIAlertController alertControllerWithTitle:NELocalizedString(@"确认结束直播？")
                                              message:NELocalizedString(@"请确认是否结束直播")
                                       preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:NELocalizedString(@"确认")
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *_Nonnull action) {
                                                [weakSelf closeRoom];
                                              }]];
      [alert addAction:[UIAlertAction actionWithTitle:NELocalizedString(@"取消")
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [self presentViewController:alert animated:true completion:nil];
    } else {
      [self closeRoom];
    }
  });
}

- (void)closeRoom {
  if ([[NEListenTogetherUIManager sharedInstance].delegate
          respondsToSelector:@selector(onListenTogetherLeaveRoom)]) {
    [[NEListenTogetherUIManager sharedInstance].delegate onListenTogetherLeaveRoom];
  }
  __weak typeof(self) weakSelf = self;
  if (self.role == NEVoiceRoomRoleHost) {  // 主播
    [NEVoiceRoomKit.getInstance
        endRoom:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [NEListenTogetherToast showToast:NELocalizedString(@"房间解散成功")];
            if (weakSelf.presentedViewController) {
              [weakSelf.presentedViewController dismissViewControllerAnimated:false completion:nil];
            }
            [weakSelf backToListViewController];
          });
        }];
  } else {  // 观众
    [NEVoiceRoomKit.getInstance
        leaveRoom:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.presentedViewController) {
              [weakSelf.presentedViewController dismissViewControllerAnimated:false completion:nil];
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
          });
        }];
  }
}

- (void)backToListViewController {
  UIViewController *target = nil;
  for (UIViewController *controller in self.navigationController.viewControllers) {
    if ([controller isKindOfClass:[NEListenTogetherRoomListViewController class]]) {
      target = controller;
      break;
    }
  }
  if (target) {
    [self.navigationController popToViewController:target animated:YES];
  }
}
#pragma mark - NTESLiveRoomHeaderDelegate
- (void)headerExitAction {
  [self closeRoom:^{

  }];
}

#pragma mark - NETSFunctionAreaDelegate

// 麦克静音事件
- (void)footerDidReceiveMicMuteAction:(BOOL)mute {
  [self handleMuteOperation:mute];
}

- (void)footerDidReceiveGiftClickAciton {
  // 发送礼物
  [NEListenTogetherSendGiftViewController showWithTarget:self viewController:self];
}
// 禁言事件
- (void)footerDidReceiveNoSpeekingAciton {
}

/// 点击点歌台
- (void)footerDidReceiveMusicClickAciton {
  [self showChooseSingViewController];
}
// menu点击事件
- (void)footerDidReceiveMenuClickAciton {
  NEListenTogetherUIMoreFunctionVC *moreVC =
      [[NEListenTogetherUIMoreFunctionVC alloc] initWithContext:self.context];
  moreVC.delegate = self;
  NEListenTogetherUIActionSheetNavigationController *nav =
      [[NEListenTogetherUIActionSheetNavigationController alloc] initWithRootViewController:moreVC];
  nav.dismissOnTouchOutside = YES;
  [self presentViewController:nav animated:YES completion:nil];
}

// 输入框点击事件
- (void)footerInputViewDidClickAction {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   [self.keyboardView becomeFirstResponse];
                 });
}
#pragma mark------------------------ NEUIMoreSettingDelegate ------------------------
- (void)didEarbackOn:(BOOL)earBackOn {
}
- (void)didSetMicOn:(BOOL)micOn {
  if (micOn) {
    [self unmuteAudio:YES];
  } else {
    [self muteAudio:YES];
  }
}
- (void)endLive {
  [self closeRoom:^{

  }];
}

#pragma mark------------------------ NEListenTogetherSendGiftViewtDelegate ------------------------

- (void)didSendGift:(NESocialGiftModel *)gift {
  if (![self checkNetwork]) {
    return;
  }

  [self dismissViewControllerAnimated:true
                           completion:^{
                             [[NEVoiceRoomKit getInstance]
                                 sendBatchGift:gift.giftId
                                     giftCount:1
                                     userUuids:@[ self.detail.anchor.userUuid ]
                                      callback:^(NSInteger code, NSString *_Nullable msg,
                                                 id _Nullable obj) {
                                        if (code != 0) {
                                          [NEListenTogetherToast
                                              showToast:[NSString
                                                            stringWithFormat:@"发送礼物失败 %zd %@",
                                                                             code, msg]];
                                        }
                                      }];
                           }];
}

- (BOOL)checkNetwork {
  NEListenTogetherNetworkStatus status = [self.reachability currentReachabilityStatus];
  if (status == NotReachable) {
    [NEListenTogetherToast showToast:NELocalizedString(@"网络异常，请稍后重试")];
    return false;
  }
  return true;
}

#pragma mark------------------------ NEUIKeyboardToolbarDelegate ------------------------
- (void)didToolBarSendText:(NSString *)text {
  NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  text = [text stringByTrimmingCharactersInSet:set];
  if (text.length <= 0) {
    [NEListenTogetherToast showToast:NELocalizedString(@"发送内容为空")];
    return;
  }
  [NEVoiceRoomKit.getInstance
      sendTextMessage:text
             callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
               dispatch_async(dispatch_get_main_queue(), ^{
                 NESocialChatroomTextMessage *model = [[NESocialChatroomTextMessage alloc] init];
                 model.sender = NEListenTogetherUIManager.sharedInstance.nickname;
                 model.text = text;
                 if (self.role == NEVoiceRoomRoleHost) {
                   model.iconSize = CGSizeMake(32, 16);
                   model.icon = [NEVRBaseBundle loadImage:[NEVRBaseBundle localized:@"Owner_Icon"
                                                                              value:nil]];
                 } else {
                   model.icon = nil;
                 }
                 [self.chatView addMessages:@[ model ]];
               });
             }];
}
#pragma mark------------------------ NEVoiceRoomListener ------------------------

- (void)onRtcLocalAudioVolumeIndicationWithVolume:(NSInteger)volume enableVad:(BOOL)enableVad {
  [self.micQueueView updateWithLocalVolume:volume];
}

- (void)onRtcRemoteAudioVolumeIndicationWithVolumes:
            (NSArray<NEVoiceRoomMemberVolumeInfo *> *)volumes
                                        totalVolume:(NSInteger)totalVolume {
  [self.micQueueView updateWithRemoteVolumeInfos:volumes];
}

- (void)onAudioOutputDeviceChanged:(enum NEVoiceRoomAudioOutputDevice)device {
  if (device == NEVoiceRoomAudioOutputDeviceWiredHeadset ||
      device == NEVoiceRoomAudioOutputDeviceBluetoothHeadset) {
    // 默认不打开耳返
    //    self.context.rtcConfig.earbackOn = true;
    [NSNotificationCenter.defaultCenter
        postNotification:[[NSNotification alloc] initWithName:@"CanUseEarback"
                                                       object:nil
                                                     userInfo:nil]];
  } else {
    self.context.rtcConfig.earbackOn = false;
    [NSNotificationCenter.defaultCenter
        postNotification:[[NSNotification alloc] initWithName:@"CanNotUseEarback"
                                                       object:nil
                                                     userInfo:nil]];
  }
}

- (void)onMemberJoinRoom:(NSArray<NEVoiceRoomMember *> *)members {
  [self.micQueueView togetherListen];
  NSMutableArray *messages = @[].mutableCopy;
  for (NEVoiceRoomMember *member in members) {
    NESocialChatroomNotiMessage *message = [[NESocialChatroomNotiMessage alloc] init];
    message.notification =
        [NSString stringWithFormat:@"%@ %@", member.name, NELocalizedString(@"加入房间")];
    [messages addObject:message];
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.roomHeaderView.onlinePeople = NEVoiceRoomKit.getInstance.allMemberList.count;
    [self.chatView addMessages:messages];
  });
}
- (void)onMemberLeaveRoom:(NSArray<NEVoiceRoomMember *> *)members {
  [self.micQueueView singleListen];
  NSMutableArray *messages = @[].mutableCopy;
  for (NEVoiceRoomMember *member in members) {
    NESocialChatroomNotiMessage *message = [[NESocialChatroomNotiMessage alloc] init];
    message.notification =
        [NSString stringWithFormat:@"%@ %@", member.name, NELocalizedString(@"离开房间")];
    [messages addObject:message];
#warning 请求麦位信息
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.roomHeaderView.onlinePeople = NEVoiceRoomKit.getInstance.allMemberList.count;
    [self.chatView addMessages:messages];
  });
}
- (void)onMemberJoinChatroom:(NSArray<NEVoiceRoomMember *> *)members {
  bool isSelf = false;
  for (NEVoiceRoomMember *member in members) {
    if ([member.account isEqualToString:NEVoiceRoomKit.getInstance.localMember.account]) {
      isSelf = true;
      break;
    }
  }
  if (isSelf) {
    [self getSeatInfoWhenRejoinChatRoom];
  } else {
    [NEVoiceRoomKit.getInstance
        sendSeatInvitationWithSeatIndex:2
                                account:members.firstObject.account
                               callback:^(NSInteger code, NSString *_Nullable msg,
                                          id _Nullable obj) {
                                 if (code != 0) {
                                   //                                   [NEListenTogetherToast
                                   //                                   showToast:NELocalizedString(@"操作失败")];
                                 }
                               }];
  }
}
- (void)onReceiveTextMessage:(NEVoiceRoomChatTextMessage *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    NESocialChatroomTextMessage *model = [[NESocialChatroomTextMessage alloc] init];
    model.sender = message.fromNick;
    model.text = message.text;
    if ([message.fromUserUuid isEqualToString:self.detail.liveModel.userUuid]) {
      model.iconSize = CGSizeMake(32, 16);
      model.icon = [NEVRBaseBundle loadImage:[NEVRBaseBundle localized:@"Owner_Icon" value:nil]];
    } else {
      model.icon = nil;
    }
    [self.chatView addMessages:@[ model ]];
  });
}

- (void)onReceiveBatchGiftWithGiftModel:(NEVoiceRoomBatchGiftModel *)giftModel {
  // 展示礼物动画
  NSString *giftDisplay;
  for (NESocialGiftModel *model in self.defaultGifts) {
    if (model.giftId == giftModel.giftId) {
      giftDisplay = model.displayName;
      break;
    }
  }
  NSMutableArray *messages = [NSMutableArray array];
  for (NEVoiceRoomBatchSeatUserRewardee *userRewardee in giftModel.rewardeeUsers) {
    NESocialChatroomRewardMessage *message = [[NESocialChatroomRewardMessage alloc] init];
    message.giftImage = [NESocialGiftModel getGiftWithGiftId:giftModel.giftId].icon;
    message.giftImageSize = CGSizeMake(20, 20);
    message.sender = giftModel.rewarderUserName;
    message.receiver = userRewardee.userName;
    message.rewardText = NELocalizedString(@"送给");
    message.rewardColor = [UIColor colorWithWhite:1 alpha:0.6];
    message.giftColor = [UIColor ne_colorWithHex:0xFFD966 alpha:1];
    message.giftCount = giftModel.giftCount;
    message.giftName = giftDisplay;
    [messages addObject:message];
  }

  [self.chatView addMessages:messages];

  if (self.role != NEVoiceRoomRoleHost) {
    // 房主不展示礼物
    NSString *giftName = [NSString stringWithFormat:@"anim_gift_0%zd", giftModel.giftId];
    [self playGiftWithName:giftName];
  }
}

- (void)onRoomEnded:(enum NEVoiceRoomEndReason)reason {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (reason != NEVoiceRoomEndReasonLeaveBySelf) {
      [NEListenTogetherToast showToast:NELocalizedString(@"房间关闭")];
      if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:false completion:nil];
      }
      [self.navigationController popViewControllerAnimated:YES];
    }
  });
}

- (void)onAudioEffectFinished {
  // 播放完成，清理本地的model
  if ([self isAnchor]) {
    [[NEOrderSong getInstance]
        nextSongWithOrderId:[NEListenTogetherPickSongEngine sharedInstance]
                                .currrentSongModel.playMusicInfo.orderId
                 attachment:PlayComplete
                   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){

                   }];
  }
}

- (void)onAudioEffectTimestampUpdate:(uint32_t)effectId timeStampMS:(uint64_t)timeStampMS {
  if (effectId == NEVoiceRoomKit.OriginalEffectId) {
    if (timeStampMS > self.time) {
      [self.micQueueView play];
    } else {
      [self.micQueueView pause];
    }
    self.time = (long)timeStampMS;
    [self.lyricActionView updateLyric:self.time];
  }
}

- (void)onReceiveSongPosition:(enum NEOrderSongCustomAction)actionType
                         data:(NSDictionary<NSString *, id> *)data {
  if (actionType == NEOrderSongCustomActionGetPosition) {
    NSString *songId =
        [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel.playMusicInfo.songId;
    if (!songId.length) {
      return;
    }
    // 获取进度
    NSDictionary *songDic = @{
      @"songId" : [NEListenTogetherPickSongEngine sharedInstance]
          .currrentSongModel.playMusicInfo.songId,
      @"channel" : [NSNumber numberWithLong:[NEListenTogetherPickSongEngine sharedInstance]
                                                .currrentSongModel.playMusicInfo.oc_channel],
      @"progress" : [NSNumber numberWithLong:self.time]
    };
    [[NEVoiceRoomKit getInstance] sendCustomMessage:data[@"userUuid"]
                                          commandId:NEListenTogetherCustomActionSendPosition
                                               data:songDic.yx_modelToJSONString
                                           callback:nil];
  } else if (actionType == NEOrderSongCustomActionSendPosition) {
    NSInteger progress = [data[@"progress"] intValue];
    [[NEVoiceRoomKit getInstance] setPlayingPositionWithPosition:progress];
    self.time = progress;
    [self.lyricActionView updateLyric:progress];
    if ([NEListenTogetherPickSongEngine sharedInstance]
            .currrentSongModel.playMusicInfo.oc_musicStatus == 2) {
      // 暂停
      [[NEVoiceRoomKit getInstance] pauseEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
    }
    //        [self.lyricActionView seekLyricView:];
  } else if (actionType == NEOrderSongCustomActionDownloadProcess) {
    NSString *songId = data[@"songId"];
    if ([songId isEqualToString:[NEListenTogetherPickSongEngine sharedInstance]
                                    .currrentSongModel.playMusicInfo.songId]) {
      NSNumber *downloadProcess = data[@"downloadProcess"];
      [self.micQueueView showDownloadingProcess:self.role == NEVoiceRoomRoleHost
                                           show:downloadProcess.intValue == 1];
    }
  }
}

#pragma mark - gift animation

/// 播放礼物动画
- (void)playGiftWithName:(NSString *)name {
  if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
    // 在后台就不添加礼物动画了
    return;
  }
  [self.view addSubview:self.giftAnimation];
  [self.view bringSubviewToFront:self.giftAnimation];
  [self.giftAnimation addGift:name];
}

- (NEListenTogetherAnimationView *)giftAnimation {
  if (!_giftAnimation) {
    _giftAnimation = [[NEListenTogetherAnimationView alloc] init];
  }
  return _giftAnimation;
}

#pragma mark------------------------ NEListenTogetherMicQueueViewDelegate ------------------------
- (void)micQueueConnectBtnPressedWithMicInfo:(NEVoiceRoomSeatItem *)micInfo {
  switch (self.role) {
    case NEVoiceRoomRoleHost: {  // 主播操作麦位
      [self anchorOperationSeatItem:micInfo];
    } break;
    default: {  // 观众操作麦位
      [self audienceOperationSeatItem:micInfo];
    } break;
  }
}

- (void)clickPointSongButton {
  [self showChooseSingViewController];
}
#pragma mark------------------------ Getter  ------------------------
- (NEListenTogetherContext *)context {
  if (!_context) {
    _context = [NEListenTogetherContext new];
  }
  return _context;
}
- (UIImageView *)bgImageView {
  if (!_bgImageView) {
    _bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    _bgImageView.image = [NEListenTogetherUI ne_listen_imageName:@"chatRoom_bgImage_icon"];
  }
  return _bgImageView;
}
- (NEListenTogetherHeaderView *)roomHeaderView {
  if (!_roomHeaderView) {
    _roomHeaderView = [[NEListenTogetherHeaderView alloc] init];
    _roomHeaderView.delegate = self;
  }
  return _roomHeaderView;
}

- (NEListenTogetherFooterView *)roomFooterView {
  if (!_roomFooterView) {
    _roomFooterView = [[NEListenTogetherFooterView alloc] initWithContext:self.context];
    _roomFooterView.role = self.role;
    _roomFooterView.delegate = self;
  }
  return _roomFooterView;
}
- (NEListenTogetherKeyboardToolbarView *)keyboardView {
  if (!_keyboardView) {
    _keyboardView = [[NEListenTogetherKeyboardToolbarView alloc]
        initWithFrame:CGRectMake(0, UIScreen.mainScreen.bounds.size.height,
                                 UIScreen.mainScreen.bounds.size.width, 50)];
    _keyboardView.backgroundColor = UIColor.whiteColor;
    _keyboardView.cusDelegate = self;
  }
  return _keyboardView;
}
- (NESocialChatroomView *)chatView {
  if (!_chatView) {
    _chatView = [[NESocialChatroomView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
  }
  return _chatView;
}
- (NEListenTogetherMicQueueView *)micQueueView {
  if (!_micQueueView) {
    _micQueueView = [[NEListenTogetherMicQueueView alloc] initWithFrame:CGRectZero];
    _micQueueView.delegate = self;
    _micQueueView.datas = [self simulatedSeatData];
  }
  return _micQueueView;
}
- (NEListenTogetherReachability *)reachability {
  if (!_reachability) {
    _reachability = [NEListenTogetherReachability reachabilityForInternetConnection];
  }
  return _reachability;
}
- (NEListenTogetherUIAlertView *)alertView {
  if (!_alertView) {
    _alertView = [[NEListenTogetherUIAlertView alloc] initWithActions:[self setupAlertActions]];
  }
  return _alertView;
}

- (NEListenTogetherLyricActionView *)lyricActionView {
  if (!_lyricActionView) {
    _lyricActionView = [[NEListenTogetherLyricActionView alloc] initWithFrame:self.view.frame];
    _lyricActionView.delegate = self;
  }
  return _lyricActionView;
}

- (NEListenTogetherLyricControlView *)lyricControlView {
  if (!_lyricControlView) {
    _lyricControlView = [[NEListenTogetherLyricControlView alloc] initWithFrame:self.view.frame];
    _lyricControlView.delegate = self;
  }
  return _lyricControlView;
}

#pragma mark------------------------ Private ------------------------

- (void)showChooseSingViewController {
  if (![self checkNetwork]) {
    return;
  }
  self.pickSongView = nil;
  CGSize size = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds),
                           CGRectGetHeight([UIScreen mainScreen].bounds) / 3 * 2);
  UIViewController *controller = [[UIViewController alloc] init];
  controller.preferredContentSize = size;
  self.pickSongView =
      [[NEListenTogetherPickSongView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                                   detail:self.detail];
  [self.pickSongView setPlayingStatus:(self.playingStatus == PlayingStatus_playing)];
  [self.pickSongView setVolume:[NEVoiceRoomKit getInstance].getEffectVolume * 1.0 / 100.00];
  self.pickSongView.delegate = self;
  controller.view = self.pickSongView;
  NEListenTogetherUIActionSheetNavigationController *nav =
      [[NEListenTogetherUIActionSheetNavigationController alloc]
          initWithRootViewController:controller];
  controller.navigationController.navigationBar.hidden = true;
  nav.dismissOnTouchOutside = YES;
  [self presentViewController:nav animated:YES completion:nil];

  __weak typeof(self) weakSelf = self;
  __weak typeof(nav) weakNav = nav;
  self.pickSongView.applyOnseat = ^{
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NELocalizedString(@"仅麦上成员可点歌，先申请上麦")
                         message:nil
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NELocalizedString(@"取消")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *_Nonnull action) {
                                              [weakSelf.pickSongView cancelApply];
                                            }]];
    [alert addAction:[UIAlertAction
                         actionWithTitle:NELocalizedString(@"申请上麦")
                                   style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction *_Nonnull action) {
                                   if (![NEListenTogetherAuthorityHelper
                                           checkMicAuthority]) {  // 麦克风权限
                                     [NEListenTogetherToast
                                         showToast:NELocalizedString(@"请先开启麦克风权限")];
                                     return;
                                   }
                                   // 申请上麦
                                   [NEVoiceRoomKit.getInstance
                                       requestSeat:^(NSInteger code, NSString *_Nullable msg,
                                                     id _Nullable obj) {
                                         if (code == 0) {
                                           [weakSelf.pickSongView applyFaile];
                                         } else {
                                           [weakSelf.pickSongView applySuccess];
                                         }
                                       }];
                                 }]];
    UIViewController *controller = weakNav;
    if (controller.presentedViewController) {
      controller = controller.presentedViewController;
    }
    [controller presentViewController:alert
                             animated:true
                           completion:^{
                           }];
  };
}

#pragma mark------------------------ CMD处理 ------------------------
- (void)onReceiveChorusMessage:(enum NEOrderSongChorusActionType)actionType
                     songModel:(NEOrderSongSongModel *)songModel {
  if (actionType == NEOrderSongChorusActionTypeStartSong) {
    [self sendChatroomNotifyMessage:[NSString stringWithFormat:@"%@《%@》",
                                                               NELocalizedString(@"正在播放歌曲"),
                                                               songModel.playMusicInfo.songName]];
    /// 开始唱歌
    self.playingStatus = PlayingStatus_playing;
    [self singSong:songModel];
    [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel = songModel;
    [NEListenTogetherUILog infoLog:ListenTogetherUILog
                              desc:[NSString stringWithFormat:@"播放中的歌曲赋值 --- %@",
                                                              songModel.playMusicInfo.songId]];
    [self refreshUI];
    if (self.pickSongView) {
      // 刷新数据
      [self.pickSongView refreshPickedSongView];
    }

  } else if (actionType == NEOrderSongChorusActionTypePauseSong) {
    // 暂停
    self.playingStatus = PlayingStatus_pause;
    [[NEVoiceRoomKit getInstance] pauseEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
    [self.micQueueView pause];
    [self.pickSongView setPlayingStatus:(self.playingStatus == PlayingStatus_playing)];
    [self.lyricControlView setIsPlaying:(self.playingStatus == PlayingStatus_playing)];
  } else if (actionType == NEOrderSongChorusActionTypeResumeSong) {
    /// 本地有缓存数据，并且orderId 相同，说明是恢复
    [[NEVoiceRoomKit getInstance] resumeEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
    self.playingStatus = PlayingStatus_playing;
    [self refreshUI];
    //    [self.micQueueView play];
    [self.pickSongView setPlayingStatus:(self.playingStatus == PlayingStatus_playing)];
    [self.lyricControlView setIsPlaying:(self.playingStatus == PlayingStatus_playing)];
  }
}

- (void)refreshUI {
  if (self.pickSongView) {
    [self.pickSongView setPlayingStatus:(self.playingStatus == PlayingStatus_playing)];
    [self.lyricControlView setIsPlaying:(self.playingStatus == PlayingStatus_playing)];
  }
  //    [self.micQueueView showListenButton:NO];
}

- (void)onPreloadComplete:(NSString *)songId channel:(SongChannel)channel error:(NSError *)error {
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
  if (![NEListenTogetherPickSongEngine sharedInstance].currrentSongModel.playMusicInfo) {
    return;
  }
  NSDictionary *songDic = @{
    @"songId" : songId,
    @"channel" : [NSNumber numberWithLong:channel],
    @"downloadProcess" : [NSNumber numberWithInt:0]
  };
  [[NEVoiceRoomKit getInstance] sendCustomMessage:userUuid
                                        commandId:NEListenTogetherCustomActionDownloadProcess
                                             data:songDic.yx_modelToJSONString
                                         callback:nil];

  [NEOrderSong.getInstance queryPlayingSongInfo:^(NSInteger code, NSString *_Nullable msg,
                                                  NEOrderSongPlayMusicInfo *_Nullable model) {
    if (code == NEVoiceRoomErrorCode.success) {
      if (model) {
        // 有播放中歌曲
        if ([songId isEqualToString:model.songId] && (channel == model.oc_channel)) {
          if ([NEListenTogetherPickSongEngine sharedInstance].currrentSongModel) {
            if (self.playingAction == PlayingAction_join_half_way) {
              /// 中途加入，房间内存在播放中的歌曲
              [self singSong:[NEListenTogetherPickSongEngine sharedInstance].currrentSongModel];
              if ([NEListenTogetherPickSongEngine sharedInstance]
                      .currrentSongModel.playMusicInfo.oc_musicStatus == 2) {
                // 暂停
                [[NEVoiceRoomKit getInstance]
                    pauseEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
              }

              NSString *dataString = @{@"userUuid" : NEVoiceRoomKit.getInstance.localMember.account}
                                         .yx_modelToJSONString;
              [[NEVoiceRoomKit getInstance]
                  sendCustomMessage:userUuid
                          commandId:NEListenTogetherCustomActionGetPosition
                               data:dataString
                           callback:nil];
            } else if (self.playingAction == PlayingAction_switchSong) {
              /// 切歌
              [self readySongModel:model.orderId];
            } else {
              /// 正常ready
              [self readySongModel:model.orderId];
            }
          } else {
            /// 一开始就在
            [self readySongModel:model.orderId];
          }
        }

      } else {
        // 无播放中歌曲
      }
    } else {
      // 发生错误
    }
  }];
}

- (void)onPreloadStart:(NSString *)songId channel:(SongChannel)channel {
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
  NSDictionary *songDic = @{
    @"songId" : songId,
    @"channel" : [NSNumber numberWithLong:channel],
    @"downloadProcess" : [NSNumber numberWithInt:1]
  };
  [[NEVoiceRoomKit getInstance] sendCustomMessage:userUuid
                                        commandId:NEListenTogetherCustomActionDownloadProcess
                                             data:songDic.yx_modelToJSONString
                                         callback:nil];
}

- (void)readySongModel:(long)orderId {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NEOrderSong getInstance]
        readyPlaySongWithOrderId:orderId
                        chorusId:nil
                             ext:nil
                        callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj) {
                          // 1007表示歌曲不存在
                          if (code != 0 && code != 1007) {
                            [NEListenTogetherToast
                                showToast:[NSString stringWithFormat:@"%@：%@",
                                                                     NELocalizedString(
                                                                         @"歌曲开始播放失败"),
                                                                     msg]];
                          }
                        }];
  });
}
#pragma mark-----------------------------  NEListenTogetherSongProtocol  -----------------------------
/// 列表变更
- (void)onSongListChanged {
  [self fetchPickedSongList];
}

/// 点歌
- (void)onSongOrdered:(NEOrderSongProtocolResult *)song {
  [self sendChatroomNotifyMessage:[NSString
                                      stringWithFormat:@"%@ %@《%@》", song.operatorUser.userName,
                                                       NELocalizedString(@"点了"),
                                                       song.orderSongResultDto.orderSong.songName]];

  [[NEOrderSong getInstance] queryPlayingSongInfo:^(NSInteger code, NSString *_Nullable msg,
                                                    NEOrderSongPlayMusicInfo *_Nullable songModel) {
    if (code == 0) {
      NEOrderSongSongModel *currentModel = [[NEOrderSongSongModel alloc] init];
      currentModel.playMusicInfo = songModel;
      [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel = currentModel;

      if (![[NEVoiceRoomKit getInstance].localMember.account
              isEqualToString:song.operatorUser.userUuid]) {
        /// 不是自己点的
        if (currentModel.playMusicInfo && currentModel.playMusicInfo.oc_musicStatus != 3) {
          /// 当前存在播放中的歌曲数据，且不是等待播放的状态
          return;
        } else {
          // 如果当前无播放中歌曲
          [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel =
              [[NEOrderSongSongModel alloc] init:song];
          NEOrderSongResponseOrderSongModel *orderSong = song.orderSongResultDto.orderSong;
          if ([[NEOrderSong getInstance] isSongPreloaded:orderSong.songId
                                                 channel:(int)orderSong.oc_channel]) {
            [self readySongModel:orderSong.orderId];
          } else {
            self.playingAction = PlayingAction_default;
            [[NEOrderSong getInstance] preloadSong:orderSong.songId
                                           channel:(int)orderSong.oc_channel
                                           observe:self];
          }
        }
      }
    }
  }];
}
- (void)onSongDeleted:(NEOrderSongProtocolResult *)song {
  [self sendChatroomNotifyMessage:[NSString
                                      stringWithFormat:@"%@ %@《%@》", song.operatorUser.userName,
                                                       NELocalizedString(@"删除了歌曲"),
                                                       song.orderSongResultDto.orderSong.songName]];

  if ([song.orderSongResultDto.orderSong.songId
          isEqualToString:[NEListenTogetherPickSongEngine sharedInstance]
                              .currrentSongModel.playMusicInfo.songId]) {
    /// 删除播放中的歌
    [[NEVoiceRoomKit getInstance] pauseEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
    [[NEVoiceRoomKit getInstance] stopEffectWithEffectId:NEVoiceRoomKit.OriginalEffectId];
    [NEListenTogetherPickSongEngine sharedInstance].currrentSongModel.playMusicInfo = nil;
    self.lyricActionView.hidden = YES;
    self.lyricControlView.hidden = YES;
    self.lyricControlView.isPlaying = NO;
    [self.micQueueView stop];
    if (song.nextOrderSong) {
      /// 删除的是播放中的歌曲
      if ([[NEOrderSong getInstance]
              isSongPreloaded:song.nextOrderSong.orderSong.songId
                      channel:(int)song.nextOrderSong.orderSong.oc_channel]) {
        [self readySongModel:song.nextOrderSong.orderSong.orderId];
      } else {
        [[NEOrderSong getInstance] preloadSong:song.nextOrderSong.orderSong.songId
                                       channel:(int)song.nextOrderSong.orderSong.oc_channel
                                       observe:self];
      }
    } else {
    }
  }
}

- (void)onSongTopped:(NEOrderSongProtocolResult *)song {
  [self sendChatroomNotifyMessage:[NSString
                                      stringWithFormat:@"%@ %@《%@》", song.operatorUser.userName,
                                                       NELocalizedString(@"置顶"),
                                                       song.orderSongResultDto.orderSong.songName]];
}

- (void)onNextSong:(NEOrderSongProtocolResult *)song {
  [NEListenTogetherUILog
      infoLog:ListenTogetherUILog
         desc:[NSString stringWithFormat:@"收到切歌消息 --- %@",
                                         song.orderSongResultDto.orderSong.songId]];
  if (song.attachment.length > 0) {
    if ([song.attachment isEqualToString:PlayComplete]) {
      {
        NEOrderSongResponse *nextSong = song.nextOrderSong;
        [NEListenTogetherUILog infoLog:ListenTogetherUILog
                                  desc:[NSString stringWithFormat:@"自然播放结束歌曲切歌 --- %@",
                                                                  nextSong.orderSong.songId]];
        if (nextSong) {
          if ([[NEOrderSong getInstance] isSongPreloaded:nextSong.orderSong.songId
                                                 channel:(int)nextSong.orderSong.oc_channel]) {
            [self readySongModel:nextSong.orderSong.orderId];
          } else {
            self.playingAction = PlayingAction_switchSong;
            [[NEOrderSong getInstance] preloadSong:nextSong.orderSong.songId
                                           channel:(int)nextSong.orderSong.oc_channel
                                           observe:self];
          }
        } else {
          [NEListenTogetherUILog
              infoLog:ListenTogetherUILog
                 desc:[NSString stringWithFormat:@"自然播放结束切歌数据为空 --- %@",
                                                 nextSong.orderSong.songId]];
        }
      }
    } else {
      [self
          sendChatroomNotifyMessage:[NSString stringWithFormat:@"%@ %@", song.operatorUser.userName,
                                                               NELocalizedString(@"已切歌")]];
      // 选定歌曲切
      NSData *stringData = [song.attachment dataUsingEncoding:NSUTF8StringEncoding];
      NSError *err;
      NSDictionary *attach = [NSJSONSerialization JSONObjectWithData:stringData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&err];
      NSString *songId = attach[@"songId"];
      NSInteger channel = [attach[@"channel"] integerValue];
      NSInteger orderId = [attach[@"orderId"] integerValue];
      [NEListenTogetherUILog infoLog:ListenTogetherUILog
                                desc:[NSString stringWithFormat:@"选定歌曲切歌 --- %@", songId]];
      if (songId.length) {
        if ([[NEOrderSong getInstance] isSongPreloaded:songId channel:(SongChannel)channel]) {
          [self readySongModel:orderId];
        } else {
          self.playingAction = PlayingAction_switchSong;
          [[NEOrderSong getInstance] preloadSong:songId channel:(SongChannel)channel observe:self];
        }
      } else {
        [NEListenTogetherUILog infoLog:ListenTogetherUILog desc:@"选定歌曲切歌数据为空"];
      }
    }

  } else {
    [self sendChatroomNotifyMessage:[NSString stringWithFormat:@"%@ %@", song.operatorUser.userName,
                                                               NELocalizedString(@"已切歌")]];
    NEOrderSongResponse *nextSong = song.nextOrderSong;
    [NEListenTogetherUILog
        infoLog:ListenTogetherUILog
           desc:[NSString stringWithFormat:@"未选定歌曲切歌 --- %@", nextSong.orderSong.songId]];
    if (nextSong) {
      if ([[NEOrderSong getInstance] isSongPreloaded:nextSong.orderSong.songId
                                             channel:(int)nextSong.orderSong.oc_channel]) {
        [self readySongModel:nextSong.orderSong.orderId];
      } else {
        self.playingAction = PlayingAction_switchSong;
        [[NEOrderSong getInstance] preloadSong:nextSong.orderSong.songId
                                       channel:(int)nextSong.orderSong.oc_channel
                                       observe:self];
      }
    } else {
      [NEListenTogetherUILog infoLog:ListenTogetherUILog
                                desc:[NSString stringWithFormat:@"未选定歌曲切歌数据为空 --- %@",
                                                                nextSong.orderSong.songId]];
    }
  }
}

- (BOOL)shouldAutorotate {
  return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationPortrait;
}

#pragma mark---------- NESongPointProtocol -----------
- (void)onOrderSong:(NEOrderSongResponse *)songModel error:(NSString *)errorMessage {
  if (songModel) {
    // 点歌成功
    /// 获取房间播放信息，如果存在则不处理
    [NEOrderSong.getInstance queryPlayingSongInfo:^(NSInteger code, NSString *_Nullable msg,
                                                    NEOrderSongPlayMusicInfo *_Nullable model) {
      if (code == NEVoiceRoomErrorCode.success) {
        if (model) {
          // 有播放中歌曲
        } else {
          [self readySongModel:songModel.orderSong.orderId];
        }
      }
    }];

  } else {
    // 点歌失败 , View 层error已处理
  }
}

- (NSInteger)onLyricTime {
  return self.time;
}

- (void)onLyricSeek:(NSInteger)seek {
  self.time = seek;
  [[NEVoiceRoomKit getInstance] setPlayingPositionWithPosition:seek];
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
  NSDictionary *songDic = @{
    @"songId" : [NEListenTogetherPickSongEngine sharedInstance]
        .currrentSongModel.playMusicInfo.songId,
    @"channel" : [NSNumber numberWithLong:[NEListenTogetherPickSongEngine sharedInstance]
                                              .currrentSongModel.playMusicInfo.oc_channel],
    @"progress" : [NSNumber numberWithLong:seek]
  };
  [[NEVoiceRoomKit getInstance] sendCustomMessage:userUuid
                                        commandId:NEListenTogetherCustomActionSendPosition
                                             data:songDic.yx_modelToJSONString
                                         callback:nil];
}

- (void)singSong:(NEOrderSongSongModel *)songModel {
  self.time = 0;
  dispatch_async(dispatch_get_main_queue(), ^{
    NSInteger duration = songModel.playMusicInfo.oc_songTime;
    if (duration <= 0) {
      duration = (int)[[NEVoiceRoomKit getInstance] getEffectDuration];
    }
    self.lyricActionView.lyricDuration = duration;
    self.lyricActionView.songName = songModel.playMusicInfo.songName;
    self.lyricActionView.songSingers = songModel.playMusicInfo.singer;
  });

  NSString *lyric = [self fetchLyricContentWithSongId:songModel.playMusicInfo.songId
                                              channel:(int)songModel.playMusicInfo.oc_channel];

  // 开始合唱，展示歌词页，独唱展示打分，合唱展示歌词
  dispatch_async(dispatch_get_main_queue(), ^{
    if (lyric.length) {
      [self.lyricActionView
          setLyricContent:lyric
                lyricType:songModel.playMusicInfo.oc_channel == MIGU ? NELyricTypeKas
                                                                     : NELyricTypeYrc];
      self.lyricActionView.hidden = NO;
      self.lyricActionView.lyricSeekBtnHidden = true;
      self.lyricControlView.hidden = NO;
    } else {
      self.lyricControlView.hidden = YES;
      self.lyricActionView.hidden = YES;
    }
  });

  NSString *originPath =
      [self fetchOriginalFilePathWithSongId:songModel.playMusicInfo.songId
                                    channel:(int)songModel.playMusicInfo.oc_channel];
  NSString *accompanyPath =
      [self fetchAccompanyFilePathWithSongId:songModel.playMusicInfo.songId
                                     channel:(int)songModel.playMusicInfo.oc_channel];
  // 默认设置一把采集音量
  [self.audioManager adjustRecordingSignalVolume:[self.audioManager getRecordingSignalVolume]];

  int volume = 100;
  if (self.pickSongView) {
    volume = self.pickSongView.getVolume * 100;
  }

  if (originPath.length > 0) {
    NEVoiceRoomCreateAudioEffectOption *option = [NEVoiceRoomCreateAudioEffectOption new];
    option.startTimeStamp = 3000;
    option.path = originPath;
    option.playbackVolume = volume;
    option.sendVolume = 0;
    option.sendEnabled = false;
    option.progressInterval = 100;
    option.sendWithAudioType = NEVoiceRoomAudioStreamTypeMain;
    NSInteger code = [[NEVoiceRoomKit getInstance] playEffect:NEVoiceRoomKit.OriginalEffectId
                                                       option:option];
    if (code != 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.lyricControlView.hidden = YES;
        self.lyricControlView.isPlaying = NO;
        self.lyricActionView.hidden = YES;
        [self.micQueueView stop];
      });

    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        //        [self.micQueueView play];
        self.lyricControlView.hidden = NO;
        self.lyricControlView.isPlaying = YES;
        self.lyricActionView.hidden = NO;
      });
    }

  } else if (accompanyPath.length > 0) {
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.micQueueView stop];
      self.lyricControlView.hidden = YES;
      self.lyricControlView.isPlaying = NO;
      self.lyricActionView.hidden = YES;
    });
  }
}

#pragma mark------ NEListenTogetherPickSongViewProtocol

- (void)pauseSong {
  [[NEOrderSong getInstance]
      requestPausePlayingSong:[NEListenTogetherPickSongEngine sharedInstance]
                                  .currrentSongModel.playMusicInfo.orderId
                     callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){
                         // 歌曲暂停
                         //                       [self.micQueueView stop];
                     }];
}

- (void)resumeSong {
  [[NEOrderSong getInstance]
      requestResumePlayingSong:[NEListenTogetherPickSongEngine sharedInstance]
                                   .currrentSongModel.playMusicInfo.orderId
                      callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){
                          /// 继续播放
                          //                        [self.micQueueView play];
                      }];
}

- (void)nextSong:(NEOrderSongResponseOrderSongModel *_Nullable)orderSongModel {
  if (orderSongModel) {
    NSMutableDictionary *attach = [NSMutableDictionary new];
    if (orderSongModel.songId.length) {
      attach[@"songId"] = orderSongModel.songId;
    }
    attach[@"channel"] = [NSNumber numberWithInteger:orderSongModel.oc_channel];
    attach[@"orderId"] = [NSNumber numberWithInteger:orderSongModel.orderId];
    /// 选的某首歌曲
    [[NEOrderSong getInstance]
        nextSongWithOrderId:[NEListenTogetherPickSongEngine sharedInstance]
                                .currrentSongModel.playMusicInfo.orderId
                 attachment:attach.yx_modelToJSONString
                   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){

                   }];
  } else {
    /// 点击切歌按钮
    [[NEOrderSong getInstance]
        nextSongWithOrderId:[NEListenTogetherPickSongEngine sharedInstance]
                                .currrentSongModel.playMusicInfo.orderId
                 attachment:@""
                   callback:^(NSInteger code, NSString *_Nullable msg, id _Nullable obj){

                   }];
  }
}

- (void)volumeChanged:(float)volume {
  [[NEVoiceRoomKit getInstance] setEffectVolume:NEVoiceRoomKit.OriginalEffectId
                                         volume:volume * 100];
}

#pragma mark-------- NEListenTogetherLyricControlViewDelegate
- (void)pauseSongWithView:(NEListenTogetherLyricControlView *)view {
  [self pauseSong];
}

- (void)resumeSongWithView:(NEListenTogetherLyricControlView *)view {
  [self resumeSong];
}

- (void)nextSongWithView:(NEListenTogetherLyricControlView *)view {
  [self nextSong:nil];
}
- (void)onVoiceRoomSongTokenExpired {
  [[NEOrderSong getInstance] getSongTokenWithCallback:^(NSInteger code, NSString *_Nullable msg,
                                                        NEOrderSongDynamicToken *_Nullable token) {
    if (code == 0) {
      [[NEOrderSong getInstance] renewToken:token.accessToken];
    }
  }];
}
@end
