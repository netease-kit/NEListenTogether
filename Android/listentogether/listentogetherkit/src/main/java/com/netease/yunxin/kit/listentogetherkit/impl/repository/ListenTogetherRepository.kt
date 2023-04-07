/*
 * Copyright (c) 2022 NetEase, Inc. All rights reserved.
 * Use of this source code is governed by a MIT license that can be
 * found in the LICENSE file.
 */

package com.netease.yunxin.kit.listentogetherkit.impl.repository

import android.content.Context
import com.netease.yunxin.kit.common.network.Response
import com.netease.yunxin.kit.common.network.ServiceCreator
import com.netease.yunxin.kit.listentogetherkit.BuildConfig
import com.netease.yunxin.kit.listentogetherkit.impl.model.ListenTogetherRoomDefaultConfig
import com.netease.yunxin.kit.listentogetherkit.impl.model.ListenTogetherRoomInfo
import com.netease.yunxin.kit.listentogetherkit.impl.model.response.VoiceRoomList
import com.netease.yunxin.kit.roomkit.api.NERoomKit
import com.netease.yunxin.kit.roomkit.impl.repository.ServerConfig
import java.util.Locale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ListenTogetherRepository {
    companion object {
        lateinit var serverConfig: ServerConfig
    }

    private val serviceCreator: ServiceCreator = ServiceCreator()

    private lateinit var listenTogetherApi: ListenTogetherApi

    fun initialize(context: Context) {
        serviceCreator.init(
            context,
            serverConfig.serverUrl,
            if (BuildConfig.DEBUG) ServiceCreator.LOG_LEVEL_BODY else ServiceCreator.LOG_LEVEL_BASIC,
            NERoomKit.getInstance().deviceId
        )
        val localLanguage = Locale.getDefault().language
        serviceCreator.addHeader(ServiceCreator.ACCEPT_LANGUAGE_KEY, localLanguage)
        listenTogetherApi = serviceCreator.create(ListenTogetherApi::class.java)
    }

    fun addHeader(key: String, value: String) {
        serviceCreator.addHeader(key, value)
    }

    suspend fun getVoiceRoomList(
        liveType: Int,
        live: Int,
        pageNum: Int,
        pageSize: Int
    ): Response<VoiceRoomList> = withContext(Dispatchers.IO) {
        val params = mapOf<String, Any?>(
            "liveType" to liveType,
            "live" to live,
            "pageNum" to pageNum,
            "pageSize" to pageSize
        )
        listenTogetherApi.getVoiceRoomList(serverConfig.appKey, params)
    }

    suspend fun startVoiceRoom(
        liveTopic: String?,
        cover: String?,
        liveType: Int,
        configId: Int,
        seatCount: Int,
        seatApplyMode: Int,
        seatInviteMode: Int
    ): Response<ListenTogetherRoomInfo> =
        withContext(Dispatchers.IO) {
            val params = mapOf<String, Any?>(
                "liveTopic" to liveTopic,
                "cover" to cover,
                "liveType" to liveType,
                "configId" to configId,
                "seatCount" to seatCount,
                "seatApplyMode" to seatApplyMode,
                "seatInviteMode" to seatInviteMode
            )
            listenTogetherApi.startVoiceRoom(serverConfig.appKey, params)
        }

    suspend fun stopVoiceRoom(liveRecordId: Long): Response<Unit> = withContext(Dispatchers.IO) {
        val params = mapOf(
            "liveRecordId" to liveRecordId
        )
        listenTogetherApi.stopVoiceRoom(serverConfig.appKey, params)
    }

    suspend fun getRoomInfo(liveRecordId: Long): Response<ListenTogetherRoomInfo> = withContext(
        Dispatchers.IO
    ) {
        val params = mapOf(
            "liveRecordId" to liveRecordId
        )
        listenTogetherApi.getRoomInfo(appKey = serverConfig.appKey, params)
    }

    suspend fun getDefaultLiveInfo(): Response<ListenTogetherRoomDefaultConfig> = withContext(
        Dispatchers.IO
    ) {
        listenTogetherApi.getDefaultLiveInfo(appKey = serverConfig.appKey)
    }

    suspend fun reward(liveRecordId: Long, giftId: Int): Response<Unit> = withContext(
        Dispatchers.IO
    ) {
        val params = mapOf(
            "liveRecordId" to liveRecordId,
            "giftId" to giftId
        )
        listenTogetherApi.reward(serverConfig.appKey, params)
    }
}
