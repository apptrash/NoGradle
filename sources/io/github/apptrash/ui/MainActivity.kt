package io.github.apptrash.ui

import android.os.Bundle
import android.app.Activity
import android.widget.TextView
import android.view.ViewGroup
import android.widget.FrameLayout
import android.view.View
import android.view.Gravity
import android.graphics.Color
import io.github.apptrash.R

class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
