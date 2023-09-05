// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEVoiceRoomKit/NEVoiceRoomKit-Swift.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class NEListenTogetherUIConnectListView;

@protocol NEUIConnectListViewDelegate <NSObject>
@optional
- (void)connectListView:(NEListenTogetherUIConnectListView *)connectListView
    onAcceptWithSeatItem:(NEVoiceRoomSeatItem *)seatItem;
- (void)connectListView:(NEListenTogetherUIConnectListView *)connectListView
    onRejectWithSeatItem:(NEVoiceRoomSeatItem *)seatItem;
@end

@interface NEListenTogetherUIConnectListView : UIControl
@property(nonatomic, weak) id<NEUIConnectListViewDelegate> delegate;
- (void)refreshWithDataArray:(NSMutableArray *)dataArray;
- (void)showAsAlertOnView:(UIView *)view;
@end

NS_ASSUME_NONNULL_END
