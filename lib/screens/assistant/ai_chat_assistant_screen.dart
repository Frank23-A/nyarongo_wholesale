import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/models/product_model.dart';
import 'package:nyarongo_wholesale/services/ai_service.dart';
import 'package:nyarongo_wholesale/services/product_service.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

class AiChatAssistantScreen extends StatefulWidget {
  final String roleLabel;

  const AiChatAssistantScreen({
    super.key,
    required this.roleLabel,
  });

  @override
  State<AiChatAssistantScreen> createState() => _AiChatAssistantScreenState();
}

class _AiChatAssistantScreenState extends State<AiChatAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ProductService _productService = const ProductService();
  final AiService _aiService = const AiService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      sender: 'assistant',
      text: 'Hello! I am your Nyarongo AI assistant. Ask me about products, orders, deliveries, or support.',
    ),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  FoLogo(size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Smart Q&A and help for the ${widget.roleLabel.toLowerCase()} flow.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isAssistant = message.sender == 'assistant';

                  return Align(
                    alignment: isAssistant
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: isAssistant
                            ? Colors.white
                            : AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isAssistant ? AppConstants.textPrimaryColor : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about products, orders, or support',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(sender: 'user', text: question));
      _isLoading = true;
    });

    try {
      final response = await _aiService.ask(question);
      setState(() {
        _messages.add(_ChatMessage(sender: 'assistant', text: response));
      });
    } catch (error) {
      final errorText = error is AiServiceException
          ? error.message
          : 'Unexpected error contacting the AI assistant.';
      final isQuotaError = errorText.toLowerCase().contains('quota') ||
          errorText.toLowerCase().contains('billing');
      final fallback =
          isQuotaError ? null : await _getAssistantResponse(question);

      setState(() {
        _messages.add(
          _ChatMessage(
            sender: 'assistant',
            text: isQuotaError
                ? 'OpenAI request failed because your API key has no available quota or billing is disabled. Please check your OpenAI plan, update billing, or use a different key.\n\nError: $errorText'
                : 'Sorry, I could not complete the AI request: $errorText\n\nHere is a local response instead:\n$fallback',
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
        _questionController.clear();
      });
    }
  }

  Future<String> _getAssistantResponse(String question) async {
    final normalized = question.toLowerCase().trim();
    final products = await _productService.getProducts();
    final matchedProducts = _findProducts(normalized, products);

    if (_containsAny(normalized, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      return 'Hi there! I’m Nyarongo AI assistant. I can help you with product details, pricing, availability, orders, delivery status, and support.';
    }

    if (_containsAny(normalized, ['who are you', 'what can you do', 'what are you'])) {
      return 'I am your Nyarongo AI assistant. Ask me about our demo wholesale products, order support, or delivery information.';
    }

    if (_containsAny(normalized, ['price', 'cost', 'how much'])) {
      if (matchedProducts.isNotEmpty) {
        return matchedProducts.map(_formatProductPrice).join('\n\n');
      }
      return 'To check prices, ask about a specific item like "What is the price of Pishori Rice 25kg?" or "How much is Maize Flour 2kg?".';
    }

    if (_containsAny(normalized, ['available', 'availability', 'in stock', 'stock'])) {
      if (matchedProducts.isNotEmpty) {
        return matchedProducts.map(_formatProductAvailability).join('\n\n');
      }
      return 'I can tell you whether products are in stock. Try asking "Is Maize Flour 2kg available?" or "What products are in stock?".';
    }

    if (_containsAny(normalized, ['tell me about', 'details', 'description', 'about'])) {
      if (matchedProducts.isNotEmpty) {
        return matchedProducts.map(_formatProductDescription).join('\n\n');
      }
      return 'Ask about a specific product name or category, for example "Tell me about Pishori Rice 25kg".';
    }

    if (_containsAny(normalized, ['product', 'products', 'catalog', 'show me', 'list'])) {
      if (matchedProducts.isNotEmpty) {
        return _formatProductListResponse(matchedProducts);
      }
      return _formatProductListResponse(products.where((item) => item.isAvailable).toList());
    }

    if (_containsAny(normalized, ['order', 'orders', 'delivery', 'delivered', 'shipped', 'pending'])) {
      return 'This assistant demo can describe product details and availability. For order status, ask your store support or use the order section in the app';
    }

    if (_containsAny(normalized, ['support', 'help', 'issue', 'problem'])) {
      return 'I can help with product availability, pricing, or how to contact support. For example, ask "How much is Soda Crate 300ml?".';
    }

    return 'I can answer product and order questions for the demo catalog. Try asking: "Hi", "What is the price of Pishori Rice 25kg?", or "What products are available?"';
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any(text.contains);
  }

  List<ProductModel> _findProducts(String normalized, List<ProductModel> products) {
    final categoryMatches = products
        .where((product) {
          final category = product.category.toLowerCase();
          return normalized.contains(category);
        })
        .toList(growable: false);

    if (categoryMatches.isNotEmpty) {
      return categoryMatches;
    }

    final matches = products.where((product) {
      final name = product.name.toLowerCase();
      return normalized.contains(name) || name.split(RegExp(r'[^a-z0-9]+')).any(normalized.contains);
    }).toList(growable: false);

    return matches;
  }

  String _formatProductPrice(ProductModel product) {
    return '${product.name} is priced at KSh ${product.price.toStringAsFixed(0)} each, or wholesale KSh ${product.wholesalePrice.toStringAsFixed(0)} per ${product.unit}.';
  }

  String _formatProductAvailability(ProductModel product) {
    return '${product.name} is ${product.isAvailable ? 'available' : 'currently out of stock'}.';
  }

  String _formatProductDescription(ProductModel product) {
    return '${product.name}: ${product.description} It costs KSh ${product.wholesalePrice.toStringAsFixed(0)} per ${product.unit} (min order ${product.minOrderQuantity}).';
  }

  String _formatProductListResponse(List<ProductModel> products) {
    if (products.isEmpty) {
      return 'I could not find any matching products. Try asking about a specific product name like "Pishori Rice 25kg".';
    }

    final buffer = StringBuffer('Here are some matching products:\n');
    for (var product in products.take(4)) {
      buffer.writeln('- ${product.name}: KSh ${product.wholesalePrice.toStringAsFixed(0)} / ${product.unit} (${product.isAvailable ? 'In stock' : 'Out of stock'})');
    }
    return buffer.toString().trim();
  }
}

class FoLogo extends StatelessWidget {
  final double size;

  const FoLogo({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FoLogoPainter(),
      ),
    );
  }
}

class _FoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..color = const Color(0xFFFF2D2D)
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.45, size.height * 0.45);
    final radius = size.width * 0.4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.0, 2.2, false, orbitPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FO',
        style: TextStyle(
          color: const Color(0xFF0E5F9B),
          fontSize: size.width * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatMessage {
  final String sender;
  final String text;

  const _ChatMessage({
    required this.sender,
    required this.text,
  });
}
