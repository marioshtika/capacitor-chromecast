package com.marioshtika.capacitorchromecast

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChromecastConfigurationTest {
    @Test
    fun normalizesValidReceiverApplicationIds() {
        assertEquals("CC1AD845", ChromecastConfiguration.normalizeReceiverApplicationId(" cc1ad845 "))
    }

    @Test
    fun rejectsInvalidReceiverApplicationIds() {
        assertNull(ChromecastConfiguration.normalizeReceiverApplicationId("invalid"))
    }
}
