// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.listentogether.utils;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import com.netease.yunxin.app.listentogether.activity.CommonSettingActivity;
import com.netease.yunxin.app.listentogether.config.AppConfig;
import com.netease.yunxin.kit.common.ui.utils.ToastX;
import com.netease.yunxin.kit.common.utils.NetworkUtils;
import com.netease.yunxin.kit.entertainment.common.Constants;
import com.netease.yunxin.kit.entertainment.common.R;
import com.netease.yunxin.kit.entertainment.common.RoomConstants;
import com.netease.yunxin.kit.entertainment.common.activity.WebViewActivity;
import com.netease.yunxin.kit.listentogetherkit.ui.activity.ListenTogetherRoomListActivity;

public class ListenTogetherNavUtils {

  private static final String TAG = "NavUtil";

  public static void toPrivacyPolicyPage(Context context) {
    toBrowsePage(
        context, context.getString(R.string.app_privacy_policy), Constants.getPrivacyPolicyUrl());
  }

  public static void toUserPolicePage(Context context) {
    toBrowsePage(
        context, context.getString(R.string.app_user_agreement), Constants.getUserAgreementUrl());
  }

  public static void toBrowsePage(Context context, String title, String url) {
    Intent intent = new Intent(context, WebViewActivity.class);
    if (!(context instanceof Activity)) {
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }
    intent.putExtra(Constants.INTENT_KEY_TITLE, title);
    intent.putExtra(Constants.INTENT_KEY_URL, url);
    context.startActivity(intent);
  }

  public static void toCommonSettingPage(Context context) {
    Intent intent = new Intent(context, CommonSettingActivity.class);
    if (!(context instanceof Activity)) {
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }
    context.startActivity(intent);
  }

  public static void toListenTogetherRoomListPage(Context context) {
    if (!NetworkUtils.isConnected()) {
      ToastX.showShortToast(context.getString(R.string.network_error));
      return;
    }
    Intent intent = new Intent(context, ListenTogetherRoomListActivity.class);
    intent.putExtra(RoomConstants.INTENT_KEY_CONFIG_ID, AppConfig.getListenTogetherConfigId());
    intent.putExtra(RoomConstants.INTENT_USER_NAME, AppUtils.getUserName());
    intent.putExtra(RoomConstants.INTENT_AVATAR, AppUtils.getAvatar());
    context.startActivity(intent);
  }
}
