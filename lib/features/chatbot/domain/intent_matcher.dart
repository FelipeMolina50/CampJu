import 'dart:math';
import '../data/models/faq_entry.dart';
import 'text_normalizer.dart';

class FaqMatchResult {
  final FaqEntry entry;
  final double score;
  final double confidence;

  const FaqMatchResult({
    required this.entry,
    required this.score,
    required this.confidence,
  });
}

class MatchDecision {
  final FaqEntry? selectedFaq;
  final double confidence;
  final bool isDisambiguation;
  final List<FaqEntry> disambiguationOptions;
  final bool isFallback;

  const MatchDecision({
    this.selectedFaq,
    required this.confidence,
    this.isDisambiguation = false,
    this.disambiguationOptions = const [],
    this.isFallback = false,
  });
}

class IntentMatcher {
  static const double confidenceThreshold = 0.45;
  static const double disambiguationDelta = 1.0;

  final Map<String, List<String>> synonyms;

  IntentMatcher({Map<String, List<String>>? customSynonyms})
      : synonyms = customSynonyms ?? _defaultSynonyms;

  static const Map<String, List<String>> _defaultSynonyms = {
    'inscribir': ['registrar', 'anotar', 'apuntar', 'matricular', 'inscripcion', 'registro', 'unirme', 'unir', 'ingresar', 'participar'],
    'bosque': ['delegacion', 'grupo', 'municipio', 'sede'],
    'ascenso': ['nivel', 'grado', 'rango', 'progresion', 'subir', 'ascender', 'asciendo', 'asciende', 'subo', 'ascendemos'],
    'curso': ['capacitacion', 'leccion', 'formacion', 'clase', 'cartilla', 'aprender'],
    'contrasena': ['clave', 'password', 'pass', 'restablecer'],
    'foto': ['fotos', 'imagen', 'imagenes', 'fotografia', 'fotografias', 'publicacion', 'publicaciones', 'video', 'videos'],
    'notificacion': ['alerta', 'alertas', 'aviso', 'avisos', 'recordatorio', 'push'],
    'coordinador': ['lider', 'encargado', 'jefe'],
    'datos': ['informacion', 'privacidad', 'habeas', 'seguridad', 'personal'],
    'encuentro': ['evento', 'campamento', 'actividad'],
    'ayuda': ['soporte', 'problema', 'error', 'falla', 'contacto', 'reportar'],
  };

  bool areSynonyms(String tokenA, String tokenB) {
    if (tokenA == tokenB) return true;
    final stemA = TextNormalizer.stem(tokenA);
    final stemB = TextNormalizer.stem(tokenB);
    if (stemA == stemB) return true;

    for (final entry in synonyms.entries) {
      final keyStem = TextNormalizer.stem(entry.key);
      final valStems = entry.value.map(TextNormalizer.stem).toSet();

      final aMatches = (stemA == keyStem || valStems.contains(stemA));
      final bMatches = (stemB == keyStem || valStems.contains(stemB));

      if (aMatches && bMatches) return true;
    }
    return false;
  }

  bool _matchesToken(String uToken, String targetToken) {
    if (uToken == targetToken) return true;
    if (areSynonyms(uToken, targetToken)) return true;
    if (targetToken.length >= 5 && uToken.length >= 4) {
      final dist = TextNormalizer.levenshtein(uToken, targetToken);
      if (dist <= 1) return true;
    }
    return false;
  }

