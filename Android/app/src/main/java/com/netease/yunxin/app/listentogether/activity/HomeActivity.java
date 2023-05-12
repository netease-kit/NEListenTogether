// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.listentogether.activity;

import android.text.TextUtils;
import android.view.View;
import androidx.annotation.Nullable;
import com.blankj.utilcode.util.ToastUtils;
import com.google.android.material.tabs.TabLayout;
import com.netease.yunxin.app.listentogether.R;
import com.netease.yunxin.app.listentogether.adapter.MainPagerAdapter;
import com.netease.yunxin.app.listentogether.config.AppConfig;
import com.netease.yunxin.app.listentogether.databinding.ActivityHomeBinding;
import com.netease.yunxin.kit.alog.ALog;
import com.netease.yunxin.kit.copyrightedmedia.api.SongScene;
import com.netease.yunxin.kit.entertainment.common.activity.BasePartyActivity;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherCallback;
import com.netease.yunxin.kit.listentogetherkit.api.NEListenTogetherKit;
import com.netease.yunxin.kit.ordersong.core.NEOrderSongService;
import java.util.Objects;
import kotlin.Unit;

public class HomeActivity extends BasePartyActivity {
  private static final String TAG = "HomeActivity";
  private ActivityHomeBinding binding;
  public int curTabIndex = -1;

  @Override
  protected View getRootView() {
    binding = ActivityHomeBinding.inflate(getLayoutInflater());
    return binding.getRoot();
  }

  @Override
  protected void init() {
    curTabIndex = -1;
    login(AppConfig.ACCOUNT, AppConfig.TOKEN);
    initViews();
  }

  private void initViews() {
    binding.vpFragment.setAdapter(new MainPagerAdapter(getSupportFragmentManager()));
    binding.vpFragment.setOffscreenPageLimit(2);
    binding.tlTab.setupWithViewPager(binding.vpFragment);
    binding.tlTab.removeAllTabs();
    binding.tlTab.setTabGravity(TabLayout.GRAVITY_CENTER);
    binding.tlTab.setSelectedTabIndicator(null);
    binding.tlTab.addTab(
        binding.tlTab.newTab().setCustomView(R.layout.view_item_home_tab_app), 0, true);
    binding.tlTab.addTab(
        binding.tlTab.newTab().setCustomView(R.layout.view_item_home_tab_user), 1, false);
    binding.vpFragment.addOnPageChangeListener(
        new TabLayout.TabLayoutOnPageChangeListener(binding.tlTab) {

          @Override
          public void onPageSelected(int position) {
            TabLayout.Tab item = binding.tlTab.getTabAt(position);
            if (item != null) {
              item.select();
            }
            super.onPageSelected(position);
          }
        });
  }

  @Override
  public void onBackPressed() {
    moveTaskToBack(true);
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    curTabIndex = -1;
    ALog.flush(true);
  }

  private void login(String account, String token) {
    if (TextUtils.isEmpty(account)) {
      ALog.d(TAG, "login but account is empty");
      ToastUtils.showShort(R.string.app_account);
      return;
    }
    if (TextUtils.isEmpty(token)) {
      ALog.d(TAG, "login but token is empty");
      ToastUtils.showShort(R.string.app_token);
      return;
    }
    NEListenTogetherKit.getInstance()
        .login(
            Objects.requireNonNull(account),
            Objects.requireNonNull(token),
            new NEListenTogetherCallback<Unit>() {

              @Override
              public void onSuccess(@Nullable Unit unit) {
                ALog.d(TAG, "NEVoiceRoomKit login success");
                String serverUrl = "https://roomkit.netease.im/";
                NEOrderSongService.INSTANCE.initialize(
                    HomeActivity.this.getApplicationContext(),
                    AppConfig.getAppKey(),
                    serverUrl,
                    account);
                NEOrderSongService.INSTANCE.setSongScene(SongScene.TYPE_LISTENING_TO_MUSIC);
                NEOrderSongService.INSTANCE.addHeader("user", account);
                NEOrderSongService.INSTANCE.addHeader("token", token);
              }

              @Override
              public void onFailure(int code, @Nullable String msg) {
                ALog.e(TAG, "NEVoiceRoomKit login failed code = " + code + ", msg = " + msg);
                ToastUtils.showShort(msg);
              }
            });
  }
}
