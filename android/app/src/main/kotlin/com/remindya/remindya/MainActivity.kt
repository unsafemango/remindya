package com.remindya.remindya

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Launcher activity-aliases declared in AndroidManifest.xml, by icon name.
    private val iconAliases = mapOf(
        "happy" to "com.remindya.remindya.IconHappy",
        "sad" to "com.remindya.remindya.IconSad",
        "feral" to "com.remindya.remindya.IconFeral",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "remindya/app_icon")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val name = call.argument<String>("name")
                        if (name == null || name !in iconAliases) {
                            result.error("bad_icon", "Unknown icon: $name", null)
                        } else {
                            setIcon(name)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setIcon(name: String) {
        val pm = packageManager
        // Enable the new alias before disabling the others so there is always
        // a launcher entry.
        pm.setComponentEnabledSetting(
            ComponentName(this, iconAliases.getValue(name)),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for ((other, alias) in iconAliases) {
            if (other == name) continue
            pm.setComponentEnabledSetting(
                ComponentName(this, alias),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
