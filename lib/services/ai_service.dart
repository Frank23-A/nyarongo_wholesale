import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nyarongo_wholesale/utils/openai_config.dart';

class AiService {
  static const _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-3.5-turbo';

  final String apiKey;

  const AiService({this.apiKey = openAiApiKey});

  Future<String> ask(String question) async {
    final key = apiKey.trim();
    if (key.isEmpty || key.startsWith('<')) {
      throw AiServiceException(
        'OpenAI API key is missing. Set OPENAI_API_KEY with a valid key.',
      );
    }

    final response = await http.post(
      Uri.parse(_openAiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode(
        {
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful wholesale store assistant. Answer clearly and concisely about products, pricing, availability, orders, deliveries, and support.',
            },
            {
              'role': 'user',
              'content': question,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        },
      ),
    );

    if (response.statusCode != 200) {
      String message = 'OpenAI request failed with status ${response.statusCode}.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('error')) {
          final error = body['error'];
          if (error is Map<String, dynamic> && error.containsKey('message')) {
            message = error['message'] as String;
          }
        }
      } catch (_) {
        // Ignore parse errors.
      }
      throw AiServiceException(message);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AiServiceException('OpenAI response did not include any choices.');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw AiServiceException('OpenAI returned an empty assistant response.');
    }

    return content.trim();
  }
}

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => 'AiServiceException: $message';
}
