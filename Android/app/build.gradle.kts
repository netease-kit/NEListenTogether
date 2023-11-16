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
    compileSdk = 33
    defaultConfig {
        applicationId = "com.netease.yunxin.app.listentogether"
        minSdk = 21
        targetSdk = 30
        versionCode = 160
        versionName = "1.6.0"
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
    implementation("com.netease.yunxin.kit:alog:1.1.0")
    implementation(project(":listentogetherkit-ui"))
    implementation("com.netease.yunxin.kit.common:common-ui:1.3.1")
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.netease.yunxin.kit.copyrightedmedia:copyrightedmedia:1.7.0")
    implementation("com.netease.yunxin.kit.room:roomkit:1.20.0")
    implementation(project(":voiceroomkit"))

}