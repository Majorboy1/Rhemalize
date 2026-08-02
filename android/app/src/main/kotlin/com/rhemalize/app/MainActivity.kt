package com.rhemalize.app

import android.os.Bundle
import androidx.core.view.WindowInsetsControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * MainActivity.
 *
 * Edge-to-edge is handled by Flutter (see lib/main.dart):
 *  - SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge) requests
 *    edge-to-edge drawing, which the engine applies on all API levels.
 *  - On Android 15+ (API 35) edge-to-edge is enforced by the OS by default.
 *
 * The legacy Window#setStatusBarColor / setNavigationBarColor /
 * setNavigationBarDividerColor and WindowCompat.setDecorFitsSystemWindows
 * calls are deprecated (and become no-ops on API 35+), so they are
 * intentionally NOT used here. Transparent bars come from the theme
 * (styles.xml) on API < 35, and from the OS on API 35+.
 *
 * We only configure the system-bar icon appearance with the modern,
 * non-deprecated WindowInsetsControllerCompat so the launch screen matches
 * the app's default light UI (dark icons). SystemChrome in Dart takes over
 * after the first frame.
 */
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = true
        controller.isAppearanceLightNavigationBars = true
    }
}
