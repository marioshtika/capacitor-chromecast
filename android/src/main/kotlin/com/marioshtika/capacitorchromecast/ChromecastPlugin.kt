package com.marioshtika.capacitorchromecast

import android.content.Context
import android.view.ContextThemeWrapper
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import androidx.mediarouter.app.MediaRouteButton
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.PluginMethod
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener

@CapacitorPlugin(name = "Chromecast")
class ChromecastPlugin : Plugin() {
    companion object {
        private const val EVENT_SESSION_STATE_CHANGED = "sessionStateChanged"
        private const val NOT_INITIALIZED_MESSAGE =
            "Google Cast has not been initialized. Call Chromecast.initialize(...) or configure plugins.Chromecast.receiverApplicationId in capacitor.config.*."
        private const val INITIALIZED_WITH_DIFFERENT_RECEIVER_MESSAGE =
            "Google Cast is already initialized with a different receiver application ID. Restart the app before changing it."
        private const val CAST_NOT_AVAILABLE_MESSAGE =
            "The native Google Cast device picker is not currently available."
    }

    private var activeReceiverApplicationId: String? = null
    private var castContext: CastContext? = null
    private var sessionManagerListener: SessionManagerListener<CastSession>? = null

    override fun load() {
        super.load()

        activity?.runOnUiThread {
            runCatching {
                resolveConfiguredReceiverApplicationId()?.let { receiverApplicationId ->
                    val pluginContext = pluginContext() ?: return@let
                    ChromecastConfiguration.setReceiverApplicationId(pluginContext, receiverApplicationId)
                    initializeCastContextIfNeeded(receiverApplicationId)
                }
            }
        }
    }

    @PluginMethod
    fun initialize(call: PluginCall) {
        val receiverApplicationId = try {
            ChromecastConfiguration.requireReceiverApplicationId(call.getString("receiverApplicationId"))
        } catch (exception: IllegalArgumentException) {
            call.reject(exception.message, "INVALID_RECEIVER_APPLICATION_ID")
            return
        }

        val activity = activity
        if (activity == null) {
            call.reject(CAST_NOT_AVAILABLE_MESSAGE, "CAST_NOT_AVAILABLE")
            return
        }

        activity.runOnUiThread {
            try {
                initializeCastContextIfNeeded(receiverApplicationId)
                call.resolve()
            } catch (exception: IllegalArgumentException) {
                call.reject(exception.message, "INVALID_RECEIVER_APPLICATION_ID")
            } catch (exception: IllegalStateException) {
                call.reject(exception.message, "CAST_CONNECTION_FAILED")
            } catch (exception: Exception) {
                call.reject("Failed to initialize Google Cast.", "CAST_CONNECTION_FAILED", exception)
            }
        }
    }

    @PluginMethod
    fun show(call: PluginCall) {
        val activity = activity
        if (activity == null) {
            call.reject(CAST_NOT_AVAILABLE_MESSAGE, "CAST_NOT_AVAILABLE")
            return
        }

        activity.runOnUiThread {
            try {
                val receiverApplicationId = resolveReceiverApplicationIdForUse()
                initializeCastContextIfNeeded(receiverApplicationId)
                showNativeDevicePicker(call)
            } catch (exception: IllegalArgumentException) {
                call.reject(exception.message, "INVALID_RECEIVER_APPLICATION_ID")
            } catch (exception: IllegalStateException) {
                val code = if (exception.message == NOT_INITIALIZED_MESSAGE) {
                    "NOT_INITIALIZED"
                } else {
                    "CAST_CONNECTION_FAILED"
                }
                call.reject(exception.message, code)
            } catch (exception: Exception) {
                call.reject("Failed to open the Google Cast device picker.", "CAST_NOT_AVAILABLE", exception)
            }
        }
    }

    override fun handleOnDestroy() {
        detachSessionManagerListener()
        super.handleOnDestroy()
    }

    private fun showNativeDevicePicker(call: PluginCall) {
        val fragmentActivity = activity as? FragmentActivity
        if (fragmentActivity == null) {
            call.reject(CAST_NOT_AVAILABLE_MESSAGE, "CAST_NOT_AVAILABLE")
            return
        }

        val rootView = fragmentActivity.findViewById<ViewGroup>(android.R.id.content)
        if (rootView == null) {
            call.reject(CAST_NOT_AVAILABLE_MESSAGE, "CAST_NOT_AVAILABLE")
            return
        }

        val themedContext = ContextThemeWrapper(fragmentActivity, androidx.mediarouter.R.style.Theme_MediaRouter)
        val mediaRouteButton = MediaRouteButton(themedContext).apply {
            alpha = 0f
            visibility = View.INVISIBLE
        }

        CastButtonFactory.setUpMediaRouteButton(fragmentActivity, mediaRouteButton)
        rootView.addView(mediaRouteButton, FrameLayout.LayoutParams(1, 1))

        mediaRouteButton.post {
            try {
                mediaRouteButton.performClick()
                call.resolve()
            } catch (exception: Exception) {
                call.reject(CAST_NOT_AVAILABLE_MESSAGE, "CAST_NOT_AVAILABLE", exception)
            } finally {
                rootView.removeView(mediaRouteButton)
            }
        }
    }

