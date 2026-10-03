// Modelos de sedes y canchas. Vienen del backend (GET /sedes, GET /sedes/{id}).
class Cancha {
  final int id;
  final String name;
  final String sport;
  final String? subtype; // ej: 'Futbol 5', 'Futbol 11'
  final double price;
  final List<String> features; // ej: ['Outdoor', 'Iluminada']
  final String? image;

  const Cancha({
    required this.id,
    required this.name,
    required this.sport,
    this.subtype,
    required this.price,
    this.features = const [],
    this.image,
  });

  factory Cancha.fromJson(Map<String, dynamic> json) => Cancha(
    id: json['id'] as int,
    name: json['name'] as String,
    sport: json['sport'] as String,
    subtype: json['subtype'] as String?,
    price: (json['price'] as num).toDouble(),
    features: (json['features'] as List? ?? const []).cast<String>(),
    image: json['image'] as String?,
  );

  String get label => '$name - ${subtype ?? sport}';

  String get resolvedImage => image ?? _defaultImageForSport(sport);

  static String _defaultImageForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'futbol':
        return 'assets/images/futbol/futbol-1.jpg';
      case 'tenis':
        return 'assets/images/tenis/tenis-1.jpg';
      case 'hockey':
        return 'assets/images/hockey/hockey-1.jpg';
      default:
        return 'assets/images/cancha-tenis.jpg';
    }
  }
}

class Sede {
  final int id;
  final String name;
  final String localidad;
  final String address;
  final String? headerImage;
  final List<String> sports;
  final List<Cancha> canchas; // vacio en el listado; completo en el detalle

  const Sede({
    required this.id,
    required this.name,
    required this.localidad,
    required this.address,
    this.headerImage,
    required this.sports,
    this.canchas = const [],
  });

  factory Sede.fromJson(Map<String, dynamic> json) => Sede(
    id: json['id'] as int,
    name: json['name'] as String,
    localidad: json['localidad'] as String,
    address: json['address'] as String,
    headerImage: json['header_image'] as String?,
    sports: (json['sports'] as List? ?? const []).cast<String>(),
    canchas: (json['canchas'] as List? ?? const [])
        .map((c) => Cancha.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  String get resolvedHeaderImage =>
      headerImage ?? 'assets/images/cancha-tenis.jpg';
}
