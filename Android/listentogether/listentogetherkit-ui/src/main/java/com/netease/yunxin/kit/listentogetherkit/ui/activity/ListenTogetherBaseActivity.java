// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.kit.listentogetherkit.ui.activity;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Application;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.IBinder;
import android.text.TextUtils;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.SeekBar;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.SwitchCompat;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.lifecycle.ViewModelProvider;
import com.netease.yunxin.kit.alog.ALog;
import com.netease.yunxin.kit.common.ui.utils.Permission;
import com.netease.yunxin.kit.common.ui.utils.ToastUtils;
import com.netease.yunxin.kit.common.utils.DeviceUtils;
import com.netease.yunxin.kit.common.utils.NetworkUtils;
import com.netease.yunxin.kit.common.utils.SizeUtils;
import com.netease.yunxin.kit.entertainment.common.activity.BaseActivity;
import com.netease.yunxin.kit.entertainment.common.gift.GifAnimationView;
import com.netease.yunxin.kit.entertainment.common.gift.GiftCache;
import com.netease.yunxin.kit.entertainment.common.gift.GiftRender;
import com.netease.yunxin.kit.entertainment.common.utils.BluetoothHeadsetUtil;
import com.netease.yunxin.kit.entertainment.common.utils.ClickUtils;
import com.netease.yunxin.kit.entertainment.common.utils.InputUtils;
import com.netease.yunxin.kit.entertainment.common.utils.ReportUtils;
import com.netease.yunxin.kit.entertainment.common.utils.Utils;
import com.netease.yunxin.kit.entertainment.common.utils.ViewUtils;
import com.netease.yunxin.kit.entertainment.common.utils.VoiceRoomUtils;
import com.netease.yunxin.kit.listentogetherkit.ui.Constants;
import com.netease.yunxin.kit.listentogetherkit.ui.R;
import com.netease.yunxin.kit.listentogetherkit.ui.chatroom.ChatRoomMsgCreator;
import com.netease.yunxin.kit.listentogetherkit.ui.core.SongPlayManager;
import com.netease.yunxin.kit.listentogetherkit.ui.core.constant.ListenTogetherConstant;
import com.netease.yunxin.kit.listentogetherkit.ui.dialog.ChatRoomAudioDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.dialog.ChatRoomMixerDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.dialog.ChatRoomMoreDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.dialog.NoticeDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.dialog.TopTipsDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.gift.GiftDialog;
import com.netease.yunxin.kit.listentogetherkit.ui.helper.AudioPlayHelper;
import com.netease.yunxin.kit.listentogetherkit.ui.model.ListenTogetherRoomModel;
import com.netease.yunxin.kit.listentogetherkit.ui.model.VoiceRoomSeat;
import com.netease.yunxin.kit.listentogetherkit.ui.service.KeepAliveService;
import com.netease.yunxin.kit.listentogetherkit.ui.utils.ListenTogetherUILog;
import com.netease.yunxin.kit.listentogetherkit.ui.utils.ListenTogetherUtils;
import com.netease.yunxin.kit.listentogetherkit.ui.viewmodel.ListenTogetherRoomViewModel;
import com.netease.yunxin.kit.listentogetherkit.ui.viewmodel.ListenTogetherViewModel;
import com.netease.yunxin.kit.listentogetherkit.ui.widget.ChatRoomMsgRecyclerView;
import com.netease.yunxin.kit.listentogetherkit.ui.widget.ListenTogetherSeatsLayout;
import com.netease.yunxin.kit.listentogetherkit.ui.widget.SeatView;
import com.netease.yunxin.kit.listentogetherkit.ui.widget.SongOptionPanel;
import com.netease.yunxin.kit.listentogetherkit.ui.widget.VolumeSetup;
import com.netease.yunxin.kit.ordersong.core.NEOrderSongService;
import com.netease.yunxin.kit.ordersong.core.model.Song;
import com.netease.yunxin.kit.ordersong.ui.NEOrderSongCallback;
import com.netease.yunxin.kit.ordersong.ui.OrderSongDialog;
import com.netease.yunxin.kit.ordersong.ui.viewmodel.OrderSongViewModel;
import com.netease.yunxin.kit.voiceroomkit.api.NEJoinVoiceRoomOptions;
import com.netease.yunxin.kit.voiceroomkit.api.NEJoinVoiceRoomParams;
import com.netease.yunxin.kit.voiceroomkit.api.NELiveType;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomAudioOutputDevice;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomCallback;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomEndReason;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomKit;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomListener;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomListenerAdapter;
import com.netease.yunxin.kit.voiceroomkit.api.NEVoiceRoomRole;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomBatchRewardTarget;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomInfo;
import com.netease.yunxin.kit.voiceroomkit.api.model.NEVoiceRoomMember;
import com.netease.yunxin.kit.voiceroomkit.impl.utils.ScreenUtil;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import kotlin.Unit;
import org.jetbrains.annotations.NotNull;

