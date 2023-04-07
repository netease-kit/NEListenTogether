// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.listentogether.activity;

import android.os.Bundle;
import android.text.TextUtils;

import androidx.annotation.Nullable;

import com.netease.yunxin.app.listentogether.utils.NavUtils;
import com.netease.yunxin.kit.common.ui.utils.ToastUtils;
import com.netease.yunxin.kit.common.utils.NetworkUtils;
import com.netease.yunxin.kit.entertainment.common.activity.CreateRoomActivity;
import com.netease.yunxin.kit.entertainment.common.utils.ClickUtils;
import com.netease.yunxin.kit.listentogether.R;
import com.netease.yunxin.kit.listentogetherkit.api.NECreateListenTogetherRoomOptions;
import com.netease.yunxin.kit.listentogetherkit.api.NECreateListenTogetherRoomParams;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherCallback;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherKit;
import com.netease.yunxin.kit.listentogetherkit.api.NELiveType;
import com.netease.yunxin.kit.listentogetherkit.api.model.NEListenTogetherCreateRoomDefaultInfo;
import com.netease.yunxin.kit.listentogetherkit.api.model.NEListenTogetherRoomInfo;

public class ListenTogetherCreateActivity extends CreateRoomActivity {
  private static final String TAG = "ListenTogetherCreateActivity";

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding.tvChatRoom.setText(getString(R.string.listen_together));
  }

  @Override
  protected void getRoomDefault() {
    super.getRoomDefault();
    NEListenTogetherKit.getInstance()
        .getCreateRoomDefaultInfo(
            new NEListenTogetherCallback<NEListenTogetherCreateRoomDefaultInfo>() {

              @Override
              public void onSuccess(
                  @Nullable NEListenTogetherCreateRoomDefaultInfo neVoiceCreateRoomDefaultInfo) {
                binding.etRoomName.setText(neVoiceCreateRoomDefaultInfo.getTopic());
                cover = neVoiceCreateRoomDefaultInfo.getLivePicture();
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {}
            });
  }

  @Override
  protected void setEvent() {
    super.setEvent();
    binding.tvCreateRoom.setOnClickListener(
        v -> {
          if (ClickUtils.isFastClick()) {
            return;
          }

          if (!NetworkUtils.isConnected()) {
            ToastUtils.INSTANCE.showShortToast(this, getString(R.string.common_network_error));
            return;
          }
          if (TextUtils.isEmpty(binding.etRoomName.getText().toString())) {
            ToastUtils.INSTANCE.showShortToast(
                ListenTogetherCreateActivity.this,
                getString(R.string.voiceroom_empty_roomname_tips));
            return;
          }

            createRoomInner();
        });
  }

  protected void createRoomInner() {

    NECreateListenTogetherRoomParams createVoiceRoomParams =
        new NECreateListenTogetherRoomParams(
            binding.etRoomName.getText().toString(),
            username,
            LISTEN_TOGETHER_COUNT_SEAT,
            configId,
            cover,
            NELiveType.LIVE_TYPE_TOGETHER_LISTEN,
            null);
    NEListenTogetherKit.getInstance()
        .createRoom(
            createVoiceRoomParams,
            new NECreateListenTogetherRoomOptions(),
            new NEListenTogetherCallback<NEListenTogetherRoomInfo>() {
              @Override
              public void onSuccess(@Nullable NEListenTogetherRoomInfo roomInfo) {
                NavUtils.toListenTogetherRoomPage(
                    ListenTogetherCreateActivity.this, username, avatar, roomInfo);
                finish();
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {}
            });
  }
}
