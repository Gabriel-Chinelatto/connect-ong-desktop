/// Conversões tolerantes de JSON para os `fromJson` dos models.
///
/// O backend (JPA/MySQL) às vezes serializa valores de forma inesperada para o
/// cliente: um booleano pode chegar como 0/1 (a origem do bug do `doisFatores`,
/// que travava o Salvar Configurações), um id pode vir como num, um campo pode
/// vir null numa coluna criada depois. Estes helpers convertem com segurança e
/// recaem em defaults em vez de estourar `type cast` e derrubar a tela.
library;

/// Converte para int aceitando int, num ("2.0") e String ("2"); null/inesperado
/// -> [fallback].
int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Igual a [asInt], mas preserva null (para campos opcionais como ongId).
int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  return asInt(v);
}

/// Converte para double aceitando num e String; null/inesperado -> [fallback].
double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

/// Converte para bool aceitando bool, num (0/1 do MySQL) e String
/// ("true"/"1"); null/inesperado -> [fallback].
bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return fallback;
}

/// Converte para String; null -> [fallback] (default "").
String asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

/// Igual a [asString], mas preserva null (para campos opcionais).
String? asStringOrNull(dynamic v) => v?.toString();
