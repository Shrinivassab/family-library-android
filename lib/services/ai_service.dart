import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class AIService {
  // Keys live in lib/config/api_keys.dart, which is gitignored — see
  // lib/config/api_keys.example.dart for the template. An APK's strings can
  // still be extracted by anyone, so for a real production release these
  // should move to a backend proxy rather than shipping in the client at all.
  static const String GOOGLE_API_KEY = ApiKeys.googleApiKey;
  static const String GROQ_API_KEY = ApiKeys.groqApiKey;

  // Primary: Gemma 4
  static Future<String> callGemma4(String prompt, {String? imageBase64}) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com'
        '/v1beta/models/gemma-2-27b-it:generateContent'
        '?key=$GOOGLE_API_KEY',
      );

      List<Map<String, dynamic>> parts = [];
      if (imageBase64 != null) {
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': imageBase64,
          }
        });
      }
      parts.add({'text': prompt});

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {'parts': parts}
              ],
              'generationConfig': {
                'maxOutputTokens': 2048,
                'temperature': 0.7,
              }
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      throw Exception('Gemma 4 failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Gemma 4 API Error: $e');
      // Fallback to Groq (its own errors are logged inside callGroq)
      return await callGroq(prompt, imageBase64: imageBase64);
    }
  }

  // Fallback: Groq
  static Future<String> callGroq(String prompt, {String? imageBase64}) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    String model = imageBase64 != null
        ? 'meta-llama/llama-4-scout-17b-16e-instruct'
        : 'llama-3.3-70b-versatile';

    List<Map<String, dynamic>> messageContent = [];
    if (imageBase64 != null) {
      messageContent.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$imageBase64',
        }
      });
    }
    messageContent.add({
      'type': 'text',
      'text': prompt,
    });

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $GROQ_API_KEY',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': messageContent}
              ],
              'max_tokens': 2048,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      throw Exception('Groq failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Groq API Error: $e');
      rethrow;
    }
  }

  // Convenience wrapper used by all tab screens.
  static Future<String> generateContent(String prompt, {String? imageBase64}) {
    return callGemma4(prompt, imageBase64: imageBase64);
  }
}
