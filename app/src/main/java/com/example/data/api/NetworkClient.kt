package com.example.data.api

import android.content.Context
import android.content.SharedPreferences
import com.example.data.models.RefreshTokenRequest
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.runBlocking
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

class NetworkClient(private val context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("shopgenie_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_BASE_URL = "api_base_url"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_ESP32_URL = "esp32_cam_url"
        private const val KEY_SHOP_NAME = "shop_name"
        private const val KEY_USERNAME = "username"
        private const val KEY_USER_ROLE = "user_role"
        private const val KEY_CAN_CONFIRM_BILLS = "can_confirm_bills"
        private const val KEY_CAN_VIEW_INVOICES = "can_view_invoices"
        private const val KEY_IS_WORKER_ACTIVE = "is_worker_active"

        // Default local and emulator-friendly endpoints
        const val DEFAULT_BASE_URL = "http://10.0.2.2:8000/"
        const val DEFAULT_ESP32_URL = "http://192.168.1.100:81/stream"

        @Volatile
        private var instance: NetworkClient? = null

        fun getInstance(context: Context): NetworkClient {
            return instance ?: synchronized(this) {
                instance ?: NetworkClient(context.applicationContext).also { instance = it }
            }
        }
    }

    var baseUrl: String
        get() {
            var url = prefs.getString(KEY_BASE_URL, DEFAULT_BASE_URL) ?: DEFAULT_BASE_URL
            if (!url.endsWith("/")) url += "/"
            return url
        }
        set(value) {
            var formatted = value.trim()
            if (!formatted.endsWith("/")) formatted += "/"
            prefs.edit().putString(KEY_BASE_URL, formatted).apply()
            rebuildRetrofit()
        }

    var accessToken: String?
        get() = prefs.getString(KEY_ACCESS_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_ACCESS_TOKEN, value).apply()

    var refreshToken: String?
        get() = prefs.getString(KEY_REFRESH_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_REFRESH_TOKEN, value).apply()

    var esp32Url: String
        get() = prefs.getString(KEY_ESP32_URL, DEFAULT_ESP32_URL) ?: DEFAULT_ESP32_URL
        set(value) = prefs.edit().putString(KEY_ESP32_URL, value.trim()).apply()

    var currentShopName: String?
        get() = prefs.getString(KEY_SHOP_NAME, "My Kirana Store")
        set(value) = prefs.edit().putString(KEY_SHOP_NAME, value).apply()

    var currentUsername: String?
        get() = prefs.getString(KEY_USERNAME, "kirana_owner")
        set(value) = prefs.edit().putString(KEY_USERNAME, value).apply()

    var userRole: String
        get() = prefs.getString(KEY_USER_ROLE, "SHOP_OWNER") ?: "SHOP_OWNER"
        set(value) = prefs.edit().putString(KEY_USER_ROLE, value).apply()

    val isOwner: Boolean
        get() = userRole == "SHOP_OWNER"

    val isWorker: Boolean
        get() = userRole == "SHOP_WORKER"

    var canConfirmBills: Boolean
        get() = if (isOwner) true else prefs.getBoolean(KEY_CAN_CONFIRM_BILLS, true)
        set(value) = prefs.edit().putBoolean(KEY_CAN_CONFIRM_BILLS, value).apply()

    var canViewInvoices: Boolean
        get() = if (isOwner) true else prefs.getBoolean(KEY_CAN_VIEW_INVOICES, true)
        set(value) = prefs.edit().putBoolean(KEY_CAN_VIEW_INVOICES, value).apply()

    var isWorkerActive: Boolean
        get() = prefs.getBoolean(KEY_IS_WORKER_ACTIVE, true)
        set(value) = prefs.edit().putBoolean(KEY_IS_WORKER_ACTIVE, value).apply()

    init {
        // Initialize merchant session so the owner has instant access to all screens and options
        if (prefs.getString(KEY_ACCESS_TOKEN, null).isNullOrBlank()) {
            enableDemoSession()
        }
    }

    fun enableDemoSession() {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.shopgenie_demo_token")
            .putString(KEY_REFRESH_TOKEN, "shopgenie_demo_refresh_token")
            .putString(KEY_USERNAME, "kirana_owner")
            .putString(KEY_SHOP_NAME, "Shree Kirana Store")
            .putString(KEY_USER_ROLE, "SHOP_OWNER")
            .putBoolean(KEY_CAN_CONFIRM_BILLS, true)
            .putBoolean(KEY_CAN_VIEW_INVOICES, true)
            .putBoolean(KEY_IS_WORKER_ACTIVE, true)
            .apply()
    }

    fun enableWorkerDemoSession() {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.shopgenie_worker_token")
            .putString(KEY_REFRESH_TOKEN, "shopgenie_worker_refresh_token")
            .putString(KEY_USERNAME, "ramesh_worker")
            .putString(KEY_SHOP_NAME, "Shree Kirana Store")
            .putString(KEY_USER_ROLE, "SHOP_WORKER")
            .putBoolean(KEY_CAN_CONFIRM_BILLS, true)
            .putBoolean(KEY_CAN_VIEW_INVOICES, true)
            .putBoolean(KEY_IS_WORKER_ACTIVE, true)
            .apply()
    }

    fun clearSession() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_USERNAME)
            .remove(KEY_USER_ROLE)
            .apply()
    }

    val isLoggedIn: Boolean
        get() = !accessToken.isNullOrBlank()

    private val moshi: Moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()

    // Auth Interceptor: Automatically injects Bearer <token>
    private val authInterceptor = Interceptor { chain ->
        val originalRequest = chain.request()
        val token = accessToken

        val newRequest = if (!token.isNullOrBlank()) {
            originalRequest.newBuilder()
                .header("Authorization", "Bearer $token")
                .header("Accept", "application/json")
                .build()
        } else {
            originalRequest.newBuilder()
                .header("Accept", "application/json")
                .build()
        }

        val response = chain.proceed(newRequest)

        // Automatic Token Refresh on 401 Unauthorized
        if (response.code == 401 && !refreshToken.isNullOrBlank()) {
            synchronized(this) {
                // Check if another thread already refreshed it
                val latestToken = accessToken
                if (latestToken != token && !latestToken.isNullOrBlank()) {
                    response.close()
                    val retryRequest = originalRequest.newBuilder()
                        .header("Authorization", "Bearer $latestToken")
                        .build()
                    return@Interceptor chain.proceed(retryRequest)
                }

                val currentRefresh = refreshToken
                if (!currentRefresh.isNullOrBlank()) {
                    try {
                        val refreshCall = rawClient.newCall(
                            okhttp3.Request.Builder()
                                .url(baseUrl + "api/auth/refresh/")
                                .post("""{"refresh":"$currentRefresh"}""".toRequestBody("application/json".toMediaType()))
                                .build()
                        ).execute()

                        if (refreshCall.isSuccessful) {
                            val bodyStr = refreshCall.body?.string()
                            val adapter = moshi.adapter(Map::class.java)
                            val map = adapter.fromJson(bodyStr ?: "")
                            val newAccess = map?.get("access") as? String
                            if (!newAccess.isNullOrBlank()) {
                                accessToken = newAccess
                                response.close()
                                val retryRequest = originalRequest.newBuilder()
                                    .header("Authorization", "Bearer $newAccess")
                                    .build()
                                return@Interceptor chain.proceed(retryRequest)
                            }
                        } else {
                            clearSession()
                        }
                    } catch (e: Exception) {
                        // Refresh failed
                    }
                }
            }
        }

        response
    }

    private val rawClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    private var okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .addInterceptor(authInterceptor)
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        })
        .build()

    private var retrofit: Retrofit = Retrofit.Builder()
        .baseUrl(baseUrl)
        .client(okHttpClient)
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()

    var apiService: ShopGenieApiService = retrofit.create(ShopGenieApiService::class.java)
        private set

    private fun rebuildRetrofit() {
        retrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
        apiService = retrofit.create(ShopGenieApiService::class.java)
    }
}
