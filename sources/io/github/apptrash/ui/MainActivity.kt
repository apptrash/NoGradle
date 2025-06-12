package io.github.apptrash.ui

import android.os.Bundle
import android.app.Activity
import io.github.apptrash.R

class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
