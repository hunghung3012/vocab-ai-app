import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocab_ai/models/chat_message.dart';
import 'package:vocab_ai/models/vocab_model.dart';
import 'package:vocab_ai/screens/chat_ai/service/chat_service.dart';

// Import các Widgets đã tách
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_area.dart';
import 'widgets/image_source_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<ChatMessage> _messages = [];

  late GeminiChatService _chatService;

  File? _pendingImage;
  bool _isLoading = false;
  String _textBuffer = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatService = GeminiChatService();

    _messages.add(ChatMessage(
      text: "👋 Hello! I'm your AI English Tutor.\n\n"
          "📸 Send me a photo to identify objects\n"
          "💬 Ask about any English word or phrase\n"
          "✨ Let's learn together!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceSheet(
        onCameraTap: () => _pickImage(ImageSource.camera),
        onGalleryTap: () => _pickImage(ImageSource.gallery),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pendingImage = File(picked.path);
      });
    }
  }

  // ... (Giữ nguyên logic _startTypingTimer, _handleSend, _handleImageAnalysis,
  //      _handleVocabQuery, _streamTextResponse từ code cũ của bạn) ...

  // Mình paste lại các hàm logic này để đảm bảo file chạy được ngay:
  void _startTypingTimer(int messageIndex) {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_textBuffer.isEmpty && !_isLoading) {
        timer.cancel();
        return;
      }
      if (_textBuffer.isNotEmpty) {
        setState(() {
          final char = _textBuffer[0];
          _textBuffer = _textBuffer.substring(1);
          final oldMsg = _messages[messageIndex];
          _messages[messageIndex] = ChatMessage(
            text: oldMsg.text + char,
            isUser: false,
            timestamp: oldMsg.timestamp,
            vocabResult: oldMsg.vocabResult,
          );
        });
        _scrollDown();
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final image = _pendingImage;

    if ((text.isEmpty && image == null) || _isLoading) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      image: image,
    ));

    _controller.clear();
    setState(() => _pendingImage = null);
    _scrollDown();

    setState(() => _isLoading = true);

    if (image != null) {
      await _handleImageAnalysis(image, text);
    } else {
      final isVocabQuery = await _chatService.shouldReturnVocabCard(text);
      if (isVocabQuery) {
        await _handleVocabQuery(text);
      } else {
        await _streamTextResponse(text);
      }
    }
  }

  Future<void> _handleImageAnalysis(File image, String prompt) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(isUser: false, timestamp: DateTime.now(), text: "🔍 Analyzing image..."));

    try {
      final result = await _chatService.analyzeImage(image, prompt);
      if (result != null) {
        final vocabResult = VocabResult.fromJson(result);
        setState(() {
          _isLoading = false;
          _messages[botIndex] = ChatMessage(
            isUser: false,
            timestamp: DateTime.now(),
            vocabResult: vocabResult,
            image: image,
            text: "",
          );
        });
      } else {
        throw Exception("Could not analyze");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages[botIndex] = ChatMessage(
          text: "❌ Sorry, I couldn't analyze this image.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
    _scrollDown();
  }

  Future<void> _handleVocabQuery(String query) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(isUser: false, timestamp: DateTime.now(), text: "📖 Analyzing vocabulary..."));

    try {
      final result = await _chatService.analyzeVocabulary(query);
      if (result != null) {
        final vocabResult = VocabResult.fromJson(result);
        setState(() {
          _isLoading = false;
          _messages[botIndex] = ChatMessage(
            isUser: false,
            timestamp: DateTime.now(),
            vocabResult: vocabResult,
            text: "",
          );
        });
      } else {
        throw Exception("Could not analyze");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages[botIndex] = ChatMessage(
          text: "❌ Sorry, I couldn't analyze that word.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
    _scrollDown();
  }

  Future<void> _streamTextResponse(String userPrompt) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(text: "", isUser: false, timestamp: DateTime.now()));
    _textBuffer = '';
    _startTypingTimer(botIndex);

    try {
      final stream = _chatService.sendTextStream(userPrompt);
      await for (final part in stream) {
        _textBuffer += part;
      }
    } catch (e) {
      _textBuffer = '';
      setState(() {
        _messages[botIndex] = ChatMessage(
          text: "❌ Error: Unable to get response.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAddToVocab(VocabResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text("✅ '${result.word}' added to deck!")),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text("AI Tutor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {
              // Dialog hướng dẫn đơn giản, để ở đây cũng được hoặc tách file nếu muốn
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(children: [Icon(Icons.help_outline, color: Color(0xFF6F47EB)), SizedBox(width: 8), Text("How to use")]),
                  content: const Text("📸 Send photos\n💬 Ask about words\n💡 Chat normally"),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (_, i) => ChatBubble(
                message: _messages[i],
                onAddToVocab: () => _messages[i].vocabResult != null
                    ? _handleAddToVocab(_messages[i].vocabResult!)
                    : null,
              ),
            ),
          ),
          ChatInputArea(
            controller: _controller,
            isLoading: _isLoading,
            pendingImage: _pendingImage,
            onSend: _handleSend,
            onCameraTap: _showImageSourceDialog,
            onRemoveImage: () => setState(() => _pendingImage = null),
          ),
        ],
      ),
    );
  }
}