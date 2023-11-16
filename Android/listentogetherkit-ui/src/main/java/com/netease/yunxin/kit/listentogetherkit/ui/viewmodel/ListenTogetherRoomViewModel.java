// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
package com.netease.yunxin.kit.listentogetherkit.ui.viewmodel;

import android.text.TextUtils;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.StringRes;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;
import com.netease.yunxin.kit.alog.ALog;
import com.netease.yunxin.kit.common.utils.NetworkUtils;
import com.netease.yunxin.kit.entertainment.common.livedata.SingleLiveEvent;
import com.netease.yunxin.kit.entertainment.common.utils.Utils;
import com.netease.yunxin.kit.listentogetherkit.ui.R;
import com.netease.yunxin.kit.listentogetherkit.ui.chatroom.ChatRoomMsgCreator;
import com.netease.yunxin.kit.listentogetherkit.ui.model.SeatEvent;
import com.netease.yunxin.kit.listentogetherkit.ui.model.VoiceRoomSeat;
import com.netease.yunxin.kit.listentogetherkit.ui.utils.ListenTogetherUtils;
import com.netease.yunxin.kit.listentogetherkit.ui.utils.SeatUtils;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomCallback;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomEndReason;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomKit;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomListenerAdapter;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomBatchGiftModel;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomChatTextMessage;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomMember;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomMemberVolumeInfo;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomSeatInfo;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomSeatItem;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.jetbrains.annotations.NotNull;

/** 房间、麦位业务逻辑 */
public class ListenTogetherRoomViewModel extends ViewModel {
  public static final String TAG = "RoomViewModel";
  public static final int CURRENT_SEAT_STATE_IDLE = 0;
  public static final int CURRENT_SEAT_STATE_APPLYING = 1;
  public static final int CURRENT_SEAT_STATE_ON_SEAT = 2;
  public static final int NET_AVAILABLE = 0; // 网络 可用
  public static final int NET_LOST = 1; // 网络不可用
  private static final int AUDIENCE_SEAT_INDEX = 2;

  private List<VoiceRoomSeat> roomSeats = new ArrayList<>();
  MutableLiveData<CharSequence> chatRoomMsgData = new MutableLiveData<>(); // 聊天列表数据
  MutableLiveData<Integer> memberCountData = new MutableLiveData<>(); // 房间人数
  MutableLiveData<NEVoiceRoomEndReason> errorData = new MutableLiveData<>(); // 错误信息

  public MutableLiveData<Boolean> anchorAvatarAnimation = new MutableLiveData<>();

