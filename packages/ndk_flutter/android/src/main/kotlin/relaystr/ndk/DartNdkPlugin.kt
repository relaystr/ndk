package relaystr.ndk

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject


/// ndk_flutter native plugin.
///
/// Hosts the NIP-55 "Android Signer Application" bridge (external signer apps
/// such as Amber, Primal, Aegis, ...). Communication happens either silently
/// through a ContentResolver query (when the user has pre-authorized the
/// permission) or, as a fallback, by launching the signer via an Intent and
/// reading the result in [onActivityResult].
class DartNdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var _channel : MethodChannel
    private lateinit var _context : Context
    private var _activity: Activity? = null

    private data class PendingIntentResult(
        val result: MethodChannel.Result,
        val id: String,
    )

    private val _pendingIntentResults = HashMap<Int, PendingIntentResult>()
    private val _pendingIntentRequestCodesById = HashMap<String, Int>()
    private var _nextIntentRequestCode = 1


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ndk")
        _channel.setMethodCallHandler(this)
        _context = flutterPluginBinding.applicationContext
    }

    private fun isPackageInstalled(context: Context, target: String): Boolean {
        return context.packageManager.getInstalledApplications(0)
            .find { info -> info.packageName == target } != null
    }

    private fun isExternalSignerInstalled(context: Context): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$nostrSignerScheme:"))
        return context.packageManager.queryIntentActivities(intent, 0).isNotEmpty()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            nostrSignerScheme -> {
                val methodResult = MethodResultWrapper(result)

                val paramsMap = call.arguments as? HashMap<*, *>
                if (paramsMap == null) {
                    Log.d("onMethodCall", "paramsMap is null")
                    methodResult.success(HashMap<String, String?>())
                    return
                }

                val requestType = paramsMap[keyType] as? String ?: ""
                val currentUser = paramsMap[keyCurrentUser] as? String ?: ""
                val pubKey = paramsMap[keyPubKey] as? String
                    ?: paramsMap["pubkey"] as? String
                    ?: ""
                val id = paramsMap[keyId] as? String ?: ""
                val uriData = paramsMap[keyUriData] as? String ?: ""
                val permissions = paramsMap[keyPermissions] as? String ?: ""
                // Signer app package captured at login (Amber, Primal, ...).
                // Empty for get_public_key / legacy accounts.
                val signerPackage = paramsMap[keyPackage] as? String ?: ""

                // First try the silent ContentResolver path (pre-authorized
                // permissions). Only attempt it when we know which signer to
                // query (a captured package): querying a foreign provider
                // (e.g. Amber for a Primal account) returns wrong/empty data.
                // get_public_key (login) is Intent-only per NIP-55.
                if (requestType != "get_public_key" && signerPackage.isNotEmpty()) {
                    val data = getDataFromContentResolver(
                        requestType.uppercase(),
                        arrayOf(uriData, pubKey, currentUser),
                        _context.contentResolver,
                        signerPackage,
                    )
                    if (!data.isNullOrEmpty()) {
                        Log.d("onMethodCall", "content resolver got data")
                        methodResult.success(data)
                        return
                    }
                }

                // Fallback: launch the signer app via Intent.
                val intent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("$nostrSignerScheme:$uriData")
                )
                if (requestType == "sign_event") {
                    intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                intent.putExtra(keyType, requestType)
                intent.putExtra(keyCurrentUser, currentUser)
                intent.putExtra(keyPubKey, pubKey)
                intent.putExtra("pubkey", pubKey)
                intent.putExtra(keyId, id)
                intent.putExtra(keyPermissions, permissions)
                // Target the captured signer directly (no app chooser). Empty
                // for login, so the user can pick a signer the first time.
                if (signerPackage.isNotEmpty()) {
                    intent.setPackage(signerPackage)
                    intent.putExtra(keyPackage, signerPackage)
                }

                val activity = _activity
                if (activity == null) {
                    methodResult.success(HashMap<String, String?>())
                    return
                }

                var requestCode: Int? = null
                try {
                    requestCode = reserveIntentRequestCode(methodResult, id)
                    activity.startActivityForResult(intent, requestCode)
                } catch (e: Exception) {
                    Log.d("onMethodCall", "startActivityForResult failed for '$signerPackage': ${e.message}")
                    if (requestCode != null) {
                        removePendingIntentResult(requestCode)
                    }
                    methodResult.success(HashMap<String, String?>())
                }
            }

            "isAppInstalled" -> {
                val paramsMap = call.arguments as? HashMap<*, *>
                val packageName = paramsMap?.get("packageName") as? String
                val isInstalled = if (packageName.isNullOrEmpty()) {
                    isExternalSignerInstalled(_context)
                } else {
                    isPackageInstalled(_context, packageName)
                }
                result.success(isInstalled)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun reserveIntentRequestCode(result: MethodChannel.Result, id: String): Int {
        repeat(65535) {
            val requestCode = _nextIntentRequestCode
            _nextIntentRequestCode = if (_nextIntentRequestCode == 65535) {
                1
            } else {
                _nextIntentRequestCode + 1
            }
            if (!_pendingIntentResults.containsKey(requestCode)) {
                _pendingIntentResults[requestCode] = PendingIntentResult(result, id)
                if (id.isNotEmpty()) {
                    _pendingIntentRequestCodesById[id] = requestCode
                }
                return requestCode
            }
        }
        throw IllegalStateException("Too many pending NIP-55 signer intents")
    }

    private fun removePendingIntentResult(requestCode: Int): PendingIntentResult? {
        val pending = _pendingIntentResults.remove(requestCode)
        if (pending != null && pending.id.isNotEmpty()) {
            _pendingIntentRequestCodesById.remove(pending.id)
        }
        return pending
    }

    private fun completePendingIntentResult(requestCode: Int, data: HashMap<String, String?>): Boolean {
        val pending = removePendingIntentResult(requestCode) ?: return false
        pending.result.success(data)
        return true
    }

    private fun completePendingIntentResultById(id: String, data: HashMap<String, String?>): Boolean {
        val requestCode = _pendingIntentRequestCodesById[id] ?: return false
        val pending = removePendingIntentResult(requestCode) ?: return false
        pending.result.success(data)
        return true
    }

    private fun buildResultMapFromJson(resultJson: JSONObject): HashMap<String, String?> {
        val dataMap: HashMap<String, String?> = HashMap()
        if (resultJson.has(keyResult)) {
            val signerResult = resultJson.optString(keyResult, "")
            dataMap[keyResult] = signerResult
            dataMap[keySignature] = signerResult
        }
        if (resultJson.has(keySignature)) {
            dataMap[keySignature] = resultJson.optString(keySignature, "")
        }
        if (resultJson.has(keyPackage)) {
            dataMap[keyPackage] = resultJson.optString(keyPackage, "")
        }
        if (resultJson.has(keyId)) {
            dataMap[keyId] = resultJson.optString(keyId, "")
        }
        if (resultJson.has(keyEvent)) {
            dataMap[keyEvent] = resultJson.optString(keyEvent, "")
        }
        if (resultJson.has(keyRejected)) {
            dataMap[keyRejected] = resultJson.optString(keyRejected, "")
        }
        return dataMap
    }

    private fun buildResultMapFromIntent(intent: Intent): HashMap<String, String?> {
        val dataMap: HashMap<String, String?> = HashMap()
        if (intent.hasExtra(keyResult)) {
            val signerResult = intent.getStringExtra(keyResult)
            dataMap[keyResult] = signerResult
            // keep `signature` populated for backwards compatibility
            dataMap[keySignature] = signerResult
        }
        if (intent.hasExtra(keySignature)) {
            dataMap[keySignature] = intent.getStringExtra(keySignature)
        }
        if (intent.hasExtra(keyPackage)) {
            dataMap[keyPackage] = intent.getStringExtra(keyPackage)
        }
        if (intent.hasExtra(keyId)) {
            dataMap[keyId] = intent.getStringExtra(keyId)
        }
        if (intent.hasExtra(keyEvent)) {
            dataMap[keyEvent] = intent.getStringExtra(keyEvent)
        }
        if (intent.hasExtra(keyRejected)) {
            dataMap[keyRejected] = intent.getBooleanExtra(keyRejected, false).toString()
        }
        return dataMap
    }

    private fun completeBatchedResults(intent: Intent): Boolean {
        if (!intent.hasExtra(keyResults)) {
            return false
        }

        val resultsJson = intent.getStringExtra(keyResults) ?: return false
        return try {
            val results = JSONArray(resultsJson)
            var completedAny = false
            for (index in 0 until results.length()) {
                val item = results.optJSONObject(index) ?: continue
                val id = item.optString(keyId, "")
                if (id.isEmpty()) {
                    continue
                }
                val dataMap = buildResultMapFromJson(item)
                completedAny = completePendingIntentResultById(id, dataMap) || completedAny
            }
            completedAny
        } catch (e: Exception) {
            Log.d("onActivityResult", "failed to parse NIP-55 batched results: ${e.message}")
            false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        if (!_pendingIntentResults.containsKey(requestCode)) {
            return false
        }

        if (resultCode == Activity.RESULT_OK && intent != null) {
            if (completeBatchedResults(intent)) {
                if (_pendingIntentResults.containsKey(requestCode)) {
                    completePendingIntentResult(requestCode, HashMap())
                }
                return true
            }

            val dataMap = buildResultMapFromIntent(intent)
            val id = dataMap[keyId]
            if (!id.isNullOrEmpty() && completePendingIntentResultById(id, dataMap)) {
                return true
            }
            completePendingIntentResult(requestCode, dataMap)
            return true
        }

        completePendingIntentResult(requestCode, HashMap())
        return true
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

    /*
      Content resolver path adapted from:
      https://github.com/0xchat-app/nostr-dart/blob/main/android/src/main/kotlin/com/oxchat/nostrcore/ChatcorePlugin.kt
     */
    private fun getDataFromContentResolver(
        type: String,
        uriData: Array<out String>,
        resolver: ContentResolver,
        signerPackage: String,
    ): HashMap<String, String?>? {
        try {
            resolver.query(
                Uri.parse("content://${signerPackage}.$type"),
                uriData,
                null,
                null,
                null
            ).use {
                if (it == null) {
                    Log.d("getDataFromResolver", "resolver query is NULL")
                    return null
                }
                if (it.moveToFirst()) {
                    // The signer reports it cannot answer silently (permission
                    // not granted / user denied): fall back to the Intent so
                    // the user can approve, instead of returning empty data.
                    val rejectedIndex = it.getColumnIndex("rejected")
                    if (rejectedIndex >= 0) {
                        Log.d("getDataFromResolver", "request rejected -> fallback to intent")
                        return null
                    }

                    val dataMap: HashMap<String, String?> = HashMap()
                    val resultIndex = it.getColumnIndex("result")
                    if (resultIndex >= 0) {
                        val result = it.getString(resultIndex)
                        dataMap["result"] = result
                        dataMap["signature"] = result
                    }
                    val index = it.getColumnIndex("signature")
                    if (index >= 0) {
                        dataMap["signature"] = it.getString(index)
                    }
                    val indexJson = it.getColumnIndex("event")
                    if (indexJson >= 0) {
                        dataMap["event"] = it.getString(indexJson)
                    }

                    // Only short-circuit the Intent if we actually got a result;
                    // an empty/absent result means the signer didn't answer.
                    if (dataMap["signature"].isNullOrEmpty()) {
                        Log.d("getDataFromResolver", "empty result -> fallback to intent")
                        return null
                    }
                    return dataMap
                }
            }
        } catch (e: Exception) {
            Log.d("contentResolver", e.message ?: "unknown error")
            return null
        }
        return null
    }
}


private class MethodResultWrapper internal constructor(result: MethodChannel.Result) :
    MethodChannel.Result {
    private val methodResult: MethodChannel.Result = result
    private val handler: Handler = Handler(Looper.getMainLooper())

    override fun success(result: Any?) {
        handler.post { methodResult.success(result) }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        handler.post { methodResult.error(errorCode, errorMessage, errorDetails) }
    }

    override fun notImplemented() {
        handler.post { methodResult.notImplemented() }
    }
}
