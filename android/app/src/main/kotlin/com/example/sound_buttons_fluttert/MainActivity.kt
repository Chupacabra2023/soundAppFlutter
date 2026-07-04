package com.example.sound_buttons_fluttert

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "sk.marcelsotak.soundboard/export"
    private val createDocumentRequestCode = 4231
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "createDocument" -> {
                    val fileName = call.argument<String>("fileName") ?: "backup.zip"
                    val mimeType = call.argument<String>("mimeType") ?: "application/zip"
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mimeType
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    startActivityForResult(intent, createDocumentRequestCode)
                }
                "writeFile" -> {
                    val uriString = call.argument<String>("uri")
                    val sourcePath = call.argument<String>("sourcePath")
                    if (uriString == null || sourcePath == null) {
                        result.error("invalid_args", "uri and sourcePath are required", null)
                        return@setMethodCallHandler
                    }
                    // Stream the already-built file to the SAF Uri on a background
                    // thread so a large export never blocks the UI thread.
                    Thread {
                        try {
                            val uri = Uri.parse(uriString)
                            val output = contentResolver.openOutputStream(uri)
                                ?: throw IllegalStateException("Could not open output stream")
                            output.use { out ->
                                File(sourcePath).inputStream().use { input ->
                                    input.copyTo(out, bufferSize = 262144)
                                }
                            }
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("write_failed", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == createDocumentRequestCode) {
            val result = pendingResult
            pendingResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                result?.success(data.data.toString())
            } else {
                result?.success(null)
            }
        }
    }
}
