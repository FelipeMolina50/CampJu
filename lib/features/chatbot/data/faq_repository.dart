import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/faq_entry.dart';

class FaqRepository {
  static const String defaultAssetPath = 'assets/chatbot/faq.json';

  final String assetPath;
  List<FaqEntry>? _cachedFaqs;

  FaqRepository({this.assetPath = defaultAssetPath});

  bool get isLoaded => _cachedFaqs != null;

  List<FaqEntry> get faqs => _cachedFaqs ?? const [];

  Future<List<FaqEntry>> load({bool forceReload = false}) async {
    if (_cachedFaqs != null && !forceReload) {
      return _cachedFaqs!;
    }

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      return parseFaqs(jsonStr);
    } catch (e) {
      // Return empty list if asset fails to load, or preserve existing cache
      if (_cachedFaqs != null) return _cachedFaqs!;
      rethrow;
    }
  }

  List<FaqEntry> parseFaqs(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> faqsJson = data['faqs'] as List<dynamic>? ?? [];
    final list = faqsJson
        .map((item) => FaqEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    _cachedFaqs = list;
    return list;
  }

  void setFaqs(List<FaqEntry> faqs) {
    _cachedFaqs = List.unmodifiable(faqs);
  }
}