    private fun initializeCastContextIfNeeded(receiverApplicationId: String): CastContext {
        val pluginContext = pluginContext() ?: throw IllegalStateException(CAST_NOT_AVAILABLE_MESSAGE)
        val normalizedReceiverApplicationId = ChromecastConfiguration.requireReceiverApplicationId(receiverApplicationId)

        activeReceiverApplicationId?.let {
            if (it != normalizedReceiverApplicationId) {
                throw IllegalStateException(INITIALIZED_WITH_DIFFERENT_RECEIVER_MESSAGE)
            }
        }

        ChromecastConfiguration.setReceiverApplicationId(pluginContext, normalizedReceiverApplicationId)

        if (castContext == null) {
            castContext = CastContext.getSharedInstance(activity ?: pluginContext)
            activeReceiverApplicationId = normalizedReceiverApplicationId
        }

        attachSessionManagerListener(castContext ?: throw IllegalStateException(CAST_NOT_AVAILABLE_MESSAGE))
        return castContext ?: throw IllegalStateException(CAST_NOT_AVAILABLE_MESSAGE)
    }

    private fun resolveReceiverApplicationIdForUse(): String {
        val pluginContext = pluginContext() ?: throw IllegalStateException(CAST_NOT_AVAILABLE_MESSAGE)

        ChromecastConfiguration.getReceiverApplicationId(pluginContext)?.let { return it }

        val configuredReceiverApplicationId = resolveConfiguredReceiverApplicationId()
            ?: throw IllegalStateException(NOT_INITIALIZED_MESSAGE)

        ChromecastConfiguration.setReceiverApplicationId(pluginContext, configuredReceiverApplicationId)
        return configuredReceiverApplicationId
    }

    private fun resolveConfiguredReceiverApplicationId(): String? {
        val rawReceiverApplicationId = bridge?.config
            ?.getPluginConfiguration("Chromecast")
            ?.getString("receiverApplicationId")
            ?.takeIf { it.isNotBlank() }
            ?: return null

        return ChromecastConfiguration.requireReceiverApplicationId(rawReceiverApplicationId)
    }

    private fun attachSessionManagerListener(castContext: CastContext) {
        if (sessionManagerListener != null) {
            return
        }

        val listener = object : SessionManagerListener<CastSession> {
            override fun onSessionStarting(session: CastSession) {
                notifySessionStateChanged("connecting")
            }

            override fun onSessionStarted(session: CastSession, sessionId: String) {
                notifySessionStateChanged("connected")
            }

            override fun onSessionStartFailed(session: CastSession, error: Int) {
                notifySessionStateChanged("disconnected")
            }

            override fun onSessionResuming(session: CastSession, sessionId: String) {
                notifySessionStateChanged("connecting")
            }

            override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
                notifySessionStateChanged("connected")
            }

            override fun onSessionResumeFailed(session: CastSession, error: Int) {
                notifySessionStateChanged("disconnected")
            }

            override fun onSessionSuspended(session: CastSession, reason: Int) {
                notifySessionStateChanged("disconnected")
            }

            override fun onSessionEnding(session: CastSession) = Unit

            override fun onSessionEnded(session: CastSession, error: Int) {
                notifySessionStateChanged("disconnected")
            }
        }
        sessionManagerListener = listener

        castContext.sessionManager.addSessionManagerListener(
            listener,
            CastSession::class.java,
        )
    }

    private fun detachSessionManagerListener() {
        val existingCastContext = castContext ?: return
        val listener = sessionManagerListener ?: return

        existingCastContext.sessionManager.removeSessionManagerListener(listener, CastSession::class.java)
        sessionManagerListener = null
    }

    private fun notifySessionStateChanged(state: String) {
        val payload = JSObject().apply {
            put("state", state)
        }
        notifyListeners(EVENT_SESSION_STATE_CHANGED, payload)
    }

    private fun pluginContext(): Context? = context ?: activity?.applicationContext
}
