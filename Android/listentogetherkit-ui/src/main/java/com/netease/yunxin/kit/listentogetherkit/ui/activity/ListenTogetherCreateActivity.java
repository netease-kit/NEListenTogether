// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.kit.listentogetherkit.ui.activity;

import android.os.Bundle;
import android.text.TextUtils;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import com.netease.yunxin.kit.alog.ALog;
import com.netease.yunxin.kit.common.ui.utils.ToastUtils;
import com.netease.yunxin.kit.common.ui.utils.ToastX;
import com.netease.yunxin.kit.entertainment.common.utils.ClickUtils;
import com.netease.yunxin.kit.entertainment.common.utils.Utils;
import com.netease.yunxin.kit.entertainment.common.utils.VoiceRoomUtils;
import com.netease.yunxin.kit.listentogetherkit.ui.R;
import com.netease.yunxin.kit.listentogetherkit.ui.utils.NavUtils;
import com.netease.yunxin.kit.voiceroomkit.api.NECreateVoiceRoomOptions;
import com.netease.yunxin.kit.voiceroomkit.api.NECreateVoiceRoomParams;
import com.netease.yunxin.kit.voiceroomkit.api.NELiveType;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomCallback;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomKit;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomSeatApplyMode;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceCreateRoomDefaultInfo;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomInfo;
import com.netease.yunxin.kit.voiceroomkit.ui.base.activity.CommonCreateRoomActivity;
import kotlin.Unit;

public class ListenTogetherCreateActivity extends CommonCreateRoomActivity {
  private static final String TAG = "ListenTogetherCreateActivity";
  protected static final int LISTEN_TOGETHER_COUNT_SEAT = 2;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding.tvChatRoom.setText(getString(R.string.listen_together));
  }

  @Override
  protected void getRoomDefault() {
    super.getRoomDefault();
    NEVoiceRoomKit.getInstance()
        .getCreateRoomDefaultInfo(
            new NEVoiceRoomCallback<NEVoiceCreateRoomDefaultInfo>() {

              @Override
              public void onSuccess(
                  @Nullable NEVoiceCreateRoomDefaultInfo neVoiceCreateRoomDefaultInfo) {
                if (neVoiceCreateRoomDefaultInfo != null) {
                  binding.etRoomName.setText(neVoiceCreateRoomDefaultInfo.getTopic());
                  cover = neVoiceCreateRoomDefaultInfo.getLivePicture();
                }
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
          if (TextUtils.isEmpty(binding.etRoomName.getText().toString())) {
            ToastUtils.INSTANCE.showShortToast(
                ListenTogetherCreateActivity.this,
                getString(R.string.voiceroom_empty_roomname_tips));
            return;
          }
          if (VoiceRoomUtils.isShowFloatView()) {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle(getString(R.string.voiceroom_tip));
            builder.setMessage(getString(R.string.click_create_room_tips));
            builder.setCancelable(true);
            builder.setPositiveButton(
                getString(R.string.voiceroom_sure),
                (dialog, which) -> {
                  if (VoiceRoomUtils.isLocalAnchor()) {
                    NEVoiceRoomKit.getInstance()
                        .endRoom(
                            new NEVoiceRoomCallback<Unit>() {
                              @Override
                              public void onSuccess(@Nullable Unit unit) {
                                ToastUtils.INSTANCE.showShortToast(
                                    Utils.getApp(),
                                    Utils.getApp()
                                        .getString(R.string.voiceroom_host_close_room_success));
                                createRoomInner();
                              }

                              @Override
                              public void onFailure(int code, @Nullable String msg) {
                                ALog.e(TAG, "endRoom failed code:" + code + ",msg:" + msg);
                              }
                            });
                  } else {
                    NEVoiceRoomKit.getInstance()
                        .leaveRoom(
                            new NEVoiceRoomCallback<Unit>() {
                              @Override
                              public void onSuccess(@Nullable Unit unit) {
                                createRoomInner();
                              }

                              @Override
                              public void onFailure(int code, @Nullable String msg) {
                                ALog.e(TAG, "leaveRoom failed code:" + code + ",msg:" + msg);
                              }
                            });
                  }
                  VoiceRoomUtils.stopFloatPlay();
                  dialog.dismiss();
                });
            builder.setNegativeButton(
                getString(R.string.voiceroom_cancel), (dialog, which) -> dialog.dismiss());
            AlertDialog alertDialog = builder.create();
            alertDialog.show();
          } else {
            createRoomInner();
          }
        });
  }

  protected void createRoomInner() {

    NECreateVoiceRoomParams createVoiceRoomParams =
        new NECreateVoiceRoomParams(
            binding.etRoomName.getText().toString(),
            username,
            LISTEN_TOGETHER_COUNT_SEAT,
            NEVoiceRoomSeatApplyMode.managerApproval,
            configId,
            cover,
            NELiveType.LIVE_TYPE_TOGETHER_LISTEN,
            null);
    NEVoiceRoomKit.getInstance()
        .createRoom(
            createVoiceRoomParams,
            new NECreateVoiceRoomOptions(),
            new NEVoiceRoomCallback<NEVoiceRoomInfo>() {
              @Override
              public void onSuccess(@Nullable NEVoiceRoomInfo roomInfo) {
                NavUtils.toListenTogetherRoomPage(
                    ListenTogetherCreateActivity.this, username, avatar, roomInfo);
                finish();
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ToastX.showShortToast(getString(R.string.ec_join_failed_tips));
              }
            });
  }
}
