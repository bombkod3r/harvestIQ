import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:dr_ai/utils/constant/api_url.dart';

class GenerativeAiWebService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''You are Dr. AI, a helpful and empathetic medical assistant.
Your role is to:
- Answer health and medical questions clearly and accurately
- Help users understand symptoms, conditions, and medications
- Recommend when users should seek professional medical care
- Never diagnose conditions definitively — always advise consulting a doctor
- Be concise, friendly, and reassuring
- Politely decline non-medical topics''';

  static Future<String?> postData({required String text}) async {
    try {
      log("🤖 Sending to Groq: ${ApiUrlManager.generativeModelVersion}");
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiUrlManager.generativeModelApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': ApiUrlManager.generativeModelVersion,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      log("✅ Response: $content");
      return content.trim();
    } on DioException catch (err) {
      log("❌ Groq API error: ${err.response?.data}");
      return "API Error: ${err.response?.data?['error']?['message'] ?? err.message}";
    } catch (err) {
      log("❌ Error: $err");
      return "Something went wrong. Please try again.";
    }
  }

  static Future<void> streamData({required String text}) async {
    // Streaming can be added later
    final result = await postData(text: text);
    log(result ?? '');
  }
}
