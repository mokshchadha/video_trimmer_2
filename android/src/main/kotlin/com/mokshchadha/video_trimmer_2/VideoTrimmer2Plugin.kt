package com.mokshchadha.video_trimmer_2

import android.content.Context
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaCodec
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.UUID

/** VideoTrimmer2Plugin */
class VideoTrimmer2Plugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private val executor = Executors.newSingleThreadExecutor()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_trimmer_2")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "trimVideo" -> {
        val path = call.argument<String>("path")
        val startMs = call.argument<Int>("startMs")
        val endMs = call.argument<Int>("endMs")
        val rotation = call.argument<Int>("rotation") ?: -1

        if (path == null || startMs == null || endMs == null) {
          result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
          return
        }

        executor.execute {
          try {
            val outputPath = generateOutputPath()
            trimVideo(File(path), outputPath, startMs.toLong(), endMs.toLong(), rotation)

            // Return result on main thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.success(outputPath)
            }
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("TRIM_ERROR", e.message, e.stackTraceToString())
            }
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    executor.shutdown()
  }

  private fun generateOutputPath(): String {
    val outputDir = File(context.cacheDir, "trimmed_videos")
    if (!outputDir.exists()) {
      outputDir.mkdirs()
    }

    val uuid = UUID.randomUUID().toString()
    return File(outputDir, "trim_$uuid.mp4").absolutePath
  }

  private fun trimVideo(inputFile: File, outputPath: String, startTimeMs: Long, endTimeMs: Long, inputRotation: Int) {
    val extractor = MediaExtractor()
    val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

    try {
      extractor.setDataSource(inputFile.absolutePath)
      val trackCount = extractor.trackCount

      // Map to store track indices
      val indexMap = mutableMapOf<Int, Int>()

      // Set up tracks
      for (i in 0 until trackCount) {
        extractor.selectTrack(i)
        val format = extractor.getTrackFormat(i)
        val mime = format.getString(MediaFormat.KEY_MIME)

        // Add track to muxer
        val dstIndex = muxer.addTrack(format)
        indexMap[i] = dstIndex

        extractor.unselectTrack(i)
      }

      val rotation = if (inputRotation in listOf(0, 90, 180, 270)) {
        inputRotation
      } else {
        val retriever = android.media.MediaMetadataRetriever()
        retriever.setDataSource(inputFile.absolutePath)
        val rotationString = retriever.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
        retriever.release()
        rotationString?.toIntOrNull() ?: 0
      }

      muxer.setOrientationHint(rotation)

      // Start muxing
      muxer.start()

      val bufferSize = 1024 * 1024 // 1MB buffer
      val buffer = ByteBuffer.allocate(bufferSize)
      val bufferInfo = MediaCodec.BufferInfo()

      // Process each track
      for (i in 0 until trackCount) {
        extractor.selectTrack(i)

        // Seek to the start position
        extractor.seekTo(startTimeMs * 1000, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

        while (true) {
          val sampleSize = extractor.readSampleData(buffer, 0)

          if (sampleSize < 0) {
            // End of stream
            break
          }

          val sampleTime = extractor.sampleTime / 1000 // Convert to ms

          if (sampleTime > endTimeMs) {
            // Past the end time
            break
          }

          bufferInfo.size = sampleSize
          bufferInfo.offset = 0
          bufferInfo.flags = extractor.sampleFlags
          bufferInfo.presentationTimeUs = extractor.sampleTime - (startTimeMs * 1000)

          // Write sample to muxer
          muxer.writeSampleData(indexMap[i]!!, buffer, bufferInfo)

          extractor.advance()
        }

        extractor.unselectTrack(i)
      }

      // Finish up
      muxer.stop()
      muxer.release()
      extractor.release()

    } catch (e: IOException) {
      throw IOException("Failed to trim video: ${e.message}")
    }
  }
}