  public MutableLiveData<Boolean> audienceAvatarAnimation = new MutableLiveData<>();
  MutableLiveData<Integer> currentSeatState = new MutableLiveData<>(CURRENT_SEAT_STATE_IDLE);
  MutableLiveData<List<VoiceRoomSeat>> onSeatListData =
      new MutableLiveData<>(ListenTogetherUtils.createSeats());
  MutableLiveData<SeatEvent> currentSeatEvent = new SingleLiveEvent<>(); // 当前操作的麦位
  MutableLiveData<Integer> netData = new MutableLiveData<>();
  public MutableLiveData<NEVoiceRoomBatchGiftModel> bachRewardData = new MutableLiveData<>();
  private final NEVoiceRoomListenerAdapter listener =
      new NEVoiceRoomListenerAdapter() {

        @Override
        public void onReceiveBatchGift(@NonNull NEVoiceRoomBatchGiftModel rewardMsg) {
          super.onReceiveBatchGift(rewardMsg);
          bachRewardData.postValue(rewardMsg);
        }

        @Override
        public void onReceiveTextMessage(@NonNull NEVoiceRoomChatTextMessage message) {
          String content = message.getText();
          ALog.i(TAG, "onReceiveTextMessage :${message.fromNick}");
          chatRoomMsgData.postValue(
              ChatRoomMsgCreator.createText(
                  Utils.getApp(),
                  ListenTogetherUtils.isHost(message.getFromUserUuid()),
                  message.getFromNick(),
                  content));
        }

        @Override
        public void onMemberAudioMuteChanged(
            @NotNull NEVoiceRoomMember member,
            boolean mute,
            @org.jetbrains.annotations.Nullable NEVoiceRoomMember operateBy) {}

        @Override
        public void onMemberJoinRoom(@NonNull List<NEVoiceRoomMember> members) {
          for (NEVoiceRoomMember member : members) {
            ALog.d(TAG, "onMemberJoinRoom :" + member.getName());
            if (!ListenTogetherUtils.isMySelf(member.getAccount())) {
              chatRoomMsgData.postValue(ChatRoomMsgCreator.createRoomEnter(member.getName()));
            }
          }
          updateRoomMemberCount();
        }

        @Override
        public void onMemberLeaveRoom(@NonNull List<NEVoiceRoomMember> members) {
          for (NEVoiceRoomMember member : members) {
            ALog.d(TAG, "onMemberLeaveRoom :" + member.getName());
            chatRoomMsgData.postValue(ChatRoomMsgCreator.createRoomExit(member.getName()));
          }
          updateRoomMemberCount();
        }

        @Override
        public void onMemberJoinChatroom(@NonNull List<NEVoiceRoomMember> members) {
          if (ListenTogetherUtils.isCurrentHost() && !members.isEmpty()) {
            NEVoiceRoomKit.getInstance()
                .sendSeatInvitation(AUDIENCE_SEAT_INDEX, members.get(0).getAccount(), null);
          }
        }

        @Override
        public void onMemberLeaveChatroom(@NonNull List<NEVoiceRoomMember> members) {}

        @Override
        public void onSeatLeave(int seatIndex, @NonNull String account) {
          if (TextUtils.equals(account, SeatUtils.getCurrentUuid())) {
            currentSeatState.postValue(CURRENT_SEAT_STATE_IDLE);
            currentSeatEvent.postValue(
                new SeatEvent(account, seatIndex, VoiceRoomSeat.Reason.LEAVE));
          }
          buildSeatEventMessage(account, getString(R.string.listen_down_seat));
        }

        @Override
        public void onSeatListChanged(@NonNull List<NEVoiceRoomSeatItem> seatItems) {
          ALog.i(TAG, "onSeatListChanged seatItems" + seatItems);
          handleSeatItemListChanged(seatItems);
        }

        @Override
        public void onRoomEnded(@NonNull NEVoiceRoomEndReason reason) {
          errorData.postValue(reason);
        }

        @Override
        public void onRtcChannelError(int code) {
          if (code == 30015) {
            errorData.postValue(NEVoiceRoomEndReason.valueOf("END_OF_RTC"));
          }
        }

        @Override
        public void onRtcLocalAudioVolumeIndication(int volume, boolean vadFlag) {
          if (ListenTogetherUtils.isCurrentHost()) {
            anchorAvatarAnimation.postValue(volume > 0);
          } else {
            for (VoiceRoomSeat roomSeat : roomSeats) {
              if (ListenTogetherUtils.isMySelf(roomSeat.getAccount()) && roomSeat.isOn()) {
                audienceAvatarAnimation.postValue(volume > 0);
              }
            }
          }
        }

        @Override
        public void onRtcRemoteAudioVolumeIndication(
            @NonNull List<? extends NEVoiceRoomMemberVolumeInfo> volumes, int totalVolume) {
          Map<String, NEVoiceRoomMemberVolumeInfo> memberVolumeInfoMap = new HashMap<>();
          for (NEVoiceRoomMemberVolumeInfo memberVolumeInfo : volumes) {
            memberVolumeInfoMap.put(memberVolumeInfo.getUserUuid(), memberVolumeInfo);
            if (ListenTogetherUtils.isHost(memberVolumeInfo.getUserUuid())) {
              anchorAvatarAnimation.postValue(memberVolumeInfo.getVolume() > 0);
            }
          }
          for (VoiceRoomSeat roomSeat : roomSeats) {
            if (!ListenTogetherUtils.isMySelf(roomSeat.getAccount())) {
              if (memberVolumeInfoMap.containsKey(roomSeat.getAccount())
                  && (Objects.requireNonNull(memberVolumeInfoMap.get(roomSeat.getAccount())))
                          .getVolume()
                      > 0) {
                if (!roomSeat.isSpeaking()) {
                  roomSeat.setSpeaking(true);
                  audienceAvatarAnimation.postValue(true);
                }
              } else {
                if (roomSeat.isSpeaking()) {
                  roomSeat.setSpeaking(false);
                  audienceAvatarAnimation.postValue(false);
                }
              }
            }
          }
        }
      };

  public MutableLiveData<Integer> getNetData() {
    return netData;
  }

  public MutableLiveData<CharSequence> getChatRoomMsgData() {
    return chatRoomMsgData;
  }

  public MutableLiveData<Integer> getMemberCountData() {
    return memberCountData;
  }

