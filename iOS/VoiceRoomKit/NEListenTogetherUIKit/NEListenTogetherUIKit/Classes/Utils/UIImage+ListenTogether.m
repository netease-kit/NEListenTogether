// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIImage+ListenTogether.h"

#import "NEListenTogetherUI.h"

@implementation UIImage (ListenTogether)

+ (UIImage *)voiceRoom_imageNamed:(NSString *)name {
  return [NEListenTogetherUI ne_listen_imageName:name];
}

@end
