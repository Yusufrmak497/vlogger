import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  final bool isFullScreen;
  final Function(String) onVideoSaved;

  const CameraScreen({
    super.key,
    this.isFullScreen = false,
    required this.onVideoSaved,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni gerekli')),
        );
      }
      return;
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera başlatılamadı: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video kaydı başlatılamadı: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isInitialized) return;

    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      widget.onVideoSaved(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video kaydı durdurulamadı: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF6750A4),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 