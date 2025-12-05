import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VocabEnhancementService {
  late final GenerativeModel _enhancementModel;

  VocabEnhancementService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw Exception('Chưa cấu hình API Key trong file .env');
    }

    _enhancementModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an English vocabulary expert that creates personalized example sentences. "
              "Generate natural, engaging examples based on user's interests. "
              "Return ONLY valid JSON:\n"
              "{\n"
              "  \"example\": \"An example sentence using the word\",\n"
              "  \"synonyms\": [\"synonym1\", \"synonym2\", \"synonym3\"]\n"
              "}"
      ),
    );
  }

  /// Tạo ví dụ và từ đồng nghĩa dựa trên sở thích người dùng
  Future<Map<String, dynamic>?> generateExampleAndSynonyms({
    required String word,
    required String definition,
    String userInterest = "football", // Mặc định là bóng đá
  }) async {
    try {
      final prompt = """
Generate an example sentence and synonyms for this word:
- Word: "$word"
- Definition: "$definition"
- User's interest: "$userInterest"

Create an example sentence that relates to $userInterest if possible, making it memorable and engaging.
Also provide 3-4 relevant synonyms or related words.

Return ONLY JSON format:
{
  "example": "Your example sentence here",
  "synonyms": ["syn1", "syn2", "syn3"]
}
""";

      final response = await _enhancementModel.generateContent([
        Content.text(prompt)
      ]);

      if (response.text == null) return null;

      final jsonText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonText);
    } catch (e) {
      print("Enhancement error: $e");
      return null;
    }
  }

  /// Stream version cho real-time updates (optional)
  Stream<String> generateExampleStream({
    required String word,
    required String definition,
    String userInterest = "football",
  }) async* {
    final prompt = """
Create an engaging example sentence for "$word" (meaning: $definition) related to $userInterest.
""";

    final response = _enhancementModel.generateContentStream([
      Content.text(prompt)
    ]);

    await for (final chunk in response) {
      if (chunk.text != null) yield chunk.text!;
    }
  }
}