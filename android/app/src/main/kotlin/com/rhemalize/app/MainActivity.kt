package com.rhemalize.app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * MainActivity: configure edge-to-edge using WindowCompat and WindowInsetsControllerCompat.
 * This approach is compatible across Android 12..15 and avoids calling app-specific
 * extension helpers that may be unavailable due to activity base class differences.
 */
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Request that the window be laid out edge-to-edge. Flutter will receive
        // accurate insets via MediaQuery/Window padding so widgets using SafeArea
        // work properly.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Make system bars transparent so Flutter controls the appearance.
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        super.onCreate(savedInstanceState)

        // Configure light/dark appearances for system bar icons.
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = true
        controller.isAppearanceLightNavigationBars = true

        // For devices with gesture/navigation bar differences, ensure the
        // navigation bar divider color is transparent when supported.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                window.navigationBarDividerColor = Color.TRANSPARENT
            } catch (_: Throwable) {
                // Ignore if not supported on a particular OEM device.
            }
        }
    }
}
