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

  String get resolvedImage => image ?? _defaultImage();

  // Cantidad de imagenes disponibles por deporte en assets/images/<deporte>/.
  static const _imageCounts = {'futbol': 4, 'tenis': 3, 'golf': 3};

  // Se reparte por id para que canchas del mismo deporte no repitan imagen.
  // Sin imagenes para el deporte, la ruta no existe y AssetImageWithFallback muestra el icono.
  String _defaultImage() {
    final key = sport.toLowerCase();
    final count = _imageCounts[key];
    if (count == null) return 'assets/images/$key/cancha-$key.jpg';
    final n = id % count;
    final suffix = n == 0 ? '' : '-${n + 1}';
    return 'assets/images/$key/cancha-$key$suffix.jpg';
  }
}

class Sede {
  final int id;
  final String name;
  final String localidad;
  final String address;
  final String? headerImage;
  final String horaApertura; // 'HH:MM'
  final String horaCierre; // 'HH:MM'
  final List<String> sports;
  final List<Cancha> canchas; // vacio en el listado; completo en el detalle

  const Sede({
    required this.id,
    required this.name,
    required this.localidad,
    required this.address,
    this.headerImage,
    required this.horaApertura,
    required this.horaCierre,
    required this.sports,
    this.canchas = const [],
  });

  factory Sede.fromJson(Map<String, dynamic> json) => Sede(
    id: json['id'] as int,
    name: json['name'] as String,
    localidad: json['localidad'] as String,
    address: json['address'] as String,
    headerImage: json['header_image'] as String?,
    horaApertura: json['hora_apertura'] as String,
    horaCierre: json['hora_cierre'] as String,
    sports: (json['sports'] as List? ?? const []).cast<String>(),
    canchas: (json['canchas'] as List? ?? const [])
        .map((c) => Cancha.fromJson(c as Map<String, dynamic>))
        .toList(),
  );

  String get horarioLabel => '$horaApertura a $horaCierre';

  String get resolvedHeaderImage =>
      headerImage ?? 'assets/images/sedes/sede-${localidad.toLowerCase()}.jpg';
}
