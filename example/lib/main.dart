import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer_2/video_trimmer_2.dart';
import 'package:video_player/video_player.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  File? _trimmedVideoFile;
  VideoPlayerController? _controller;
  bool _isProcessing = false;
  bool _isSaving = false;
  final Trimmer _trimmer = Trimmer();

  // Values for trim start and end points
  double _startValue = 0.0;
  double _endValue = 0.0;
  double _videoDuration = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _getPlatformVersion();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();
    }
  }

  Future<void> _getPlatformVersion() async {
    try {
      final version = await _trimmer.getPlatformVersion();
      print('Running on platform: $version');
    } catch (e) {
      print('Error getting platform version: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedVideo =
          await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedVideo != null) {
        final File videoFile = File(pickedVideo.path);

        setState(() {
          _videoFile = videoFile;
          _trimmedVideoFile = null;
        });

        _initializeVideoPlayer();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoFile != null) {
      try {
        _controller = VideoPlayerController.file(_videoFile!);
        await _controller!.initialize();
        await _controller!.play();

        setState(() {
          _videoDuration =
              _controller!.value.duration.inMilliseconds.toDouble();
          _startValue = 0;
          _endValue = _videoDuration;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video: $e')),
        );
      }
    }
  }

  Future<void> _trimVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File trimmedFile = await _trimmer.trimVideo(
        file: _videoFile!,
        startMs: _startValue.toInt(),
        endMs: _endValue.toInt(),
      );

      setState(() {
        _trimmedVideoFile = trimmedFile;
        _isProcessing = false;
      });

      // Play the trimmed video
      _controller?.dispose();
      _controller = VideoPlayerController.file(_trimmedVideoFile!);
      await _controller!.initialize();
      await _controller!.play();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video trimmed successfully')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      print('Error trimming video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error trimming video: $e')),
      );
    }
  }

  Future<void> _saveVideoToGallery() async {
    if (_trimmedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trimmed video to save')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Correct implementation of saver_gallery for videos
      final fileName =
          'trimmed_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final result = await SaverGallery.saveFile(
        filePath: _trimmedVideoFile!.path,
        fileName: fileName,
        androidRelativePath: "Movies",
        skipIfExists: false,
      );

      setState(() {
        _isSaving = false;
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video saved to gallery successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save video to gallery: ${result.errorMessage}')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      print('Error saving video to gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video to gallery: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Trimmer Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No video selected'),
                ),
              ),

            // Video player controls
            if (_controller != null && _controller!.value.isInitialized)
              IconButton(
                icon: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
              ),

            // Trim controls
            if (_videoFile != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Slider for trim start and end
                    RangeSlider(
                      values: RangeValues(_startValue, _endValue),
                      min: 0,
                      max: _videoDuration,
                      divisions: 100, // Add divisions for more precise control
                      onChanged: (RangeValues values) {
                        setState(() {
                          _startValue = values.start;
                          _endValue = values.end;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Start: ${(_startValue / 1000).toStringAsFixed(1)}s'),
                        Text('End: ${(_endValue / 1000).toStringAsFixed(1)}s'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _trimVideo,
                      child: _isProcessing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Processing...'),
                              ],
                            )
                          : const Text('Trim Video'),
                    ),
                  ],
                ),
              ),

            // Trimmed video info and save button
            if (_trimmedVideoFile != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trimmed Video:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _trimmedVideoFile!.path,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveVideoToGallery,
                      icon: const Icon(Icons.save_alt),
                      label: _isSaving
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : const Text('Save to Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickVideo,
        tooltip: 'Pick Video',
        child: const Icon(Icons.video_library),
      ),
    );
  }
}
