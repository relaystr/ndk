package relaystr.ndk

import android.app.Activity
import android.content.Intent
import android.net.Uri
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
import fr.acinq.secp256k1.Secp256k1

class DartNdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var _channel : MethodChannel
    private lateinit var _context : Context
    private var _activity: Activity? = null
    private lateinit var _result: MethodChannel.Result

    private val _intentRequestCode = 0

    private val secp256k1 = Secp256k1.get()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ndk")
        _channel.setMethodCallHandler(this)
        _context = flutterPluginBinding.applicationContext
    }
    override fun onMethodCall(call: MethodCall, result: Result) {
        _result = result

        when (call.method) {
            "verifySignature" -> {
                var sig = call.argument<ByteArray>("signature");
                var hash = call.argument<ByteArray>("hash");
                var pubKey = call.argument<ByteArray>("pubKey");

                _result.success(secp256k1.verifySchnorr(sig!!, hash!!, pubKey!!));
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

//
//    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
//        if (resultCode != Activity.RESULT_OK) {
//            _result.error("error","user rejected request","")
//            return false
//        }
//        return true
//    }
//
//
//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
//        if (requestCode == _intentRequestCode) {
//            if (resultCode == Activity.RESULT_OK && intent != null) {
//                if (intent.hasExtra("signature")) {
//                    val resultData = intent?.getStringExtra("signature")
//                    // Send the result back to Flutter
//                    _result.success(resultData)
//                    return true
//                }
//            }
//        }
//
//        return false
////        if (requestCode == REQUEST_CODE) {
////            if (resultCode == Activity.RESULT_OK) {
////                // Handle the result from the other app here
////                val resultData = data?.getStringExtra("signature")
////                // Send the result back to Flutter
////                myResult.success(resultData)
////            } else {
////                myResult.success(null)
////            }
////        }
//    }
}
