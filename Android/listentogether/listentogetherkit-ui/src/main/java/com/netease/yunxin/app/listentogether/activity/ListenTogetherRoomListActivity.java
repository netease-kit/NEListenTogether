// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.listentogether.activity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import com.netease.yunxin.app.listentogether.adapter.ListenTogetherListAdapter;
import com.netease.yunxin.app.listentogether.utils.ListenTogetherUtils;
import com.netease.yunxin.app.listentogether.utils.NavUtils;
import com.netease.yunxin.kit.common.ui.utils.ToastUtils;
import com.netease.yunxin.kit.common.utils.NetworkUtils;
import com.netease.yunxin.kit.entertainment.common.RoomConstants;
import com.netease.yunxin.kit.entertainment.common.activity.RoomListActivity;
import com.netease.yunxin.kit.entertainment.common.adapter.RoomListAdapter;
import com.netease.yunxin.kit.entertainment.common.floatplay.FloatPlayManager;
import com.netease.yunxin.kit.entertainment.common.model.RoomModel;
import com.netease.yunxin.kit.entertainment.common.utils.ClickUtils;
import com.netease.yunxin.kit.entertainment.common.utils.ReportUtils;
import com.netease.yunxin.kit.listentogether.R;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherCallback;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherKit;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherLiveState;
import com.netease.yunxin.kit.listentogetherkit.api.model.NEListenTogetherRoomInfo;
import com.netease.yunxin.kit.listentogetherkit.api.model.NERoomList;
import kotlin.Unit;

public class ListenTogetherRoomListActivity extends RoomListActivity {
  private static final String TAG_REPORT_PAGE_LISTEN_TOTHER = "page_listentogether_list";

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding.tvTitle.setText(getString(R.string.listen_together));
    ReportUtils.report(
        ListenTogetherRoomListActivity.this, TAG_REPORT_PAGE_LISTEN_TOTHER, "listentogether_enter");
  }

  @Override
  protected void setEvent() {
    super.setEvent();
    binding.ivCreateRoom.setOnClickListener(
        v -> {
          ReportUtils.report(
              ListenTogetherRoomListActivity.this,
              TAG_REPORT_PAGE_LISTEN_TOTHER,
              "listentogether_start_live");
          Intent intent = new Intent(this, ListenTogetherCreateActivity.class);
          intent.putExtra(RoomConstants.INTENT_KEY_CONFIG_ID, configId);
          intent.putExtra(RoomConstants.INTENT_USER_NAME, userName);
          intent.putExtra(RoomConstants.INTENT_AVATAR, avatar);
          startActivity(intent);
        });
    adapter.setItemOnClickListener(
        info -> {
          if (ClickUtils.isFastClick()) {
            return;
          }
          if (NetworkUtils.isConnected()) {
            handleJoinListenTogetherRoom(info);
          } else {
            ToastUtils.INSTANCE.showShortToast(
                ListenTogetherRoomListActivity.this,
                getString(
                    com.netease.yunxin.kit.entertainment.common.R.string.common_network_error));
          }
        });
  }

  @Override
  protected RoomListAdapter getRoomListAdapter() {
    return new ListenTogetherListAdapter(ListenTogetherRoomListActivity.this);
  }

  @Override
  protected void refresh() {
    super.refresh();
    NEListenTogetherKit.getInstance()
        .getRoomList(
            NEListenTogetherLiveState.Live,
            tempPageNum,
            PAGE_SIZE,
            new NEListenTogetherCallback<NERoomList>() {
              @Override
              public void onSuccess(@Nullable NERoomList neVoiceRoomList) {
                pageNum = tempPageNum;
                if (neVoiceRoomList == null
                    || neVoiceRoomList.getList() == null
                    || neVoiceRoomList.getList().isEmpty()) {
                  binding.emptyView.setVisibility(View.VISIBLE);
                  binding.rvRoomList.setVisibility(View.GONE);
                } else {
                  binding.emptyView.setVisibility(View.GONE);
                  binding.rvRoomList.setVisibility(View.VISIBLE);
                  adapter.refreshList(
                      ListenTogetherUtils.neListenTogetherRoomInfos2RoomInfos(
                          neVoiceRoomList.getList()));
                }
                binding.refreshLayout.finishRefresh(true);
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                tempPageNum = pageNum;
                binding.refreshLayout.finishRefresh(false);
                ToastUtils.INSTANCE.showShortToast(
                    ListenTogetherRoomListActivity.this, getString(R.string.voiceroom_net_error));
              }
            });
  }

  @Override
  protected void loadMore() {
    super.loadMore();
    NEListenTogetherKit.getInstance()
        .getRoomList(
            NEListenTogetherLiveState.Live,
            tempPageNum,
            PAGE_SIZE,
            new NEListenTogetherCallback<NERoomList>() {
              @Override
              public void onSuccess(@Nullable NERoomList neVoiceRoomList) {
                pageNum = tempPageNum;
                if (neVoiceRoomList != null && neVoiceRoomList.getList() != null) {
                  adapter.loadMore(
                      ListenTogetherUtils.neListenTogetherRoomInfos2RoomInfos(
                          neVoiceRoomList.getList()));
                }
                binding.refreshLayout.finishLoadMore(true);
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                tempPageNum = pageNum;
                binding.refreshLayout.finishLoadMore(false);
              }
            });
  }

  private void handleJoinListenTogetherRoom(RoomModel info) {
    if (FloatPlayManager.getInstance().isShowFloatView()) {
      AlertDialog.Builder builder = new AlertDialog.Builder(ListenTogetherRoomListActivity.this);
      builder.setTitle(getString(R.string.voiceroom_tip));
      builder.setMessage(getString(R.string.voiceroom_click_roomlist_tips));
      builder.setCancelable(true);
      builder.setPositiveButton(
          getString(R.string.voiceroom_sure),
          (dialog, which) -> {
            NEListenTogetherKit.getInstance()
                .leaveRoom(
                    new NEListenTogetherCallback<Unit>() {
                      @Override
                      public void onSuccess(@Nullable Unit unit) {
                        joinListenTogetherRoom(info);
                      }

                      @Override
                      public void onFailure(int code, @Nullable String msg) {}
                    });
            dialog.dismiss();
          });
      builder.setNegativeButton(
          getString(R.string.voiceroom_cancel), (dialog, which) -> dialog.dismiss());
      AlertDialog alertDialog = builder.create();
      alertDialog.show();
    } else {
      joinListenTogetherRoom(info);
    }
  }

  private void joinListenTogetherRoom(RoomModel info) {
    NEListenTogetherKit.getInstance()
        .getRoomInfo(
            info.getLiveRecordId(),
            new NEListenTogetherCallback<NEListenTogetherRoomInfo>() {
              @Override
              public void onSuccess(@Nullable NEListenTogetherRoomInfo neVoiceRoomInfo) {
                if (neVoiceRoomInfo.getLiveModel() != null
                    && neVoiceRoomInfo.getLiveModel().getAudienceCount()
                        >= ROOM_MAX_AUDIENCE_COUNT) {
                  ToastUtils.INSTANCE.showShortToast(
                      ListenTogetherRoomListActivity.this,
                      getString(R.string.listen_join_live_error));
                } else {
                  NavUtils.toListenTogetherAudiencePage(
                      ListenTogetherRoomListActivity.this, userName, avatar, info);
                }
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ToastUtils.INSTANCE.showShortToast(
                    ListenTogetherRoomListActivity.this,
                    getString(R.string.voiceroom_room_not_exist));
              }
            });
  }
}
