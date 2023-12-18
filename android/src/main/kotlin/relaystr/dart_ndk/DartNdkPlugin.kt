package relaystr.dart_ndk

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import com.google.gson.Gson

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
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var _channel: MethodChannel
    private var _activity: Activity? = null
    private lateinit var _result: MethodChannel.Result

    private val secp256k1 = Secp256k1.get()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dart_ndk")
        _channel.setMethodCallHandler(this)
    }

    fun verifySignature(
        call: MethodCall, result: MethodChannel.Result
    ) {
        var sig = call.argument<ByteArray>("signature");
        var hash = call.argument<ByteArray>("hash");
        var pubKey = call.argument<ByteArray>("pubKey");

        result.success(secp256k1.verifySchnorr(sig!!, hash!!, pubKey!!));
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        _result = result

        when (call.method) {
            "verifySignature" -> {
                verifySignature(call, result);
            }

            else -> {
                result.notImplemented()
                return
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (resultCode != Activity.RESULT_OK) {
            _result.error("error","user rejected request","")
            return false
        }
        return true
    }


//    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
//        super.onActivityResult(requestCode, resultCode, data)
//        if (requestCode == REQUEST_CODE) {
//            if (resultCode == Activity.RESULT_OK) {
//                // Handle the result from the other app here
//                val resultData = data?.getStringExtra("signature")
//                // Send the result back to Flutter
//                myResult.success(resultData)
//            } else {
//                myResult.success(null)
//            }
//        }
//    }

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
