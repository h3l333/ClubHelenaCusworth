import 'package:flutter_test/flutter_test.dart';

import 'package:club_helena_cusworth/date_utils.dart';
import 'package:club_helena_cusworth/reserva.dart';
import 'package:club_helena_cusworth/sede.dart';
import 'package:club_helena_cusworth/user_profile.dart';

void main() {
  group('parseBirthDate', () {
    test('parses DD/MM/AAAA', () {
      expect(parseBirthDate('12/04/1990'), DateTime(1990, 4, 12));
    });

    test('rejects out-of-range and malformed dates', () {
      expect(() => parseBirthDate('31/02/1990'), throwsFormatException);
      expect(() => parseBirthDate('1990-04-12'), throwsFormatException);
      expect(() => parseBirthDate('aa/bb/cccc'), throwsFormatException);
    });
  });

  group('validators', () {
    test('birth date must be past and formatted', () {
      expect(validateBirthDate('12/04/1990'), isNull);
      expect(validateBirthDate('12/04/2999'), isNotNull);
      expect(validateBirthDate(''), isNotNull);
    });

    test('dni accepts dots and 6-10 digits', () {
      expect(validateDni('30.123.456'), isNull);
      expect(validateDni('123'), isNotNull);
      expect(validateDni('abc'), isNotNull);
    });

    test('formatDni adds thousands separators', () {
      expect(formatDni('30123456'), '30.123.456');
    });
  });

  test('toIsoDate pads month and day', () {
    expect(toIsoDate(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('UserProfile.fromJson', () {
    final p = UserProfile.fromJson({
      'id': 1,
      'email': 'a@b.com',
      'first_name': 'Juan',
      'last_name': 'Perez',
      'birth_date': '1990-04-12',
      'dni': '30123456',
    });
    expect(p.fullName, 'Juan Perez');
    expect(p.initials, 'JP');
    expect(p.birthDateLabel, '12/04/1990');
  });

  test('Sede.fromJson with canchas', () {
    final s = Sede.fromJson({
      'id': 1,
      'name': 'Sede Norte',
      'localidad': 'Norte',
      'address': 'Av. 1',
      'header_image': null,
      'hora_apertura': '08:00',
      'hora_cierre': '23:00',
      'sports': ['Futbol'],
      'canchas': [
        {
          'id': 3,
          'name': 'Norte_Libertador_1200_Futbol_1',
          'display_name': 'Norte Libertador 1200 Futbol 1',
          'sport': 'Futbol',
          'subtype': 'Futbol 5',
          'price': 8000.0,
          'features': ['Outdoor'],
          'image': null,
        },
      ],
    });
    expect(s.horarioLabel, '08:00 a 23:00');
    expect(s.canchas.single.label, 'Norte Libertador 1200 Futbol 1 (Futbol 5)');
    expect(s.canchas.single.resolvedImage, contains('futbol'));
  });

  test('Reserva state', () {
    Map<String, dynamic> json(String fecha, String estado) => {
      'id': 1,
      'cancha_id': 1,
      'cancha': 'Cancha 1 - Futbol 5',
      'sede': 'Sede Norte',
      'fecha': fecha,
      'hora_inicio': '18:00',
      'hora_fin': '20:00',
      'price': 8000,
      'estado': estado,
    };
    final future = DateTime.now().add(const Duration(days: 3));
    final futureIso = toIsoDate(future);
    expect(Reserva.fromJson(json(futureIso, 'confirmada')).isActive, isTrue);
    expect(
      Reserva.fromJson(json(futureIso, 'confirmada')).horario,
      '18:00 - 20:00',
    );
    expect(
      Reserva.fromJson(json(futureIso, 'cancelada')).estadoLabel,
      'Cancelada',
    );
    expect(
      Reserva.fromJson(json('2020-01-01', 'confirmada')).estadoLabel,
      'Finalizada',
    );
  });

  test('Reserva en curso no es cancelable ni finalizada', () {
    final now = DateTime.now();
    String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
    final r = Reserva(
      id: 1,
      canchaId: 1,
      cancha: 'Norte_Libertador_1200_Futbol_1 - Futbol 5',
      sede: 'Sede Norte',
      fecha: DateTime(now.year, now.month, now.day),
      horaInicio: hh(now.hour),
      horaFin: hh(now.hour + 1),
      price: 8000,
      estado: 'confirmada',
    );
    expect(r.estadoActual, EstadoReserva.enCurso);
    expect(r.estadoLabel, 'En curso');
    expect(r.isActive, isFalse);
  });
}
