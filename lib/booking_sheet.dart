import 'package:flutter/material.dart';

import 'date_utils.dart';
import 'sede.dart';
import 'services/api_client.dart';
import 'widgets/common.dart';

const _diasVisibles = 14;
const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

Future<void> showBookingSheet(BuildContext context, Cancha cancha, Sede sede) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _BookingSheet(cancha: cancha, sede: sede),
  );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.cancha, required this.sede});

  final Cancha cancha;
  final Sede sede;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late final List<DateTime> _dias;
  late DateTime _fecha;
  Future<List<Slot>>? _slots;
  String? _hora;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    _dias = [
      for (var i = 0; i < _diasVisibles; i++) hoy.add(Duration(days: i)),
    ];
    _selectDay(_dias.first);
  }

  void _selectDay(DateTime dia) {
    _fecha = dia;
    _hora = null;
    _error = null;
    _slots = ApiClient.instance.getDisponibilidad(widget.cancha.id, dia);
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.createReserva(
        canchaId: widget.cancha.id,
        fecha: _fecha,
        hora: _hora!,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reserva confirmada: ${widget.cancha.label}, ${formatDate(_fecha)} $_hora',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeError(e);
        // Si alguien tomo el horario mientras tanto, se refresca la disponibilidad.
        if (e is ApiException && e.statusCode == 409) _selectDay(_fecha);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cancha.label,
              style: TextStyle(
                color: Colors.grey[850],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${widget.sede.name} · \$${widget.cancha.price.toStringAsFixed(0)}/h',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dias.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final dia = _dias[i];
                  final selected = dia == _fecha;
                  return GestureDetector(
                    onTap: _saving
                        ? null
                        : () => setState(() => _selectDay(dia)),
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: selected ? Colors.lime[400] : Colors.yellow[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _diasSemana[dia.weekday - 1],
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '${dia.day}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Slot>>(
              future: _slots,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorRetry(
                    message: describeError(snapshot.error!),
                    onRetry: () => setState(() => _selectDay(_fecha)),
                  );
                }
                final slots = snapshot.data!;
                if (!slots.any((s) => s.disponible)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay horarios disponibles para este día.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in slots)
                      ChoiceChip(
                        label: Text(slot.hora),
                        selected: _hora == slot.hora,
                        onSelected: slot.disponible && !_saving
                            ? (_) => setState(() => _hora = slot.hora)
                            : null,
                        selectedColor: Colors.lime[400],
                        backgroundColor: Colors.yellow[50],
                        side: BorderSide(color: Colors.grey[700]!),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: limeFilledStyle(fontSize: 15),
                onPressed: _hora == null || _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _hora == null ? 'Elegí un horario' : 'Reservar $_hora',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
