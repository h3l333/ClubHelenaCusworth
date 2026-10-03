class Reserva {
  final int id;
  final int canchaId;
  final String cancha;
  final String sede;
  final DateTime fecha; // solo la fecha (medianoche local)
  final String horario; // 'HH:MM'
  final double price;
  final String estado; // 'confirmada' | 'cancelada'

  const Reserva({
    required this.id,
    required this.canchaId,
    required this.cancha,
    required this.sede,
    required this.fecha,
    required this.horario,
    required this.price,
    required this.estado,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as int,
    canchaId: json['cancha_id'] as int,
    cancha: json['cancha'] as String,
    sede: json['sede'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    horario: json['hora'] as String,
    price: (json['price'] as num).toDouble(),
    estado: json['estado'] as String,
  );

  DateTime get startsAt {
    final parts = horario.split(':');
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  bool get isCancelada => estado == 'cancelada';
  bool get isPast => startsAt.isBefore(DateTime.now());
  bool get isActive => !isCancelada && !isPast;

  String get estadoLabel => isCancelada
      ? 'Cancelada'
      : isPast
      ? 'Finalizada'
      : 'Confirmada';

  String get fechaLabel {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }
}
