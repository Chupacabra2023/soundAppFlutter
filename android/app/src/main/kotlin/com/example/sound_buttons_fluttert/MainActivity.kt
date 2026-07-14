package com.example.sound_buttons_fluttert

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

private val WIRED_DEVICE_TYPES = setOf(
    AudioDeviceInfo.TYPE_WIRED_HEADSET,
    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
    AudioDeviceInfo.TYPE_LINE_ANALOG,
    AudioDeviceInfo.TYPE_LINE_DIGITAL,
    AudioDeviceInfo.TYPE_AUX_LINE,
    AudioDeviceInfo.TYPE_USB_HEADSET,
    AudioDeviceInfo.TYPE_USB_DEVICE,
    AudioDeviceInfo.TYPE_USB_ACCESSORY,
)

/**
 * Keeps the audio output DAC from powering down between button presses by
 * continuously writing silent (all-zero) PCM samples to a raw AudioTrack.
 * Some wired DACs power off between plays and pop/click when they wake up
 * for the next sound; an audio stream that never goes idle avoids that.
 * Writing actual zero samples (rather than just lowering a player's volume)
 * matters: volume is a software gain applied on top of the samples, so a
 * "quiet" track can still be silence-detected and let the DAC idle anyway.
 */
private class SilentAudioKeepAlive {
    private var audioTrack: AudioTrack? = null
    private var thread: Thread? = null

    @Volatile private var running = false

    fun start() {
        if (running) return
        running = true

        val sampleRate = 44100
        val minBuf = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                    .build(),
            )
            .setBufferSizeInBytes(minBuf)
            .build()
        audioTrack = track
        track.play()

        val silence = ByteArray(minBuf)
        thread = Thread {
            // write() blocks until the track has room, so this loop is
            // naturally paced by playback and doesn't spin the CPU.
            while (running) {
                track.write(silence, 0, silence.size)
            }
        }.apply { start() }
    }

    fun stop() {
        if (!running) return
        running = false
        thread?.join()
        thread = null
        audioTrack?.let {
            it.stop()
            it.release()
        }
        audioTrack = null
    }
}

class MainActivity : FlutterActivity() {
    private val channelName = "sk.marcelsotak.soundboard/export"
    private val audioRouteChannelName = "sk.marcelsotak.soundboard/audio_route"
    private val silentKeepAliveChannelName = "sk.marcelsotak.soundboard/silent_keepalive"
    private val createDocumentRequestCode = 4231
    private var pendingResult: MethodChannel.Result? = null

    private var audioDeviceCallback: AudioDeviceCallback? = null
    private val silentKeepAlive = SilentAudioKeepAlive()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, audioRouteChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

                    fun isWiredConnected(): Boolean =
                        audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                            .any { it.type in WIRED_DEVICE_TYPES }

                    events.success(isWiredConnected())

                    val callback = object : AudioDeviceCallback() {
                        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                            events.success(isWiredConnected())
                        }

                        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                            events.success(isWiredConnected())
                        }
                    }
                    audioDeviceCallback = callback
                    audioManager.registerAudioDeviceCallback(callback, null)
                }

                override fun onCancel(arguments: Any?) {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    audioDeviceCallback?.let { audioManager.unregisterAudioDeviceCallback(it) }
                    audioDeviceCallback = null
                }
            },
        )

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, silentKeepAliveChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    silentKeepAlive.start()
                    result.success(null)
                }
                "stop" -> {
                    silentKeepAlive.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        silentKeepAlive.stop()
        super.onDestroy()
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
