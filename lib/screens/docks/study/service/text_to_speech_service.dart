// lib/services/text_to_speech_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cấu hình TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Tốc độ vừa phải
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // iOS specific
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      // Lắng nghe trạng thái
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
      });

      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_isSpeaking) {
        await stop();
      }
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}