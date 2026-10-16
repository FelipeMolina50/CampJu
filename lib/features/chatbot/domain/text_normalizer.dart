class TextNormalizer {
  static const _from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  static const _to =   'aaaaaeeeeiiiiooooouuuunc';

  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    for (var i = 0; i < _from.length; i++) {
      s = s.replaceAll(_from[i], _to[i]);
    }
    // Replace punctuation with spaces
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Collapse multiple spaces into one
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Set<String> stopwords = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'de', 'del', 'al', 'a', 'en', 'y', 'o', 'u',
    'que', 'como', 'cual', 'cuales', 'quien', 'donde', 'cuando',
    'por', 'para', 'con', 'sin', 'se', 'es', 'son', 'ser',
    'esta', 'estan', 'hay', 'me', 'mi', 'mis', 'tu', 'tus',
    'su', 'sus', 'lo', 'le', 'les', 'si', 'no', 'mas',
    'muy', 'ya', 'yo', 'quiero', 'puedo', 'necesito', 'favor', 'hola'
  };

  static List<String> tokens(String input) {
    return normalize(input)
        .split(' ')
        .where((t) => t.isNotEmpty && !stopwords.contains(t))
        .map(stem)
        .toList();
  }

  // Light stemming for Spanish plurals and clitic pronouns
  static String stem(String t) {
    var word = t;
    // Strip enclitic pronouns: unirme -> unir, registrarme -> registrar
    if (word.length > 5) {
      if (word.endsWith('me') || word.endsWith('te') || word.endsWith('se')) {
        word = word.substring(0, word.length - 2);
      } else if (word.endsWith('nos')) {
        word = word.substring(0, word.length - 3);
      }
    }
    // Spanish plurals:
    // If ending in -es preceded by consonant like d, l, r, n, z, j (solicitudes -> solicitud, lecciones -> leccion)
    if (word.length > 4 && word.endsWith('es')) {
      final before = word[word.length - 3];
      if ('dlrnzj'.contains(before)) {
        return word.substring(0, word.length - 2);
      }
    }
    // If ending in -s (bosques -> bosque, cursos -> curso, ascensos -> ascenso)
    if (word.length > 3 && word.endsWith('s')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  // Levenshtein distance calculation
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,       // insertion
          v0[j + 1] + 1,   // deletion
          v0[j] + cost     // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  // Jaccard similarity between two lists of tokens
  static double jaccard(List<String> a, List<String> b) {
    final setA = a.toSet();
    final setB = b.toSet();
    if (setA.isEmpty && setB.isEmpty) return 1.0;
    if (setA.isEmpty || setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return intersection / union;
  }
}
