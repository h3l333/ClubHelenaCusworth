enum EstadoReserva { confirmada, enCurso, finalizada, cancelada }

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

  // El backend solo guarda 'confirmada'/'cancelada'; en curso y finalizada
  // se derivan comparando el horario con la hora actual.
  EstadoReserva get estadoActual {
    if (estado == 'cancelada') return EstadoReserva.cancelada;
    final now = DateTime.now();
    if (!endsAt.isAfter(now)) return EstadoReserva.finalizada;
    if (!startsAt.isAfter(now)) return EstadoReserva.enCurso;
    return EstadoReserva.confirmada;
  }

  bool get isCancelada => estadoActual == EstadoReserva.cancelada;
  bool get isFinalizada => estadoActual == EstadoReserva.finalizada;
  bool get isEnCurso => estadoActual == EstadoReserva.enCurso;
  // Solo las reservas que todavia no empezaron se pueden cancelar.
  bool get isActive => estadoActual == EstadoReserva.confirmada;

  String get estadoLabel => switch (estadoActual) {
    EstadoReserva.confirmada => 'Confirmada',
    EstadoReserva.enCurso => 'En curso',
    EstadoReserva.finalizada => 'Finalizada',
    EstadoReserva.cancelada => 'Cancelada',
  };

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
