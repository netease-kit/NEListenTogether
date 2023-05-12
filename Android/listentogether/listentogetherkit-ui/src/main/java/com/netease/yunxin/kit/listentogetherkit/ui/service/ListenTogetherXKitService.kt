/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.kit.listentogetherkit.ui.service

import android.content.Context
import androidx.annotation.Keep
import com.netease.yunxin.kit.corekit.XKitService
import com.netease.yunxin.kit.corekit.startup.Initializer


@Keep
class ListenTogetherXKitService(override val appKey: String?) : XKitService {

    override val serviceName: String
        get() = "ListenTogetherKit"

    override val versionName: String
        get() = "1.2.0"

    override fun onMethodCall(method: String, param: Map<String, Any?>?): Any? {
        return null
    }

    override fun create(context: Context): ListenTogetherXKitService {
        // expose send team tip method
        @Suppress("UNCHECKED_CAST")
        return this
    }

    override fun dependencies(): List<Class<out Initializer<*>>> = emptyList()
}
