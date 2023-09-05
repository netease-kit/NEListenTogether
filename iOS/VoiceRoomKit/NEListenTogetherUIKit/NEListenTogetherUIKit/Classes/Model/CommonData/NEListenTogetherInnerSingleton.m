// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEListenTogetherInnerSingleton.h"

static NEListenTogetherInnerSingleton *singleton = nil;
@implementation NEListenTogetherInnerSingleton
+ (instancetype)singleton {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    singleton = [NEListenTogetherInnerSingleton new];
  });
  return singleton;
}
- (NSArray<NEVoiceRoomSeatItem *> *)fetchAudienceSeatItems:
    (NSArray<NEVoiceRoomSeatItem *> *)seatItems {
  NSMutableArray *tempArr = @[].mutableCopy;
  for (NEVoiceRoomSeatItem *item in seatItems) {
    if (![item.user isEqualToString:self.roomInfo.anchor.userUuid]) {
      [tempArr addObject:item];
    }
  }
  return tempArr.copy;
}
- (NEVoiceRoomSeatItem *)fetchAnchorItem:(NSArray<NEVoiceRoomSeatItem *> *)seatItems {
  NEVoiceRoomSeatItem *anchorItem = nil;
  for (NEVoiceRoomSeatItem *item in seatItems) {
    if ([item.user isEqualToString:self.roomInfo.anchor.userUuid]) {
      anchorItem = item;
    }
  }
  return anchorItem;
}

- (NEVoiceRoomSeatItem *)fetchListenTogetherItem:(NSArray<NEVoiceRoomSeatItem *> *)seatItems {
  NEVoiceRoomSeatItem *listenTogetherItem = nil;
  for (NEVoiceRoomSeatItem *item in seatItems) {
    if (![item.user isEqualToString:self.roomInfo.anchor.userUuid]) {
      listenTogetherItem = item;
      break;
    }
  }
  return listenTogetherItem;
}
@end
