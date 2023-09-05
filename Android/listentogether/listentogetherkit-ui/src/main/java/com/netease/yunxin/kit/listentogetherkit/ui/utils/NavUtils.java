// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.kit.listentogetherkit.ui.utils;

import android.content.Context;
import android.content.Intent;
import com.netease.yunxin.kit.entertainment.common.RoomConstants;
import com.netease.yunxin.kit.entertainment.common.model.RoomModel;
import com.netease.yunxin.kit.listentogetherkit.ui.activity.ListenTogetherAnchorActivity;
import com.netease.yunxin.kit.listentogetherkit.ui.activity.ListenTogetherAudienceActivity;
import com.netease.yunxin.kit.listentogetherkit.ui.model.ListenTogetherRoomModel;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomInfo;

public class NavUtils {

  private static final String TAG = "NavUtil";

  public static void toListenTogetherRoomPage(
      Context context, String username, String avatar, NEVoiceRoomInfo roomInfo) {
    ListenTogetherRoomModel roomModel = new ListenTogetherRoomModel();
    roomModel.setLiveRecordId(roomInfo.getLiveModel().getLiveRecordId());
    roomModel.setRoomUuid(roomInfo.getLiveModel().getRoomUuid());
    roomModel.setRole(RoomConstants.ROLE_HOST);
    roomModel.setRoomName(roomInfo.getLiveModel().getLiveTopic());
    roomModel.setNick(username);
    roomModel.setAvatar(avatar);
    roomModel.setAnchorUserUuid(roomInfo.getAnchor().getAccount());
    roomModel.setAnchorNick(roomInfo.getAnchor().getNick());
    roomModel.setAnchorAvatar(roomInfo.getAnchor().getAvatar());
    Intent intent = new Intent(context, ListenTogetherAnchorActivity.class);
    intent.putExtra(RoomConstants.INTENT_ROOM_MODEL, roomModel);
    context.startActivity(intent);
  }

  public static void toListenTogetherAudiencePage(
      Context context, String username, String avatar, RoomModel roomInfo) {
    ListenTogetherRoomModel roomModel = new ListenTogetherRoomModel();
    roomModel.setLiveRecordId(roomInfo.getLiveRecordId());
    roomModel.setRoomUuid(roomInfo.getRoomUuid());
    roomModel.setRole(RoomConstants.ROLE_AUDIENCE);
    roomModel.setRoomName(roomInfo.getLiveTopic());
    roomModel.setNick(username);
    roomModel.setAvatar(avatar);
    roomModel.setAnchorUserUuid(roomInfo.getAnchorUserUuid());
    roomModel.setAnchorNick(roomInfo.getAnchorNick());
    roomModel.setAnchorAvatar(roomInfo.getAnchorAvatar());
    Intent intent = new Intent(context, ListenTogetherAudienceActivity.class);
    intent.putExtra(RoomConstants.INTENT_ROOM_MODEL, roomModel);
    context.startActivity(intent);
  }
}
