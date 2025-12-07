import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiChatService {
  late final GenerativeModel _textModel;
  late final GenerativeModel _imageModel;
  late final GenerativeModel _vocabModel;
  late final GenerativeModel _intentModel;

  GeminiChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw Exception('Chưa cấu hình API Key trong file .env');
    }

    // =========================
    // MODEL CHAT
    // =========================
    _textModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are a friendly English tutor. Answer questions naturally, "
              "politely, and concisely. Keep responses helpful and easy to read."
      ),
    );

    // =========================
    // MODEL NHẬN DIỆN ẢNH
    // =========================
    _imageModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an expert at identifying objects in images. "
              "Analyze the image and return ONLY a valid JSON object:\n"
              "{\n"
              "  \"word\": \"English word for the object\",\n"
              "  \"definition\": \"Vietnamese translation and explanation\",\n"
              "  \"type\": \"noun/verb/adjective\",\n"
              "  \"pronunciation\": \"/pronunciation/\",\n"
              "  \"part_of_speech\": \"noun/verb/adjective/etc\",\n"
              "  \"related\": [\"related_word1\", \"related_word2\", \"related_word3\"],\n"
              "  \"synonyms\": [\"synonym1\", \"synonym2\"],\n"
              "  \"example_en\": \"English example sentence\",\n"
              "  \"example_vi\": \"Vietnamese translation of example\",\n"
              "  \"confidence\": 0.95\n"
              "}"
      ),
    );

    // =========================
    // MODEL PHÂN TÍCH TỪ VỰNG
    // =========================
    _vocabModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an English-Vietnamese vocabulary expert.\n\n"
              "IMPORTANT RULES:\n"
              "1. Detect if the user asks in Vietnamese or English\n"
              "2. If Vietnamese query → return English word with Vietnamese definition\n"
              "3. If English query → return Vietnamese word with English definition\n\n"
              "Return ONLY valid JSON with this structure:\n"
              "{\n"
              "  \"word\": \"the main word (English if user asks in Vietnamese, Vietnamese if user asks in English)\",\n"
              "  \"definition\": \"is the keyword that users ask\",\n"
              "  \"type\": \"noun/verb/adjective/adverb/etc\",\n"
              "  \"pronunciation\": \"/IPA pronunciation/ (for English words only)\",\n"
              "  \"part_of_speech\": \"noun/verb/adjective/etc\",\n"
              "  \"related\": [\"related_word1\", \"related_word2\", \"related_word3\"],\n"
              "  \"synonyms\": [\"synonym1\", \"synonym2\", \"synonym3\"],\n"
              "  \"example_en\": \"Example sentence in English\",\n"
              "  \"example_vi\": \"Vietnamese translation of the example\",\n"
              "  \"confidence\": 0.98\n"
              "}\n\n"
              "Examples:\n"
              "User: 'con mèo là gì trong tiếng Anh?' → word: 'cat', definition: 'Con mèo'\n"
              "User: 'what is beautiful in Vietnamese?' → word: 'đẹp', definition: 'Beautiful'\n"

      ),
    );


    _intentModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "Classify the user's message into EXACTLY one label: "
              "\"vocab_query\" OR \"normal_chat\".\n"
              "Return ONLY JSON:\n"
              "{\"label\": \"vocab_query\"}\n"
              "OR\n"
              "{\"label\": \"normal_chat\"}\n\n"
              "A vocab_query means the user is asking for definition, meaning, "
              "explanation, synonyms, usage, translation, or vocabulary info of a word/phrase "
              "(in English or Vietnamese) — even if misspelled."
      ),
    );
  }

  // --------------------------------------------------
  // HÀM PHÂN LOẠI Ý ĐỊNH
  // --------------------------------------------------
  Future<bool> _isVocabIntent(String message) async {
    try {
      final resp = await _intentModel.generateContent([
        Content.text(message)
      ]);

      if (resp.text == null) return false;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = jsonDecode(jsonText);
      return result['label'] == 'vocab_query';
    } catch (e) {
      print("Intent classification error: $e");
      return false;
    }
  }

  // API PUBLIC
  Future<bool> shouldReturnVocabCard(String message) async {
    return await _isVocabIntent(message);
  }

  // --------------------------------------------------
  // CHAT STREAM
  // --------------------------------------------------
  Stream<String> sendTextStream(String message) async* {
    final response = _textModel.generateContentStream([
      Content.text(message),
    ]);

    await for (final chunk in response) {
      if (chunk.text != null) yield chunk.text!;
    }
  }

  // --------------------------------------------------
  // PHÂN TÍCH TỪ VỰNG
  // --------------------------------------------------
  Future<Map<String, dynamic>?> analyzeVocabulary(String message) async {
    try {
      final resp = await _vocabModel.generateContent([
        Content.text(message)
      ]);

      if (resp.text == null) return null;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonText);
    } catch (e) {
      print("Vocab error: $e");
      return null;
    }
  }

  // --------------------------------------------------
  // NHẬN DIỆN ẢNH
  // --------------------------------------------------
  Future<Map<String, dynamic>?> analyzeImage(File image, String prompt) async {
    try {
      final bytes = await image.readAsBytes();

      final finalPrompt = prompt.isEmpty
          ? "Identify the main object in this image and provide vocabulary information."
          : "Identify: $prompt";

      final resp = await _imageModel.generateContent([
        Content.multi([
          TextPart(finalPrompt),
          DataPart("image/jpeg", bytes),
        ])
      ]);

      if (resp.text == null) return null;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonText);
    } catch (e) {
      print("Image error: $e");
      return null;
    }
  }
}