// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEListenTogetherRoomListViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <Masonry/Masonry.h>
#import <NEVoiceRoomKit/NEVoiceRoomKit-Swift.h>
#import "NEListenTogetherGlobalMacro.h"
#import "NEListenTogetherLocalized.h"
#import "NEListenTogetherOpenRoomViewController.h"
#import "NEListenTogetherToast.h"
#import "NEListenTogetherUI.h"
#import "NEListenTogetherUIDeviceSizeInfo.h"
#import "NEListenTogetherUILiveListCell.h"
#import "NEListenTogetherUIManager.h"
#import "NEListenTogetherUIViewFactory.h"
#import "NEListenTogetherViewController.h"
#import "NSString+NEListenTogetherString.h"
#import "UIView+NEUIExtension.h"
@import NESocialUIKit;
@import NEVoiceRoomBaseUIKit;

@interface NEListenTogetherRoomListViewController () <UICollectionViewDelegate,
                                                      UICollectionViewDataSource>
@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) UIButton *createLiveRoomButton;
@property(nonatomic, strong) NESocialRoomListEmptyView *emptyView;
@property(nonatomic, strong) NEVRBaseRoomListViewModel *roomListViewModel;
@property(nonatomic, assign) BOOL hasEntered;
/// 是否已进入房间，亦可做防重点击
@property(nonatomic, assign) BOOL isEnterRoom;
/// 在线人数
@property(nonatomic, assign) NSInteger onlineCount;
@end

@implementation NEListenTogetherRoomListViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.title = NELocalizedString(@"一起听");

  [self getNewData];
  [self bindViewModel];
  [self setupSubviews];
}

- (void)getNewData {
  [self.roomListViewModel requestNewData];
}
- (void)bindViewModel {
  __weak typeof(self) weakSelf = self;
  self.roomListViewModel.datasChanged = ^(NSArray<NEVoiceRoomInfo *> *_Nonnull datas) {
    ntes_main_sync_safe(^{
      [weakSelf.collectionView reloadData];
      weakSelf.emptyView.hidden = [datas count] > 0;
    });
  };

  self.roomListViewModel.isLoadingChanged = ^(BOOL isLoading) {
    if (!isLoading) {
      [weakSelf.collectionView.mj_header endRefreshing];
      [weakSelf.collectionView.mj_footer endRefreshing];
    }
  };

  self.roomListViewModel.errorChanged = ^(NSError *_Nonnull error) {
    if (!error || ![error isKindOfClass:[NSError class]]) return;
    if (error.code == NEVRBaseRoomListViewModel.EMPTY_LIST_ERROR) {
      [NEListenTogetherToast showToast:NELocalizedString(@"直播列表为空")];
    } else if (error.code == NEVRBaseRoomListViewModel.NO_NETWORK_ERROR) {
      [NEListenTogetherToast showToast:NELocalizedString(@"网络异常，请稍后重试")];
    } else {
      NSString *msg =
          error.userInfo[NSLocalizedDescriptionKey] ?: NELocalizedString(@"请求直播列表错误");
      [NEListenTogetherToast showToast:msg];
    }
  };
}
- (void)setupSubviews {
  [self.view addSubview:self.collectionView];
  self.emptyView.centerX = self.collectionView.centerX;
  self.emptyView.centerY = self.collectionView.centerY - 100;
  [self.collectionView addSubview:self.emptyView];

  [self.view addSubview:self.createLiveRoomButton];

  [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.bottom.equalTo(self.view);
    make.height.mas_equalTo(UIScreenHeight -
                            [NEListenTogetherUIDeviceSizeInfo get_iPhoneNavBarHeight]);
  }];

  [self.createLiveRoomButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.equalTo(@44);
    make.right.equalTo(self.view).offset(-17);
    make.left.equalTo(self.view).offset(17);
    make.bottom.equalTo(self.view).offset(-25);
  }];

  __weak typeof(self) weakSelf = self;
  MJRefreshGifHeader *mjHeader = [MJRefreshGifHeader headerWithRefreshingBlock:^{
    [weakSelf.roomListViewModel requestNewData];
  }];
  [mjHeader setTitle:NELocalizedString(@"下拉更新") forState:MJRefreshStateIdle];
  [mjHeader setTitle:NELocalizedString(@"下拉更新") forState:MJRefreshStatePulling];
  [mjHeader setTitle:NELocalizedString(@"更新中...") forState:MJRefreshStateRefreshing];
  mjHeader.lastUpdatedTimeLabel.hidden = YES;
  [mjHeader setTintColor:[UIColor whiteColor]];
  self.collectionView.mj_header = mjHeader;

  self.collectionView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
    if (weakSelf.roomListViewModel.isEnd) {
      [NEListenTogetherToast showToast:NELocalizedString(@"无更多内容")];
      [weakSelf.collectionView.mj_footer endRefreshing];
    } else {
      [weakSelf.roomListViewModel requestMoreData];
    }
  }];
}

