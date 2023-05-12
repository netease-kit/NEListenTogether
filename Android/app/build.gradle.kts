/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    compileSdk = 31
    defaultConfig {
        applicationId = "com.netease.yunxin.app.listentogether"
        minSdk = 21
        targetSdk = 30
        versionCode = 1
        versionName = "1.2.0"
        multiDexEnabled = true
    }
    buildFeatures {
        viewBinding = true
    }

    lint {
        disable += "IconDensities"
    }

    packagingOptions {
        jniLibs.pickFirsts.add("lib/arm64-v8a/libc++_shared.so")
        jniLibs.pickFirsts.add("lib/armeabi-v7a/libc++_shared.so")
    }
}


dependencies {

    implementation("com.google.android.material:material:1.5.0")
    implementation("com.netease.yunxin.kit:alog:1.0.9")
    implementation(project(":listentogether:listentogetherkit"))
    implementation(project(":listentogether:listentogetherkit-ui"))
    implementation("com.netease.yunxin.kit.common:common-ui:1.1.20")
    implementation("com.blankj:utilcodex:1.30.6")
    implementation("com.gyf.immersionbar:immersionbar:3.0.0")
    implementation("com.netease.yunxin.kit.copyrightedmedia:copyrightedmedia:1.6.0")
    implementation("com.netease.yunxin.kit.room:roomkit:1.14.0")
    implementation("com.netease.yunxin:nertc-base:4.6.50")
    implementation("com.netease.yunxin.kit.voiceroom:voiceroomkit:1.3.1")

}