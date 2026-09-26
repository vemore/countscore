package com.vemore.countscore

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // An activity restored after process death (reopened from the recents screen) gets
        // its original launch intent back, without FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY, so
        // app_links would deliver a countscore://join link the user already answered. A
        // restored activity has handled its launch link: drop it before the plugins attach.
        if (savedInstanceState != null && intent?.data != null) {
            intent = intent.setData(null)
        }
        super.onCreate(savedInstanceState)
    }
}
