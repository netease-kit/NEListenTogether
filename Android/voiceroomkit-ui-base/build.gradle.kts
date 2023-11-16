/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    compileSdk = 33
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("com.google.android.material:material:1.5.0")
    implementation("androidx.recyclerview:recyclerview:1.2.1")
    implementation("com.airbnb.android:lottie:5.0.3")
    implementation("com.github.bumptech.glide:glide:4.13.1")
    implementation("com.github.bumptech.glide:compiler:4.13.1")
    implementation("com.netease.yunxin.kit.core:corekit:1.4.2")
    api("com.netease.yunxin.kit.common:common-ui:1.3.1")
    api("com.netease.yunxin.kit.common:common-network:1.1.8")
    api("com.netease.yunxin.kit.common:common-image:1.1.7")
    api("com.netease.yunxin.kit.copyrightedmedia:copyrightedmedia:1.8.0")
    api(project(":ordersong"))
    api(project(":entertainment-common"))
    api(project(":voiceroomkit"))
}
