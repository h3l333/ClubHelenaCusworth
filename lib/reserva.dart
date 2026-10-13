class Reserva {
  final int id;
  final int canchaId;
  final String cancha;
  final String sede;
  final DateTime fecha; // solo la fecha (medianoche local)
  final String horaInicio; // 'HH:MM'
  final String horaFin; // 'HH:MM'
  final double price;
  final String estado; // 'confirmada' | 'cancelada'

  const Reserva({
    required this.id,
    required this.canchaId,
    required this.cancha,
    required this.sede,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.price,
    required this.estado,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as int,
    canchaId: json['cancha_id'] as int,
    cancha: json['cancha'] as String,
    sede: json['sede'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    horaInicio: json['hora_inicio'] as String,
    horaFin: json['hora_fin'] as String,
    price: (json['price'] as num).toDouble(),
    estado: json['estado'] as String,
  );

  String get horario => '$horaInicio - $horaFin';

  DateTime _at(String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime get startsAt => _at(horaInicio);
  DateTime get endsAt => _at(horaFin);

  bool get isCancelada => estado == 'cancelada';
  // Una reserva ya iniciada no se puede cancelar, por eso deja de estar activa.
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
