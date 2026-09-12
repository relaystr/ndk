package relaystr.ndk

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider

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
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.roundToInt


/// ndk_flutter native plugin.
///
/// Hosts the NIP-55 "Android Signer Application" bridge for external signer
/// apps. Communication happens either silently
/// through a ContentResolver query (when the user has pre-authorized the
/// permission) or, as a fallback, by launching the signer via an Intent and
/// reading the result in [onActivityResult].
class DartNdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var _channel : MethodChannel
    private lateinit var _updatesChannel : MethodChannel
    private lateinit var _context : Context
    private var _activity: Activity? = null

    private data class PendingIntentResult(
        val result: MethodChannel.Result,
        val id: String,
    )

    private val _pendingIntentResults = HashMap<Int, PendingIntentResult>()
    private val _pendingIntentRequestCodesById = HashMap<String, Int>()
    private var _nextIntentRequestCode = 1
    private val _updateLock = Any()
    private val _mainHandler = Handler(Looper.getMainLooper())
    private var _activeUpdate: UpdateDownload? = null

    private class UpdateDownload(
        val result: Result,
        val apk: File,
    ) {
        val cancelled = AtomicBoolean(false)
        val cancellationResults = mutableListOf<Result>()
        @Volatile var input: InputStream? = null
        @Volatile var connection: HttpURLConnection? = null
    }

    private companion object {
        const val MAX_APK_BYTES = 512L * 1024L * 1024L
        const val MAX_REDIRECTS = 5
    }


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ndk")
        _channel.setMethodCallHandler(this)
        _updatesChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "ndk/app_updates")
        _updatesChannel.setMethodCallHandler(::onUpdateMethodCall)
        _context = flutterPluginBinding.applicationContext
        pruneUpdateApks(File(_context.cacheDir, "ndk_updates"))
    }

    private fun onUpdateMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledSoftware" -> result.success(installedSoftware())
            "downloadAndInstall" -> downloadAndInstall(call, result)
            "cancelDownload" -> cancelUpdateDownload(result)
            else -> result.notImplemented()
        }
    }

    private fun installedSoftware(): HashMap<String, Any> {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            _context.packageManager.getPackageInfo(
                _context.packageName,
                android.content.pm.PackageManager.PackageInfoFlags.of(
                    android.content.pm.PackageManager.GET_SIGNING_CERTIFICATES.toLong()
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            _context.packageManager.getPackageInfo(
                _context.packageName,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    android.content.pm.PackageManager.GET_SIGNING_CERTIFICATES
                } else {
                    android.content.pm.PackageManager.GET_SIGNATURES
                },
            )
        }
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION") packageInfo.versionCode.toLong()
        }
        return hashMapOf(
            "packageId" to packageInfo.packageName,
            "version" to (packageInfo.versionName ?: ""),
            "versionCode" to versionCode,
            "platformVersion" to Build.VERSION.SDK_INT,
            "platforms" to Build.SUPPORTED_ABIS.mapNotNull(::androidPlatform),
            "certificateHashes" to certificateHashes(packageInfo),
        )
    }

    private fun androidPlatform(abi: String): String? = when (abi) {
        "arm64-v8a" -> "android-arm64-v8a"
        "armeabi-v7a" -> "android-armeabi-v7a"
        "x86" -> "android-x86"
        "x86_64" -> "android-x86_64"
        else -> null
    }

    private fun certificateHashes(packageInfo: android.content.pm.PackageInfo): List<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.signingInfo?.let { signingInfo ->
                if (signingInfo.hasMultipleSigners()) {
                    signingInfo.apkContentsSigners?.toList()
                } else {
                    signingInfo.signingCertificateHistory?.toList()
                        ?: signingInfo.apkContentsSigners?.toList()
                }
            } ?: emptyList()
        } else {
            @Suppress("DEPRECATION") packageInfo.signatures?.toList() ?: emptyList()
        }
        return signatures.map { signature ->
            MessageDigest.getInstance("SHA-256")
                .digest(signature.toByteArray())
                .joinToString("") { byte -> "%02x".format(byte) }
        }
    }

    private fun downloadAndInstall(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !_context.packageManager.canRequestPackageInstalls()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${_context.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            _context.startActivity(intent)
            result.success("permissionRequired")
            return
        }
        val url = call.argument<String>("url")
        val expectedHash = call.argument<String>("sha256")?.normalizedHash()
        val packageId = call.argument<String>("packageId")
        val versionCode = (call.argument<Number>("versionCode"))?.toLong()
        val expectedSize = (call.argument<Number>("size"))?.toLong()
        val declaredCertificates =
            (call.argument<List<String>>("certificateHashes") ?: emptyList())
                .map { it.normalizedHash() }
                .toSet()
        if (url == null || expectedHash == null || packageId == null || versionCode == null ||
            (expectedSize != null && expectedSize < 0)) {
            result.error("invalid_arguments", "Missing update asset metadata", null)
            return
        }

        val directory = File(_context.cacheDir, "ndk_updates").apply { mkdirs() }
        val operation = synchronized(_updateLock) {
            if (_activeUpdate != null) {
                result.error("update_in_progress", "An update download is already active", null)
                return
            }
            pruneUpdateApks(directory)
            UpdateDownload(
                result,
                File(directory, "update-${System.nanoTime()}.apk"),
            ).also { _activeUpdate = it }
        }

        Thread {
            try {
                val apk = operation.apk
                val connection = openUpdateConnection(url, operation)
                val total = connection.getHeaderField("Content-Length")?.toLongOrNull() ?: -1L
                val byteLimit = minOf(expectedSize ?: MAX_APK_BYTES, MAX_APK_BYTES)
                check(total < 0 || total <= byteLimit) { "APK exceeds download size limit" }
                val digest = MessageDigest.getInstance("SHA-256")
                connection.getInputStream().use { input ->
                    operation.input = input
                    FileOutputStream(apk).use { output ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        var downloaded = 0L
                        var lastProgressPercentage = -1
                        while (true) {
                            if (operation.cancelled.get()) break
                            val count = input.read(buffer)
                            if (count < 0) break
                            downloaded += count
                            check(downloaded <= byteLimit) {
                                "APK exceeds download size limit"
                            }
                            output.write(buffer, 0, count)
                            digest.update(buffer, 0, count)
                            if (total > 0) {
                                val percentage =
                                    ((downloaded.toDouble() / total) * 100)
                                        .roundToInt()
                                        .coerceAtMost(99)
                                if (percentage != lastProgressPercentage) {
                                    lastProgressPercentage = percentage
                                    emitProgress(percentage / 100.0)
                                }
                            }
                        }
                        if (operation.cancelled.get()) {
                            completeUpdate(operation, "cancelled")
                            return@Thread
                        }
                        check(expectedSize == null || downloaded == expectedSize) {
                            "Downloaded APK size mismatch"
                        }
                        if (total > 0) emitProgress(1.0)
                    }
                }
                operation.input = null
                val actualHash = digest.digest().joinToString("") { "%02x".format(it) }
                check(actualHash == expectedHash) { "Downloaded APK SHA-256 mismatch" }

                val flags = android.content.pm.PackageManager.GET_SIGNING_CERTIFICATES
                val archive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    _context.packageManager.getPackageArchiveInfo(
                        apk.path,
                        android.content.pm.PackageManager.PackageInfoFlags.of(flags.toLong()),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    _context.packageManager.getPackageArchiveInfo(apk.path, flags)
                } ?: error("Android could not parse downloaded APK")
                val archiveVersion = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    archive.longVersionCode
                } else {
                    @Suppress("DEPRECATION") archive.versionCode.toLong()
                }
                check(archive.packageName == packageId) { "APK package ID mismatch" }
                check(archiveVersion == versionCode) { "APK version code mismatch" }
                val archiveCertificates = certificateHashes(archive).map { it.normalizedHash() }.toSet()
                val installedCertificates = (installedSoftware()["certificateHashes"] as List<*>)
                    .filterIsInstance<String>().map { it.normalizedHash() }.toSet()
                check(archiveCertificates.intersect(declaredCertificates).isNotEmpty()) {
                    "APK certificate does not match NIP-82 asset"
                }
                check(archiveCertificates.intersect(installedCertificates).isNotEmpty()) {
                    "APK certificate is incompatible with installed app"
                }

                _mainHandler.post {
                    if (operation.cancelled.get()) {
                        completeUpdateOnMainThread(operation, "cancelled")
                        return@post
                    }
                    try {
                        val uri = FileProvider.getUriForFile(
                            _context,
                            "${_context.packageName}.ndk_updates",
                            apk,
                        )
                        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE, uri).apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                        }
                        _context.startActivity(intent)
                        completeUpdateOnMainThread(operation, "awaitingUserAction")
                    } catch (error: Throwable) {
                        completeUpdateOnMainThread(operation, error = error)
                    }
                }
            } catch (error: Throwable) {
                completeUpdate(
                    operation,
                    if (operation.cancelled.get()) "cancelled" else null,
                    if (operation.cancelled.get()) null else error,
                )
            } finally {
                operation.input = null
                operation.connection?.disconnect()
            }
        }.start()
    }

    private fun cancelUpdateDownload(result: Result) {
        val operation = synchronized(_updateLock) {
            _activeUpdate?.also { it.cancellationResults.add(result) }
        }
        if (operation == null) {
            result.success(null)
            return
        }
        operation.cancelled.set(true)
        runCatching { operation.input?.close() }
        operation.connection?.disconnect()
    }

    private fun openUpdateConnection(rawUrl: String, operation: UpdateDownload): HttpURLConnection {
        var current = URL(rawUrl)
        repeat(MAX_REDIRECTS + 1) { redirectCount ->
            validatePublicHttpsUrl(current)
            val connection = (current.openConnection() as HttpURLConnection).apply {
                instanceFollowRedirects = false
                connectTimeout = 15_000
                readTimeout = 30_000
                connect()
            }
            operation.connection = connection
            val status = connection.responseCode
            if (status !in 300..399) return connection
            val location = connection.getHeaderField("Location")
                ?: error("Update redirect has no Location header")
            connection.disconnect()
            check(redirectCount < MAX_REDIRECTS) { "Too many update redirects" }
            current = URL(current, location)
        }
        error("Too many update redirects")
    }

    private fun validatePublicHttpsUrl(url: URL) {
        check(url.protocol.equals("https", ignoreCase = true)) {
            "Update URL must use HTTPS"
        }
        check(url.userInfo == null && url.host.isNotBlank()) { "Invalid update URL" }
        val addresses = InetAddress.getAllByName(url.host)
        check(addresses.isNotEmpty() && addresses.none(::isNonPublicAddress)) {
            "Update URL must resolve to a public address"
        }
    }

    private fun isNonPublicAddress(address: InetAddress): Boolean =
        address.isAnyLocalAddress || address.isLoopbackAddress ||
            address.isLinkLocalAddress || address.isSiteLocalAddress ||
            address.isMulticastAddress

    private fun completeUpdate(
        operation: UpdateDownload,
        value: String? = null,
        error: Throwable? = null,
    ) = _mainHandler.post {
        completeUpdateOnMainThread(operation, value, error)
    }

    private fun completeUpdateOnMainThread(
        operation: UpdateDownload,
        value: String? = null,
        error: Throwable? = null,
    ) {
        val cancellationResults = synchronized(_updateLock) {
            if (_activeUpdate !== operation) return
            _activeUpdate = null
            operation.cancellationResults.toList()
        }
        val cancelled = operation.cancelled.get() || value == "cancelled"
        if (cancelled || error != null) operation.apk.delete()
        if (cancelled) {
            operation.result.success("cancelled")
        } else if (error == null) {
            operation.result.success(value)
        } else {
            operation.result.error("update_failed", error.message ?: error.toString(), null)
        }
        cancellationResults.forEach { it.success(null) }
    }

    private fun emitProgress(progress: Double) {
        _mainHandler.post {
            _updatesChannel.invokeMethod("progress", progress.coerceIn(0.0, 1.0))
        }
    }

    private fun String.normalizedHash(): String =
        lowercase().replace(Regex("[^0-9a-f]"), "")

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
                // Signer app package captured at login.
                // Empty for get_public_key / legacy accounts.
                val signerPackage = paramsMap[keyPackage] as? String ?: ""

                // First try the silent ContentResolver path (pre-authorized
                // permissions). Only attempt it when we know which signer to
                // query (a captured package): querying a foreign provider
                // returns wrong/empty data.
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
                if (requestType != "get_public_key") {
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
        _updatesChannel.setMethodCallHandler(null)
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
