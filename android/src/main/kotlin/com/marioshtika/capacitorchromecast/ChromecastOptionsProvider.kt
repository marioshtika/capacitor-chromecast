package com.marioshtika.capacitorchromecast

import android.content.Context
import com.google.android.gms.cast.framework.CastMediaOptions
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.NotificationOptions

class ChromecastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        val receiverApplicationId = ChromecastConfiguration.getReceiverApplicationId(context).orEmpty()
        val notificationOptions = NotificationOptions.Builder().build()
        val castMediaOptions = CastMediaOptions.Builder()
            .setNotificationOptions(notificationOptions)
            .build()

        return CastOptions.Builder()
            .setReceiverApplicationId(receiverApplicationId)
            .setResumeSavedSession(true)
            .setCastMediaOptions(castMediaOptions)
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): MutableList<SessionProvider>? = null
}
