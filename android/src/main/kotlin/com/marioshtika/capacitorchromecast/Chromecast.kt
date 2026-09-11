package com.marioshtika.capacitorchromecast

import android.content.Context
import java.util.Locale

internal object ChromecastConfiguration {
    private const val PREFERENCES_NAME = "capacitor.chromecast"
    private const val RECEIVER_APPLICATION_ID_KEY = "receiverApplicationId"
    private val RECEIVER_APPLICATION_ID_PATTERN = Regex("^[A-F0-9]{8}$")

    const val INVALID_RECEIVER_APPLICATION_ID_MESSAGE =
        "Receiver application ID must be an 8-character hexadecimal Google Cast receiver application ID."

    fun normalizeReceiverApplicationId(value: String?): String? {
        val normalized = value?.trim()?.uppercase(Locale.US)

        return if (!normalized.isNullOrEmpty() && RECEIVER_APPLICATION_ID_PATTERN.matches(normalized)) {
            normalized
        } else {
            null
        }
    }

    fun requireReceiverApplicationId(value: String?): String {
        return normalizeReceiverApplicationId(value)
            ?: throw IllegalArgumentException(INVALID_RECEIVER_APPLICATION_ID_MESSAGE)
    }

    fun getReceiverApplicationId(context: Context): String? {
        val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        return normalizeReceiverApplicationId(preferences.getString(RECEIVER_APPLICATION_ID_KEY, null))
    }

    fun setReceiverApplicationId(context: Context, receiverApplicationId: String) {
        val normalizedReceiverApplicationId = requireReceiverApplicationId(receiverApplicationId)
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(RECEIVER_APPLICATION_ID_KEY, normalizedReceiverApplicationId)
            .apply()
    }
}
