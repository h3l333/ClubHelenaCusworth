// Convierte DD/MM/AAAA en DateTime; lanza FormatException si el texto o la fecha no son validos.
DateTime parseBirthDate(String text) {
  final parts = text.trim().split('/');
  if (parts.length != 3) throw const FormatException('Formato invalido');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  final date = DateTime(year, month, day);
  // DateTime normaliza fechas fuera de rango (31/02 -> 03/03), por eso se compara.
  if (date.day != day || date.month != month || date.year != year) {
    throw const FormatException('Fecha fuera de rango');
  }
  return date;
}

// Devuelve un mensaje de error para el campo de fecha de nacimiento, o null si es valida.
String? validateBirthDate(String? value) {
  if (value == null || value.trim().isEmpty) return 'Requerido';
  try {
    final date = parseBirthDate(value);
    if (date.isAfter(DateTime.now()) || date.year < 1900) {
      return 'Fecha de nacimiento invalida.';
    }
  } on FormatException {
    return 'Use el formato DD/MM/AAAA.';
  }
  return null;
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String toIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

// Devuelve un mensaje de error para el DNI (6 a 10 digitos, admite puntos), o null si es valido.
String? validateDni(String? value) {
  if (value == null || value.trim().isEmpty) return 'Requerido';
  final digits = value.replaceAll(RegExp(r'[.\s-]'), '');
  if (!RegExp(r'^\d{6,10}$').hasMatch(digits)) {
    return 'Ingrese entre 6 y 10 digitos.';
  }
  return null;
}

// 30123456 -> 30.123.456
String formatDni(String dni) {
  final digits = dni.replaceAll(RegExp(r'\D'), '');
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

String initialsFor(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
