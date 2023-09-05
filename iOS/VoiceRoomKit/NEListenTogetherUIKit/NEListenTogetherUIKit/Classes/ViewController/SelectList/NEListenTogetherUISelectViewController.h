// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEVoiceRoomKit/NEVoiceRoomKit-Swift.h>
#import <UIKit/UIKit.h>
#import "NEListenTogetherUIEmptyView.h"
#import "NEListenTogetherUINavigationBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEListenTogetherUISelectViewController
    : UIViewController <UITableViewDataSource, UITableViewDataSource>
@property(nonatomic, strong) NEListenTogetherUINavigationBar *navBar;
@property(nonatomic, strong) UITableView *tableview;
@property(nonatomic, strong) NEListenTogetherUIEmptyView *emptyView;
@property(nonatomic, strong) NSMutableArray<NEVoiceRoomMember *> *showMembers;

@end

NS_ASSUME_NONNULL_END