  MatchDecision match(String rawUserInput, List<FaqEntry> faqs, {required String role}) {
    final normalizedInput = TextNormalizer.normalize(rawUserInput);
    final userTokens = TextNormalizer.tokens(rawUserInput);

    final List<FaqMatchResult> scoredResults = [];

    // Filter by role first
    final eligibleFaqs = faqs.where((f) => f.appliesToRole(role)).toList();

    for (final faq in eligibleFaqs) {
      double score = 0.0;
      final Set<int> matchedUserTokenIndices = {};
      int matchedKeywordsCount = 0;

      // 1. Keyword matching
      for (final rawKw in faq.keywords) {
        final normKw = TextNormalizer.normalize(rawKw);
        final kwTokens = TextNormalizer.tokens(rawKw);

        if (kwTokens.isEmpty) continue;

        if (kwTokens.length > 1) {
          // Multi-word keyword: exact phrase or all tokens present
          if (normalizedInput.contains(normKw)) {
            score += 3.0;
            matchedKeywordsCount++;
          } else {
            // Check if every token in the multi-word keyword has a match in userTokens
            bool allFound = true;
            final Set<int> potentialIndices = {};
            for (final kwTok in kwTokens) {
              bool found = false;
              for (int i = 0; i < userTokens.length; i++) {
                if (!potentialIndices.contains(i) && _matchesToken(userTokens[i], kwTok)) {
                  potentialIndices.add(i);
                  found = true;
                  break;
                }
              }
              if (!found) {
                allFound = false;
                break;
              }
            }
            if (allFound) {
              score += 3.0;
              matchedKeywordsCount++;
              matchedUserTokenIndices.addAll(potentialIndices);
            }
          }
        } else {
          final targetToken = kwTokens.first;
          bool matchedThisKw = false;

          for (int i = 0; i < userTokens.length; i++) {
            if (matchedUserTokenIndices.contains(i)) continue;
            final uToken = userTokens[i];

            // Exact match
            if (uToken == targetToken) {
              score += 3.0;
              matchedThisKw = true;
              matchedUserTokenIndices.add(i);
              break;
            }
            // Synonym match
            if (areSynonyms(uToken, targetToken)) {
              score += 2.0;
              matchedThisKw = true;
              matchedUserTokenIndices.add(i);
              break;
            }
            // Levenshtein approximation for length >= 5
            if (targetToken.length >= 5 && uToken.length >= 4) {
              final dist = TextNormalizer.levenshtein(uToken, targetToken);
              if (dist <= 1) {
                score += 2.0;
                matchedThisKw = true;
                matchedUserTokenIndices.add(i);
                break;
              }
            }
          }

          if (matchedThisKw) {
            matchedKeywordsCount++;
          }
        }
      }

      // 2. Phrase matching bonus
      for (final phrase in faq.frases) {
        final phraseTokens = TextNormalizer.tokens(phrase);
        final normPhrase = TextNormalizer.normalize(phrase);

        if (normPhrase.isNotEmpty && normalizedInput.contains(normPhrase)) {
          score += 5.0;
          break;
        }

        if (phraseTokens.isNotEmpty) {
          // Check token similarity with tolerance for typos
          int matchingPhraseTokens = 0;
          for (final pTok in phraseTokens) {
            for (final uTok in userTokens) {
              if (_matchesToken(uTok, pTok)) {
                matchingPhraseTokens++;
                break;
              }
            }
          }

          final similarity = matchingPhraseTokens / max(userTokens.length, phraseTokens.length);
          if (similarity >= 0.8) {
            score += 5.0;
            break;
          }
        }
      }

      // 3. Role bonus (specific role over generic '*')
      if (!faq.roles.contains('*') && faq.appliesToRole(role)) {
        score += 1.0;
      }

      // 4. Priority tiebreaker
      score += (faq.prioridad * 0.1);

      // 5. Confidence calculation
      final expectedTokens = max(1, min(userTokens.length, faq.keywords.length).clamp(1, 4));
      final confidence = (score / (3.0 * expectedTokens)).clamp(0.0, 1.0);

      if (score > 0 && (matchedKeywordsCount > 0 || score >= 5.0)) {
        scoredResults.add(FaqMatchResult(
          entry: faq,
          score: score,
          confidence: confidence,
        ));
      }
    }

    if (scoredResults.isEmpty) {
      return const MatchDecision(
        confidence: 0.0,
        isFallback: true,
      );
    }

    // Sort descending by score
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    final best = scoredResults.first;

    // Check fallback threshold
    if (best.confidence < confidenceThreshold) {
      return MatchDecision(
        confidence: best.confidence,
        isFallback: true,
      );
    }

    // Check disambiguation between top 2
    if (scoredResults.length > 1) {
      final second = scoredResults[1];
      if ((best.score - second.score) < disambiguationDelta &&
          second.confidence >= confidenceThreshold &&
          best.entry.id != second.entry.id) {
        final options = [best.entry, second.entry];
        if (scoredResults.length > 2 &&
            (best.score - scoredResults[2].score) < disambiguationDelta &&
            scoredResults[2].confidence >= confidenceThreshold) {
          options.add(scoredResults[2].entry);
        }
        return MatchDecision(
          confidence: best.confidence,
          isDisambiguation: true,
          disambiguationOptions: options,
        );
      }
    }

    return MatchDecision(
      selectedFaq: best.entry,
      confidence: best.confidence,
    );
  }
}