  public MutableLiveData<NEVoiceRoomEndReason> getErrorData() {
    return errorData;
  }

  public MutableLiveData<Integer> getCurrentSeatState() {
    return currentSeatState;
  }

  public MutableLiveData<List<VoiceRoomSeat>> getOnSeatListData() {
    return onSeatListData;
  }

  public LiveData<SeatEvent> getCurrentSeatEvent() {
    return currentSeatEvent;
  }

  void updateRoomMemberCount() {
    memberCountData.postValue(NEVoiceRoomKit.getInstance().getAllMemberList().size());
  }

  private final NetworkUtils.NetworkStateListener networkStateListener =
      new NetworkUtils.NetworkStateListener() {

        @Override
        public void onConnected(NetworkUtils.NetworkType networkType) {
          if (!isFirst) {
            ALog.i(TAG, "onNetworkAvailable");
            getSeatInfo();
          }
          isFirst = false;
          netData.postValue(NET_AVAILABLE);
        }

        @Override
        public void onDisconnected() {
          ALog.i(TAG, "onNetworkUnavailable");
          isFirst = false;
          netData.postValue(NET_LOST);
        }

        private boolean isFirst = true;
      };

  public void initDataOnJoinRoom() {
    NEVoiceRoomKit.getInstance().addVoiceRoomListener(listener);
    updateRoomMemberCount();
    NetworkUtils.registerNetworkStatusChangedListener(networkStateListener);
    NEVoiceRoomKit.getInstance().enableAudioVolumeIndication(true, 200);
  }

  @Override
  protected void onCleared() {
    super.onCleared();
    NetworkUtils.unregisterNetworkStatusChangedListener(networkStateListener);
    NEVoiceRoomKit.getInstance().removeVoiceRoomListener(listener);
    NEVoiceRoomKit.getInstance().enableAudioVolumeIndication(false, 200);
  }

  public void getSeatInfo() {
    NEVoiceRoomKit.getInstance()
        .getSeatInfo(
            new NEVoiceRoomCallback<NEVoiceRoomSeatInfo>() {

              @Override
              public void onSuccess(@Nullable NEVoiceRoomSeatInfo seatInfo) {
                if (seatInfo != null) {
                  handleSeatItemListChanged(seatInfo.getSeatItems());
                }
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ALog.e(TAG, "getSeatInfo failed code = " + code + " msg = " + msg);
              }
            });
  }

  private String getString(@StringRes int resId) {
    return Utils.getApp().getString(resId);
  }

  public boolean isCurrentUserOnSeat() {
    return currentSeatState.getValue() == CURRENT_SEAT_STATE_ON_SEAT;
  }

  private void handleSeatItemListChanged(List<NEVoiceRoomSeatItem> seatItems) {
    if (seatItems == null) seatItems = Collections.emptyList();
    List<VoiceRoomSeat> seats = SeatUtils.transNESeatItem2VoiceRoomSeat(seatItems);
    String currentUuid = SeatUtils.getCurrentUuid();
    VoiceRoomSeat myAfterSeat = findSeatByAccount(seats, currentUuid);
    if (myAfterSeat != null && myAfterSeat.isOn()) {
      currentSeatState.postValue(CURRENT_SEAT_STATE_ON_SEAT);
    } else if (myAfterSeat != null && myAfterSeat.getStatus() == VoiceRoomSeat.Status.APPLY) {
      currentSeatState.postValue(CURRENT_SEAT_STATE_APPLYING);
    } else {
      currentSeatState.postValue(CURRENT_SEAT_STATE_IDLE);
    }
    roomSeats = seats;
    onSeatListData.postValue(seats);
  }

  private VoiceRoomSeat findSeatByAccount(List<VoiceRoomSeat> seats, String account) {
    if (seats == null || seats.isEmpty() || account == null) return null;
    for (VoiceRoomSeat seat : seats) {
      if (seat.getMember() != null && TextUtils.equals(seat.getMember().getAccount(), account)) {
        return seat;
      }
    }
    return null;
  }

  private void buildSeatEventMessage(String account, String content) {
    if (!shouldShowSeatEventMessage(account)) return;
    String nick = SeatUtils.getMemberNick(account);
    if (!TextUtils.isEmpty(nick)) {
      chatRoomMsgData.postValue(ChatRoomMsgCreator.createSeatMessage(nick, content));
    }
  }

  private boolean shouldShowSeatEventMessage(String account) {
    return ListenTogetherUtils.isMySelf(account) || ListenTogetherUtils.isCurrentHost();
  }
}
