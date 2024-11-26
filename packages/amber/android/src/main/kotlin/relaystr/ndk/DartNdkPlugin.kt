package relaystr.ndk

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import com.google.gson.Gson
import android.content.Context


import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry


class DartNdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var _channel : MethodChannel
    private lateinit var _context : Context
    private var _activity: Activity? = null
    private lateinit var _result: MethodChannel.Result

    private val _intentRequestCode = 0



    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ndk")
        _channel.setMethodCallHandler(this)
        _context = flutterPluginBinding.applicationContext
    }
    override fun onMethodCall(call: MethodCall, result: Result) {
        _result = result

        when (call.method) {
            "example" -> {
                Log.i("example", "example onMethodCall")
            }

            else -> {
                result.notImplemented()
                return
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        return false;
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        _channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        _activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        _activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        _activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        _activity = null
    }


}