/// 开始直播
- (void)createChatRoomAction {
  NEListenTogetherOpenRoomViewController *chatRoomCtrl =
      [[NEListenTogetherOpenRoomViewController alloc] init];
  [self.navigationController pushViewController:chatRoomCtrl animated:YES];
}

#pragma mark - UICollectionView delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return [self.roomListViewModel.datas count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [NEListenTogetherUILiveListCell cellWithCollectionView:collectionView
                                                      indexPath:indexPath
                                                          datas:self.roomListViewModel.datas];
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self.roomListViewModel.datas count] > indexPath.row) {
    NEVoiceRoomInfo *roomInfoModel = self.roomListViewModel.datas[indexPath.row];
    if ([NEListenTogetherUIManager.sharedInstance.delegate
            respondsToSelector:@selector(inOtherRoom)] &&
        [NEListenTogetherUIManager.sharedInstance.delegate inOtherRoom]) {
      // 已经在其他房间中，比如语聊房
      UIAlertController *alert = [UIAlertController
          alertControllerWithTitle:NELocalizedString(@"提示")
                           message:NELocalizedString(@"是否退出当前房间进入其他房间")
                    preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:NELocalizedString(@"取消")
                                                style:UIAlertActionStyleCancel
                                              handler:nil]];
      [alert
          addAction:[UIAlertAction actionWithTitle:NELocalizedString(@"确认")
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *_Nonnull action) {
                                             if ([NEListenTogetherUIManager.sharedInstance.delegate
                                                     respondsToSelector:@selector
                                                     (leaveOtherRoomWithCompletion:)]) {
                                               [NEListenTogetherUIManager.sharedInstance.delegate
                                                   leaveOtherRoomWithCompletion:^{
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self joinRoom:roomInfoModel];
                                                     });
                                                   }];
                                             }
                                           }]];
      [self presentViewController:alert animated:true completion:nil];
    } else {
      [self joinRoom:roomInfoModel];
    }
  }
}

- (void)joinRoom:(NEVoiceRoomInfo *)roomInfoModel {
  [[NEVoiceRoomKit getInstance]
      getRoomInfo:roomInfoModel.liveModel.liveRecordId
         callback:^(NSInteger code, NSString *_Nullable msg, NEVoiceRoomInfo *_Nullable info) {
           if (code == NEVoiceRoomErrorCode.success) {
             if (info.liveModel.audienceCount > 0) {
               [NEListenTogetherToast showToast:NELocalizedString(@"私密房内人数已满")];
             } else {
               dispatch_async(dispatch_get_main_queue(), ^{
                 [self audienceEnterLiveRoomWithListInfo:roomInfoModel];
               });
             }
           } else {
             [NEListenTogetherToast showToast:NELocalizedString(@"请稍后再试")];
           }
         }];
}

- (void)audienceEnterLiveRoomWithListInfo:(NEVoiceRoomInfo *)info {
  [NSNotificationCenter.defaultCenter
      postNotification:[NSNotification notificationWithName:@"listenTogetherEnter" object:nil]];
  NEListenTogetherViewController *vc =
      [[NEListenTogetherViewController alloc] initWithRole:NEVoiceRoomRoleAudience detail:info];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - lazy load
- (UICollectionView *)collectionView {
  if (!_collectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = [NEListenTogetherUILiveListCell size];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                         collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.whiteColor;
    [_collectionView registerClass:[NEListenTogetherUILiveListCell class]
        forCellWithReuseIdentifier:[NEListenTogetherUILiveListCell description]];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
      _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
  }
  return _collectionView;
}

- (UIButton *)createLiveRoomButton {
  if (!_createLiveRoomButton) {
    _createLiveRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_createLiveRoomButton setTitle:NELocalizedString(@"开始直播") forState:UIControlStateNormal];
    _createLiveRoomButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5);
    _createLiveRoomButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, -5);
    [_createLiveRoomButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createLiveRoomButton setImage:[NEListenTogetherUI ne_listen_imageName:@"create_ico"]
                           forState:UIControlStateNormal];
    _createLiveRoomButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.494 blue:1 alpha:1];
    [_createLiveRoomButton addTarget:self
                              action:@selector(createChatRoomAction)
                    forControlEvents:UIControlEventTouchUpInside];
    _createLiveRoomButton.layer.cornerRadius = 22;
  }
  return _createLiveRoomButton;
}

- (NESocialRoomListEmptyView *)emptyView {
  if (!_emptyView) {
    _emptyView = [[NESocialRoomListEmptyView alloc] initWithFrame:CGRectZero];
  }
  return _emptyView;
}

- (NEVRBaseRoomListViewModel *)roomListViewModel {
  if (!_roomListViewModel) {
    _roomListViewModel =
        [[NEVRBaseRoomListViewModel alloc] initWithLiveType:NEVoiceRoomLiveRoomTypeListenTogether];
  }
  return _roomListViewModel;
}
@end