/** 主播与观众基础页，包含所有的通用UI元素 */
public abstract class ListenTogetherBaseActivity extends BaseActivity
    implements ViewTreeObserver.OnGlobalLayoutListener, Permission.PermissionCallback {

  public static final String TAG = "ListenTogetherBaseActivity";

  public static final String TAG_REPORT_PAGE = "page_listentogether_detail";

  private final String[] permissions = {Manifest.permission.RECORD_AUDIO};

  private static final int KEY_BOARD_MIN_SIZE = SizeUtils.dp2px(80);

  private static final int ANCHOR_SEAT_INDEX = 1;
  private static final int AUDIENCE_SEAT_INDEX = 2;

  protected static final int MORE_ITEM_MICRO_PHONE = 0; // 更多菜单麦克风

  protected static final int MORE_ITEM_EAR_BACK = 1; // 更多菜单耳返

  protected static final int MORE_ITEM_MIXER = 2; // 调音台

  protected static final int MORE_ITEM_AUDIO = 3; // 伴音

  protected static final int MORE_ITEM_FINISH = 4; // 更多菜单 结束房间
  protected List<ChatRoomMoreDialog.MoreItem> moreItems;
  protected TextView tvRoomName;

  protected TextView tvMemberCount;

  // 各种控制开关
  protected FrameLayout settingsContainer;

  protected ImageView ivLocalAudioSwitch;

  protected TextView tvInput;

  protected EditText edtInput;

  protected View more;

  //消息列表
  protected ChatRoomMsgRecyclerView rcyChatMsgList;

  private int rootViewVisibleHeight;

  private View rootView;

  private boolean joinRoomSuccess = false;

  protected ListenTogetherRoomModel voiceRoomInfo;

  protected ListenTogetherRoomViewModel roomViewModel;
  protected ListenTogetherViewModel viewModel;

  protected AudioPlayHelper audioPlay;

  protected int earBack = 100;

  protected boolean isAnchor = true;

  protected ChatRoomMoreDialog chatRoomMoreDialog;

  protected List<ChatRoomMoreDialog.MoreItem> moreItemList;

  protected TopTipsDialog topTipsDialog;

  protected View netErrorView;

  private GiftDialog giftDialog;

  private ImageView ivGift;
  private GiftRender giftRender;
  private ListenTogetherSeatsLayout seatsLayout;
  private SeatView.SeatInfo anchorSeatInfo;
  private SeatView.SeatInfo audienceSeatInfo;
  private SongOptionPanel songOptionPanel;
  private TextView tvOrderSong;
  private OrderSongViewModel orderSongViewModel;
  private static final int ROOM_MEMBER_MAX_COUNT = 2;
  protected int liveType;
  private SimpleServiceConnection mServiceConnection;
  private final BluetoothHeadsetUtil.BluetoothHeadsetStatusObserver
      bluetoothHeadsetStatusChangeListener =
          new BluetoothHeadsetUtil.BluetoothHeadsetStatusObserver() {
            @Override
            public void connect() {
              if (!BluetoothHeadsetUtil.hasBluetoothConnectPermission(
                  ListenTogetherBaseActivity.this)) {
                BluetoothHeadsetUtil.requestBluetoothConnectPermission(
                    ListenTogetherBaseActivity.this);
              }
            }

            @Override
            public void disconnect() {}
          };
  private final NEVoiceRoomListener roomListener =
      new NEVoiceRoomListenerAdapter() {
        @Override
        public void onMemberAudioMuteChanged(
            @NotNull NEVoiceRoomMember member,
            boolean mute,
            @org.jetbrains.annotations.Nullable NEVoiceRoomMember operateBy) {
          if (ListenTogetherUtils.isMySelf(member.getAccount())) {
            ivLocalAudioSwitch.setSelected(mute);
            getMoreItems().get(ListenTogetherBaseActivity.MORE_ITEM_MICRO_PHONE).setEnable(!mute);
            if (chatRoomMoreDialog != null) {
              chatRoomMoreDialog.updateData();
            }
          }
          if (ListenTogetherUtils.isHost(member.getAccount())) {
            anchorSeatInfo.isMute = mute;
            seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
          } else {
            audienceSeatInfo.isMute = mute;
            seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
          }
        }

        @Override
        public void onAudioOutputDeviceChanged(@NonNull NEVoiceRoomAudioOutputDevice device) {
          ListenTogetherUILog.i(TAG, "onAudioOutputDeviceChanged device = " + device);
          if (device != NEVoiceRoomAudioOutputDevice.BLUETOOTH_HEADSET
              && device != NEVoiceRoomAudioOutputDevice.WIRED_HEADSET) {
            moreItems.get(MORE_ITEM_EAR_BACK).setEnable(false);
            chatRoomMoreDialog.updateData();
            enableEarBack(false);
          }
        }
      };

  protected ChatRoomMoreDialog.OnItemClickListener onMoreItemClickListener =
      (dialog, itemView, item) -> {
        switch (item.id) {
          case MORE_ITEM_MICRO_PHONE:
            {
              toggleMuteLocalAudio();
              break;
            }

          case MORE_ITEM_EAR_BACK:
            {
              if (DeviceUtils.hasEarBack(this)) {
                boolean isEarBackEnable = NEVoiceRoomKit.getInstance().isEarbackEnable();
                if (enableEarBack(!isEarBackEnable) == 0) {
                  item.enable = !isEarBackEnable;
                  dialog.updateData();
                }
              } else {
                ToastUtils.INSTANCE.showShortToast(this, getString(R.string.listen_earback_tip));
              }
              break;
            }
          case MORE_ITEM_MIXER:
            {
              if (dialog != null && dialog.isShowing()) {
                dialog.dismiss();
              }
              showChatRoomMixerDialog();
              break;
            }
          case MORE_ITEM_AUDIO:
            {
              if (dialog != null && dialog.isShowing()) {
                dialog.dismiss();
              }
              new ChatRoomAudioDialog(ListenTogetherBaseActivity.this, audioPlay).show();
              break;
            }
          case MORE_ITEM_FINISH:
            {
              if (dialog != null && dialog.isShowing()) {
                dialog.dismiss();
              }
              doLeaveRoom();
              break;
            }
        }
        return true;
      };

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    // 屏幕常亮
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    liveType = getIntent().getIntExtra(Constants.INTENT_LIVE_TYPE, NELiveType.LIVE_TYPE_VOICE);
    voiceRoomInfo =
        (ListenTogetherRoomModel) getIntent().getSerializableExtra(Constants.INTENT_ROOM_MODEL);
    if (voiceRoomInfo == null) {
      ToastUtils.INSTANCE.showShortToast(
          ListenTogetherBaseActivity.this, getString(R.string.listen_chat_message_tips));
      finish();
      return;
    }
    roomViewModel = new ViewModelProvider(this).get(ListenTogetherRoomViewModel.class);
    orderSongViewModel = new ViewModelProvider(this).get(OrderSongViewModel.class);
    viewModel = new ViewModelProvider(this).get(ListenTogetherViewModel.class);
    setContentView(getContentViewID());
    initViews();
    audioPlay = new AudioPlayHelper(this);
    requestPermissionsIfNeeded();
    bindForegroundService();
    BluetoothHeadsetUtil.registerBluetoothHeadsetStatusObserver(
        bluetoothHeadsetStatusChangeListener);
    if (BluetoothHeadsetUtil.isBluetoothHeadsetConnected()
        && !BluetoothHeadsetUtil.hasBluetoothConnectPermission(ListenTogetherBaseActivity.this)) {
      BluetoothHeadsetUtil.requestBluetoothConnectPermission(ListenTogetherBaseActivity.this);
    }
  }

  /** 权限检查 */
  private void requestPermissionsIfNeeded() {
    Permission.requirePermissions(ListenTogetherBaseActivity.this, permissions).request(this);
  }

  @Override
  public void onGranted(@NonNull List<String> granted) {
    if (permissions.length == granted.size()) {
      enterRoomInner(
          voiceRoomInfo.getRoomUuid(),
          voiceRoomInfo.getNick(),
          voiceRoomInfo.getAvatar(),
          voiceRoomInfo.getLiveRecordId(),
          voiceRoomInfo.getRole());
    }
  }

  @Override
  public void onDenial(List<String> permissionsDenial, List<String> permissionDenialForever) {
    ToastUtils.INSTANCE.showShortToast(ListenTogetherBaseActivity.this, "permission failed!");
    ALog.i(TAG, "finish onDenial");
    finish();
  }

  @Override
  public void onException(Exception exception) {}

  private void initViews() {
    findBaseView();
    setupBaseViewInner();
    setupBaseView();
    initSeatsInfo();
    rootView = getWindow().getDecorView();
    rootView.getViewTreeObserver().addOnGlobalLayoutListener(this);
    String countStr = String.format(getString(R.string.listen_people_online), "0");
    tvMemberCount.setText(countStr);
  }

  private void initSeatsInfo() {
    anchorSeatInfo = new SeatView.SeatInfo();
    anchorSeatInfo.nickname = voiceRoomInfo.getAnchorNick();
    anchorSeatInfo.avatar = voiceRoomInfo.getAnchorAvatar();
    anchorSeatInfo.isAnchor = true;
    anchorSeatInfo.isOnSeat = true;
    anchorSeatInfo.isMute = false;
    seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
    audienceSeatInfo = new SeatView.SeatInfo();
    audienceSeatInfo.isAnchor = false;
    audienceSeatInfo.isOnSeat = false;
    seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
  }

  @Override
  protected void onDestroy() {
    if (rootView != null) {
      rootView.getViewTreeObserver().removeOnGlobalLayoutListener(this);
    }
    if (audioPlay != null) {
      audioPlay.destroy();
    }
    NEVoiceRoomKit.getInstance().removeVoiceRoomListener(roomListener);
    giftRender.release();
    SongPlayManager.getInstance().stop();
    unbindForegroundService();
    BluetoothHeadsetUtil.unregisterBluetoothHeadsetStatusObserver(
        bluetoothHeadsetStatusChangeListener);
    super.onDestroy();
  }

  @Override
  public void onBackPressed() {
    if (settingsContainer.getVisibility() == View.VISIBLE) {
      settingsContainer.setVisibility(View.GONE);
      return;
    }
    ALog.i(TAG, "onBackPressed");
    leaveRoom();
    super.onBackPressed();
  }

  @Override
  public void onGlobalLayout() {
    int preHeight = rootViewVisibleHeight;
    //获取当前根视图在屏幕上显示的大小
    Rect r = new Rect();
    rootView.getWindowVisibleDisplayFrame(r);
    rootViewVisibleHeight = r.height();
    if (preHeight == 0 || preHeight == rootViewVisibleHeight) {
      return;
    }
    //根视图显示高度变大超过KEY_BOARD_MIN_SIZE，可以看作软键盘隐藏了
    if (rootViewVisibleHeight - preHeight >= KEY_BOARD_MIN_SIZE) {
      rcyChatMsgList.toLatestMsg();
    }
  }

  private void findBaseView() {
    View baseAudioView = findViewById(R.id.rl_base_audio_ui);
    if (baseAudioView == null) {
      throw new IllegalStateException("xml layout must include base_audio_ui.xml layout");
    }
    //    int barHeight = ImmersionBar.getStatusBarHeight(this);
    int barHeight = 50;
    baseAudioView.setPadding(
        baseAudioView.getPaddingLeft(),
        baseAudioView.getPaddingTop() + barHeight,
        baseAudioView.getPaddingRight(),
        baseAudioView.getPaddingBottom());
    songOptionPanel = baseAudioView.findViewById(R.id.song_option_panel);
    songOptionPanel.setSongPositionCallback(position -> viewModel.seekTo(position));
    songOptionPanel.setLoadingCallback(
        (show) -> {
          if (isAnchor) {
            anchorSeatInfo.isLoadingSong = show;
            seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
          } else {
            audienceSeatInfo.isLoadingSong = show;
            seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
          }
        });
    NEOrderSongService.INSTANCE.setRoomUuid(voiceRoomInfo.getRoomUuid());
    NEOrderSongService.INSTANCE.setLiveRecordId(voiceRoomInfo.getLiveRecordId());
    tvRoomName = baseAudioView.findViewById(R.id.tv_chat_room_name);
    tvMemberCount = baseAudioView.findViewById(R.id.tv_chat_room_member_count);
    settingsContainer = findViewById(R.id.settings_container);
    settingsContainer.setOnClickListener(view -> settingsContainer.setVisibility(View.GONE));
    findViewById(R.id.settings_action_container).setOnClickListener(view -> {});
    SeekBar skRecordingVolume = settingsContainer.findViewById(R.id.recording_volume_control);
    skRecordingVolume.setOnSeekBarChangeListener(
        new VolumeSetup() {

          @Override
          protected void onVolume(int volume) {
            setAudioCaptureVolume(volume);
          }
        });
    SwitchCompat switchEarBack = settingsContainer.findViewById(R.id.ear_back);
    switchEarBack.setChecked(false);
    switchEarBack.setOnCheckedChangeListener(
        (buttonView, isChecked) -> {
          if (!DeviceUtils.hasEarBack(ListenTogetherBaseActivity.this)) {
            buttonView.setChecked(false);
            return;
          }
          enableEarBack(isChecked);
        });
    more = baseAudioView.findViewById(R.id.iv_room_more);
    more.setOnClickListener(
        v -> {
          moreItemList = getMoreItems();
          chatRoomMoreDialog =
              new ChatRoomMoreDialog(ListenTogetherBaseActivity.this, moreItemList);
          chatRoomMoreDialog.registerOnItemClickListener(getMoreItemClickListener());
          chatRoomMoreDialog.show();
        });
    ivLocalAudioSwitch = baseAudioView.findViewById(R.id.iv_local_audio_switch);
    ivLocalAudioSwitch.setSelected(true);
    ivLocalAudioSwitch.setOnClickListener(view -> toggleMuteLocalAudio());

    baseAudioView
        .findViewById(R.id.iv_leave_room)
        .setOnClickListener(
            v -> {
              ALog.i(TAG, "click leave room button");
              doLeaveRoom();
            });

    rcyChatMsgList = baseAudioView.findViewById(R.id.rcy_chat_message_list);
    tvInput = baseAudioView.findViewById(R.id.tv_input_text);
    tvInput.setOnClickListener(
        v -> InputUtils.showSoftInput(ListenTogetherBaseActivity.this, edtInput));
    edtInput = baseAudioView.findViewById(R.id.edt_input_text);
    edtInput.setOnEditorActionListener(
        (v, actionId, event) -> {
          InputUtils.hideSoftInput(ListenTogetherBaseActivity.this, edtInput);
          sendTextMessage();
          return true;
        });
    InputUtils.registerSoftInputListener(
        this,
        new InputUtils.InputParamHelper() {

          @Override
          public int getHeight() {
            return baseAudioView.getHeight();
          }

          @Override
          public EditText getInputView() {
            return edtInput;
          }
        });
    View announcement = baseAudioView.findViewById(R.id.tv_chat_room_announcement);
    announcement.setOnClickListener(
        v -> {
          NoticeDialog noticeDialog = new NoticeDialog();
          noticeDialog.show(getSupportFragmentManager(), "");
        });
    initGiftAnimation(baseAudioView);
    ivGift = baseAudioView.findViewById(R.id.iv_gift);
    ivGift.setOnClickListener(
        new View.OnClickListener() {
          @Override
          public void onClick(View v) {
            ReportUtils.report(
                ListenTogetherBaseActivity.this, TAG_REPORT_PAGE, "listentogether_gift");
            Application application = Utils.getApp();
            if (!NetworkUtils.isConnected()) {
              ToastUtils.INSTANCE.showShortToast(
                  application, application.getString(R.string.listen_net_error));
              return;
            }

            if (giftDialog == null) {
              giftDialog = new GiftDialog(ListenTogetherBaseActivity.this);
            }
            List<String> sendUserUuids = new ArrayList<>();
            sendUserUuids.add(voiceRoomInfo.getAnchorUserUuid());
            giftDialog.show(
                (giftId) ->
                    NEVoiceRoomKit.getInstance()
                        .sendBatchGift(
                            giftId,
                            1,
                            sendUserUuids,
                            new NEVoiceRoomCallback<Unit>() {
                              @Override
                              public void onSuccess(@Nullable Unit unit) {}

                              @Override
                              public void onFailure(int code, @Nullable String msg) {
                                ToastUtils.INSTANCE.showShortToast(
                                    application,
                                    application.getString(R.string.listen_reward_failed));
                              }
                            }));
          }
        });

    seatsLayout = baseAudioView.findViewById(R.id.seats_layout);

    tvOrderSong = baseAudioView.findViewById(R.id.tv_order_song);
    tvOrderSong.setOnClickListener(
        v -> {
          ReportUtils.report(
              ListenTogetherBaseActivity.this, TAG_REPORT_PAGE, "listentogether_order_song");
          showSingingTable();
        });

    baseAudioView.findViewById(R.id.iv_order_song).setOnClickListener(v -> showSingingTable());
  }

  private void showSingingTable() {
    if (!ClickUtils.isSlightlyFastClick()) {
      if (!NetworkUtils.isConnected()) {
        return;
      }

      OrderSongDialog dialog = new OrderSongDialog(NEVoiceRoomKit.getInstance().getEffectVolume());
      dialog.show(getSupportFragmentManager(), TAG);
    }
  }

  protected void doLeaveRoom() {
    leaveRoom();
  }

  @SuppressLint("NotifyDataSetChanged")
  private void setupBaseViewInner() {
    String name = voiceRoomInfo.getRoomName();
    name = TextUtils.isEmpty(name) ? voiceRoomInfo.getRoomUuid() : name;
    tvRoomName.setText(name);
    roomViewModel.getOnSeatListData().observe(this, voiceRoomSeats -> {});
  }

  protected abstract int getContentViewID();

  protected abstract void setupBaseView();

  @NonNull
  protected List<ChatRoomMoreDialog.MoreItem> getMoreItems() {
    return Collections.emptyList();
  }

  protected ChatRoomMoreDialog.OnItemClickListener getMoreItemClickListener() {
    return onMoreItemClickListener;
  }

  protected void onNetLost() {
    Bundle bundle = new Bundle();
    topTipsDialog = new TopTipsDialog();
    TopTipsDialog.Style style =
        topTipsDialog
        .new Style(
            getString(R.string.listen_net_disconnected), 0, R.drawable.listen_neterrricon, 0);
    bundle.putParcelable(topTipsDialog.TAG, style);
    topTipsDialog.setArguments(bundle);
    if (!topTipsDialog.isVisible()) {
      topTipsDialog.show(getSupportFragmentManager(), topTipsDialog.TAG);
    }
    netErrorView.setVisibility(View.VISIBLE);
  }

  protected void onNetAvailable() {
    if (topTipsDialog != null) {
      topTipsDialog.dismiss();
    }
    netErrorView.setVisibility(View.GONE);
  }

  private void enterRoomInner(
      String roomUuid, String nick, String avatar, long liveRecordId, String role) {
    NEJoinVoiceRoomParams params =
        new NEJoinVoiceRoomParams(
            roomUuid, nick, avatar, NEVoiceRoomRole.Companion.fromValue(role), liveRecordId, null);
    boolean isAnchor = NEVoiceRoomRole.HOST.getValue().equals(role);
    ivGift.setVisibility(isAnchor ? View.GONE : View.VISIBLE);
    if (isAnchor) {
      updateAnchorUI(nick, avatar, true);
    }
    NEJoinVoiceRoomOptions options = new NEJoinVoiceRoomOptions();
    NEVoiceRoomKit.getInstance()
        .joinRoom(
            params,
            options,
            new NEVoiceRoomCallback<NEVoiceRoomInfo>() {

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ALog.e(TAG, "joinRoom failed code = " + code + " msg = " + msg);
                if (!TextUtils.isEmpty(msg)) {
                  ToastUtils.INSTANCE.showShortToast(ListenTogetherBaseActivity.this, msg);
                } else {
                  ToastUtils.INSTANCE.showShortToast(
                      ListenTogetherBaseActivity.this,
                      getString(
                          isAnchor
                              ? R.string.listen_start_live_error
                              : R.string.listen_join_live_error));
                }
                finish();
              }

              @Override
              public void onSuccess(@Nullable NEVoiceRoomInfo roomInfo) {
                ALog.i(TAG, "joinRoom success");
                if (roomInfo.getLiveModel().getAudienceCount() >= ROOM_MEMBER_MAX_COUNT) {
                  ToastUtils.INSTANCE.showShortToast(
                      ListenTogetherBaseActivity.this,
                      getString(
                          isAnchor
                              ? R.string.listen_start_live_error
                              : R.string.listen_join_live_error));
                  ALog.e(TAG, "joinRoom success but The private room is full");
                  NEVoiceRoomKit.getInstance().leaveRoom(null);
                  finish();
                  return;
                }
                joinRoomSuccess = true;
                initViewAfterJoinRoom();
              }
            });
  }

  private void initViewAfterJoinRoom() {
    songOptionPanel.setRoomInfo(voiceRoomInfo);
    initDataObserver();
    roomViewModel.initDataOnJoinRoom();
    viewModel.initialize(voiceRoomInfo);
    if (ListenTogetherUtils.isCurrentHost()) {
      NEVoiceRoomKit.getInstance().submitSeatRequest(ANCHOR_SEAT_INDEX, true, null);
    } else {
      NEVoiceRoomMember hostMember = ListenTogetherUtils.getHost();
      if (hostMember != null) {
        updateAnchorUI(hostMember.getName(), hostMember.getAvatar(), hostMember.isAudioOn());
      }
      roomViewModel.getSeatInfo();
    }
  }

  private void updateAnchorUI(String nick, String avatar, boolean isAudioOn) {
    anchorSeatInfo.nickname = nick;
    anchorSeatInfo.avatar = avatar;
    anchorSeatInfo.isMute = !isAudioOn;
    seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
  }

  private void initDataObserver() {
    roomViewModel
        .getMemberCountData()
        .observe(
            this,
            count -> {
              String countStr = String.format(getString(R.string.listen_people_online), count + "");
              tvMemberCount.setText(countStr);
            });
    roomViewModel
        .getOnSeatListData()
        .observe(
            this,
            seatList -> {
              List<VoiceRoomSeat> audienceSeats = new ArrayList<>();
              for (VoiceRoomSeat model : seatList) {
                if (model.getSeatIndex() == AUDIENCE_SEAT_INDEX) {
                  audienceSeats.add(model);
                }
                final NEVoiceRoomMember member = model.getMember();
                if (member != null && ListenTogetherUtils.isHost(member.getAccount())) {
                  updateAnchorUI(member.getName(), member.getAvatar(), member.isAudioOn());
                }
              }
              if (audienceSeats.size() == 1) {
                NEVoiceRoomMember member = audienceSeats.get(0).getMember();
                if (member != null) {
                  audienceSeatInfo.isOnSeat = true;
                  audienceSeatInfo.nickname = member.getName();
                  audienceSeatInfo.avatar = member.getAvatar();
                  audienceSeatInfo.isMute = !member.isAudioOn();
                  audienceSeatInfo.isListenTogether = true;
                  anchorSeatInfo.isListenTogether = true;
                  seatsLayout.setIsListeningTogether(true);
                } else {
                  audienceSeatInfo.isOnSeat = false;
                  audienceSeatInfo.isListenTogether = false;
                  anchorSeatInfo.isListenTogether = false;
                  seatsLayout.setIsListeningTogether(false);
                }
                seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
                seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
              }
            });

    roomViewModel
        .getChatRoomMsgData()
        .observe(
            this,
            charSequence -> {
              rcyChatMsgList.appendItem(charSequence);
            });

    roomViewModel
        .getErrorData()
        .observe(
            this,
            endReason -> {
              if (endReason == NEVoiceRoomEndReason.CLOSE_BY_MEMBER) {
                if (!ListenTogetherUtils.isCurrentHost()) {
                  ToastUtils.INSTANCE.showShortToast(
                      ListenTogetherBaseActivity.this, getString(R.string.listen_host_close_room));
                }
                ALog.i(TAG, "finish endReason == NEVoiceRoomEndReason.CLOSE_BY_MEMBER");
                finish();
              } else if (endReason == NEVoiceRoomEndReason.END_OF_RTC) {
                ALog.i(TAG, "finish endReason == NEVoiceRoomEndReason.END_OF_RTC");
                leaveRoom();
              } else {
                ALog.i(TAG, "finish endReason");
                leaveRoom();
                finish();
              }
            });

    roomViewModel.bachRewardData.observe(
        this,
        batchReward -> {
          if (voiceRoomInfo == null) {
            return;
          }
          ALog.i(TAG, "bachRewardData observe giftModel:" + batchReward);
          List<NEVoiceRoomBatchRewardTarget> targets = batchReward.getTargets();
          if (targets.isEmpty()) {
            return;
          }
          for (NEVoiceRoomBatchRewardTarget target : targets) {
            CharSequence batchGiftReward =
                ChatRoomMsgCreator.createBatchGiftReward(
                    ListenTogetherBaseActivity.this,
                    batchReward.getUserName(),
                    target.getUserName(),
                    GiftCache.getGift(batchReward.getGiftId()).getName(),
                    batchReward.getGiftCount(),
                    GiftCache.getGift(batchReward.getGiftId()).getStaticIconResId());
            rcyChatMsgList.appendItem(batchGiftReward);
            ALog.i(TAG, "target:" + target);
          }
          if (!VoiceRoomUtils.isLocalAnchor()) {
            giftRender.addGift(GiftCache.getGift(batchReward.getGiftId()).getDynamicIconResId());
          }
        });

    viewModel
        .getPlayCurrentSongData()
        .observe(
            this,
            orderSong -> {
              tvOrderSong.setVisibility(View.GONE);
              Song songModel = new Song();
              songModel.setOrderId(orderSong.orderId);
              songModel.setSongId(orderSong.songId);
              songModel.setSongName(orderSong.songName);
              songModel.setChannel(orderSong.channel);
              songModel.setSongTime(orderSong.songTime);
              songModel.setSinger(orderSong.singer);
              songModel.setStatus(orderSong.musicStatus);
              boolean isPlaying =
                  orderSong.musicStatus == ListenTogetherConstant.SONG_PLAYING_STATE;
              seatsLayout.showAnim(isPlaying);
              songOptionPanel.setPauseOrResumeState(isPlaying);
              songOptionPanel.startPlay(
                  songModel,
                  isPlaying,
                  new NEOrderSongCallback<Void>() {
                    @Override
                    public void onSuccess(@Nullable Void unused) {}

                    @Override
                    public void onFailure(int code, @Nullable String msg) {
                      ALog.e(TAG, "startPlaySong onFailure,code:" + code + ",msg:" + msg);
                    }
                  });
            });

    viewModel
        .getShowSongPanelData()
        .observe(
            this,
            aBoolean -> {
              showSongOptionPanel(aBoolean);
            });

    viewModel
        .getChatRoomMsgData()
        .observe(this, charSequence -> rcyChatMsgList.appendItem(charSequence));

    viewModel
        .getShowOtherSongDownLoadingData()
        .observe(
            this,
            pair -> {
              if (isAnchor) {
                audienceSeatInfo.isLoadingSong = pair.first;
                seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
              } else {
                anchorSeatInfo.isLoadingSong = pair.first;
                seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
              }
            });
    viewModel
        .getShowMySongDownLoadingData()
        .observe(
            this,
            pair -> {
              if (isAnchor) {
                anchorSeatInfo.isLoadingSong = pair.first;
                seatsLayout.setAnchorSeatInfo(anchorSeatInfo);
              } else {
                audienceSeatInfo.isLoadingSong = pair.first;
                seatsLayout.setAudienceSeatInfo(audienceSeatInfo);
              }
            });
    viewModel
        .getPlayStateChangedData()
        .observe(
            this,
            integer -> {
              if (integer == ListenTogetherConstant.SONG_START) {
                seatsLayout.showAnim(true);
              } else if (integer == ListenTogetherConstant.SONG_PAUSE) {
                seatsLayout.showAnim(false);
              } else if (integer == ListenTogetherConstant.SONG_RESUME) {
                seatsLayout.showAnim(true);
              }
            });

    viewModel
        .getDeleteSongData()
        .observe(
            this,
            song -> {
              if (song.getNextOrderSong() == null) {
                showSongOptionPanel(false);
              }
            });

    orderSongViewModel
        .getOrderSongListChangeEvent()
        .observe(this, neOrderSongs -> showSongOptionPanel(!neOrderSongs.isEmpty()));

    roomViewModel.anchorAvatarAnimation.observe(
        this, show -> seatsLayout.showAnchorAvatarAnimal(show));

    roomViewModel.audienceAvatarAnimation.observe(
        this, show -> seatsLayout.showAudienceAvatarAnimal(show));

    NEVoiceRoomKit.getInstance().addVoiceRoomListener(roomListener);
  }

  private void showSongOptionPanel(boolean show) {
    if (show) {
      tvOrderSong.setVisibility(View.GONE);
    } else {
      tvOrderSong.setVisibility(View.VISIBLE);
      songOptionPanel.setVisibility(View.INVISIBLE);
      songOptionPanel.reset();
      seatsLayout.showAnim(false);
    }
  }

  protected final void leaveRoom() {
    if (ListenTogetherUtils.isCurrentHost()) {
      NEVoiceRoomKit.getInstance()
          .endRoom(
              new NEVoiceRoomCallback<Unit>() {
                @Override
                public void onSuccess(@Nullable Unit unit) {
                  ALog.i(TAG, "endRoom success");
                  ToastUtils.INSTANCE.showShortToast(
                      ListenTogetherBaseActivity.this,
                      getString(R.string.listen_host_close_room_success));
                  finish();
                }

                @Override
                public void onFailure(int code, @Nullable String msg) {
                  ALog.e(TAG, "endRoom onFailure");
                }
              });
    } else {
      NEVoiceRoomKit.getInstance()
          .leaveSeat(
              new NEVoiceRoomCallback<Unit>() {
                @Override
                public void onSuccess(@Nullable Unit unit) {
                  NEVoiceRoomKit.getInstance()
                      .leaveRoom(
                          new NEVoiceRoomCallback<Unit>() {
                            @Override
                            public void onSuccess(@Nullable Unit unit) {
                              ALog.i(TAG, "leaveRoom success");
                              finish();
                            }

                            @Override
                            public void onFailure(int code, @Nullable String msg) {
                              ALog.e(TAG, "leaveRoom onFailure");
                              ToastUtils.INSTANCE.showShortToast(
                                  getApplicationContext(),
                                  "leaveRoom failed code:" + code + ",msg:" + msg);
                            }
                          });
                }

                @Override
                public void onFailure(int code, @Nullable String msg) {
                  ALog.e(TAG, "leaveSeat onFailure code:" + code + ",msg:" + msg);
                  NEVoiceRoomKit.getInstance()
                      .leaveRoom(
                          new NEVoiceRoomCallback<Unit>() {
                            @Override
                            public void onSuccess(@Nullable Unit unit) {
                              ALog.i(TAG, "leaveRoom success");
                              finish();
                            }

                            @Override
                            public void onFailure(int code, @Nullable String msg) {
                              ALog.e(TAG, "leaveRoom onFailure");
                              ToastUtils.INSTANCE.showShortToast(
                                  getApplicationContext(),
                                  "leaveRoom failed code:" + code + ",msg:" + msg);
                            }
                          });
                }
              });
    }
  }

  protected final void toggleMuteLocalAudio() {
    if (!joinRoomSuccess) return;
    NEVoiceRoomMember localMember = NEVoiceRoomKit.getInstance().getLocalMember();
    if (localMember == null) return;
    boolean isAudioOn = localMember.isAudioOn();
    ALog.d(
        TAG,
        "toggleMuteLocalAudio,localMember.isAudioOn:"
            + isAudioOn
            + ",localMember.isAudioBanned():"
            + localMember.isAudioBanned());
    if (isAudioOn) {
      muteMyAudio(
          new NEVoiceRoomCallback<Unit>() {
            @Override
            public void onSuccess(@Nullable Unit unit) {
              ToastUtils.INSTANCE.showShortToast(
                  ListenTogetherBaseActivity.this, getString(R.string.listen_mic_off));
            }

            @Override
            public void onFailure(int code, @Nullable String msg) {}
          });
    } else {
      unmuteMyAudio(
          new NEVoiceRoomCallback<Unit>() {
            @Override
            public void onSuccess(@Nullable Unit unit) {
              ToastUtils.INSTANCE.showShortToast(
                  ListenTogetherBaseActivity.this, getString(R.string.listen_mic_on));
            }

            @Override
            public void onFailure(int code, @Nullable String msg) {}
          });
    }
  }

  protected void setAudioCaptureVolume(int volume) {
    NEVoiceRoomKit.getInstance().adjustRecordingSignalVolume(volume);
  }

  protected int enableEarBack(boolean enable) {
    if (enable) {
      return NEVoiceRoomKit.getInstance().enableEarback(earBack);
    } else {
      return NEVoiceRoomKit.getInstance().disableEarback();
    }
  }

  private void sendTextMessage() {
    String content = edtInput.getText().toString().trim();
    if (TextUtils.isEmpty(content)) {
      ToastUtils.INSTANCE.showShortToast(this, getString(R.string.listen_chat_message_tips));
      return;
    }
    NEVoiceRoomKit.getInstance()
        .sendTextMessage(
            content,
            new NEVoiceRoomCallback<Unit>() {
              @Override
              public void onSuccess(@Nullable Unit unit) {
                rcyChatMsgList.appendItem(
                    ChatRoomMsgCreator.createText(
                        ListenTogetherBaseActivity.this,
                        ListenTogetherUtils.isCurrentHost(),
                        ListenTogetherUtils.getCurrentName(),
                        content));
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ALog.e(TAG, "sendTextMessage failed code = " + code + " msg = " + msg);
              }
            });
  }

  @Override
  public boolean dispatchTouchEvent(MotionEvent ev) {
    int x = (int) ev.getRawX();
    int y = (int) ev.getRawY();
    // 键盘区域外点击收起键盘
    if (!ViewUtils.isInView(edtInput, x, y)) {
      InputUtils.hideSoftInput(ListenTogetherBaseActivity.this, edtInput);
    }
    return super.dispatchTouchEvent(ev);
  }

  /** 显示调音台 */
  public void showChatRoomMixerDialog() {
    new ChatRoomMixerDialog(ListenTogetherBaseActivity.this, audioPlay, isAnchor).show();
  }

  private void initGiftAnimation(View baseAudioView) {
    GifAnimationView gifAnimationView = new GifAnimationView(this);
    int size = ScreenUtil.getDisplayWidth();
    ConstraintLayout.LayoutParams layoutParams = new ConstraintLayout.LayoutParams(size, size);
    layoutParams.topToTop = ConstraintLayout.LayoutParams.PARENT_ID;
    layoutParams.bottomToBottom = ConstraintLayout.LayoutParams.PARENT_ID;
    ViewGroup root = (ViewGroup) baseAudioView.findViewById(R.id.rl_base_audio_ui);
    root.addView(gifAnimationView, layoutParams);
    gifAnimationView.bringToFront();
    giftRender = new GiftRender();
    giftRender.init(gifAnimationView);
  }

  public void unmuteMyAudio(NEVoiceRoomCallback<Unit> callback) {
    NEVoiceRoomKit.getInstance().unmuteMyAudio(callback);
  }

  public void muteMyAudio(NEVoiceRoomCallback<Unit> callback) {
    NEVoiceRoomKit.getInstance().muteMyAudio(callback);
  }

  @Override
  protected boolean needTransparentStatusBar() {
    return true;
  }

  private void bindForegroundService() {
    Intent intent = new Intent();
    intent.setClass(this, KeepAliveService.class);
    mServiceConnection = new SimpleServiceConnection();
    bindService(intent, mServiceConnection, Context.BIND_AUTO_CREATE);
  }

  private void unbindForegroundService() {
    if (mServiceConnection != null) {
      unbindService(mServiceConnection);
    }
  }

  private class SimpleServiceConnection implements ServiceConnection {
    @Override
    public void onServiceConnected(ComponentName componentName, IBinder service) {

      if (service instanceof KeepAliveService.SimpleBinder) {
        ALog.i(TAG, "onServiceConnect");
      }
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      ALog.i(TAG, "onServiceDisconnected");
    }
  }
}
