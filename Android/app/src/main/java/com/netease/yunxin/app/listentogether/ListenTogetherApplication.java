// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.listentogether;

import android.app.Application;
import android.content.Context;
import androidx.annotation.Nullable;
import com.blankj.utilcode.util.ToastUtils;
import com.netease.yunxin.app.listentogether.config.AppConfig;
import com.netease.yunxin.kit.alog.ALog;
import com.netease.yunxin.kit.entertainment.common.AppStatusManager;
import com.netease.yunxin.kit.entertainment.common.utils.IconFontUtil;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherAuthEvent;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherCallback;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherKit;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherKitConfig;
import java.util.HashMap;
import java.util.Map;
import kotlin.Unit;

public class ListenTogetherApplication extends Application {

  private static final String TAG = "ListenTogetherApplication";

  @Override
  public void onCreate() {
    super.onCreate();
    ALog.init(this, ALog.LEVEL_ALL);
    AppConfig.init(this);
    AppStatusManager.init(this);
    initAuth();
    initListenTogetherUI();
    initListenTogetherKit(
        this,
        AppConfig.getAppKey(),
        new NEListenTogetherCallback<Unit>() {

          @Override
          public void onSuccess(@Nullable Unit unit) {
            ALog.i(TAG, "initListenTogetherKit success");
          }

          @Override
          public void onFailure(int code, @Nullable String msg) {
            ALog.i(TAG, "initListenTogetherKit failed code = " + code + ", msg = " + msg);
          }
        });

    IconFontUtil.getInstance().init(this);
  }

  private void initAuth() {
    ALog.i(TAG, "initAuth");
  }

  private void initListenTogetherUI() {
    AppStatusManager.init(this);
  }

  private void initListenTogetherKit(
      Context context, String appKey, NEListenTogetherCallback<Unit> callback) {
    ALog.i(TAG, "initListenTogetherKit");
    Map<String, String> extras = new HashMap<>();
    if (AppConfig.isOversea()) {
      extras.put("serverUrl", "oversea");
    }
    NEListenTogetherKit.getInstance()
        .initialize(context, new NEListenTogetherKitConfig(appKey, extras), callback);
    NEListenTogetherKit.getInstance()
        .addAuthListener(
            evt -> {
              ALog.i(TAG, "onVoiceRoomAuthEvent evt = " + evt);
              if (evt == NEListenTogetherAuthEvent.KICK_OUT) {
                ToastUtils.showShort(R.string.app_kick_out);
              }
              if (evt != NEListenTogetherAuthEvent.LOGGED_IN) {}
            });
  }
}
