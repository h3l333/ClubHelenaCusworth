import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

import 'reserva.dart';
import 'services/api_client.dart';
import 'widgets/common.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  int _selectedTab = 0;
  EstadoReserva? _historialFiltro; // null = todas
  late Future<List<Reserva>> _future;
  // Copia local de las reservas: permite actualizar la UI sin volver a pedir la lista.
  List<Reserva> _reservas = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Reserva>> _load() async {
    final data = await ApiClient.instance.getReservas();
    _reservas = data;
    return data;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _cancel(Reserva reserva) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Querés cancelar ${reserva.cancha} el ${reserva.fechaLabel} de ${reserva.horaInicio} a ${reserva.horaFin}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cancelar reserva',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final cancelada = await ApiClient.instance.cancelReserva(reserva.id);
      if (!mounted) return;
      // Se reemplaza por la version cancelada: sale de Proximas y pasa al historial.
      setState(() {
        _reservas = [
          for (final r in _reservas) r.id == cancelada.id ? cancelada : r,
        ];
      });
      showSnack(context, 'Reserva cancelada');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, describeError(e));
      _reload(); // ante un error se resincroniza con el backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: FutureBuilder<List<Reserva>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorRetry(
                  message: describeError(snapshot.error!),
                  onRetry: _reload,
                );
              }
              return _buildContent(_reservas);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Reserva> reservas) {
    // Las reservas en curso siguen en Proximas aunque ya no se puedan cancelar.
    final proximas = reservas.where((r) => r.isActive || r.isEnCurso).toList();
    // El historial muestra primero lo mas reciente.
    final historial = reservas
        .where((r) => r.isFinalizada || r.isCancelada)
        .toList()
        .reversed
        .toList();
    final finalizadas = historial.where((r) => r.isFinalizada).length;
    final canceladas = historial.length - finalizadas;
    final visibles = _selectedTab == 0
        ? proximas
        : _historialFiltro == null
        ? historial
        : historial.where((r) => r.estadoActual == _historialFiltro).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis reservas',
          style: TextStyle(
            color: Colors.grey[850],
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${proximas.length} próximas - $finalizadas realizadas - $canceladas canceladas',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildTabBar(proximas.length),
        const SizedBox(height: 16),
        if (_selectedTab == 1) ...[
          _buildHistorialFiltros(historial.length, finalizadas, canceladas),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: visibles.isEmpty
              ? Center(
                  child: Text(
                    _selectedTab == 0
                        ? 'No tenés reservas próximas.'
                        : switch (_historialFiltro) {
                            EstadoReserva.finalizada =>
                              'No tenés reservas realizadas.',
                            EstadoReserva.cancelada =>
                              'No tenés reservas canceladas.',
                            _ => 'No tenés reservas en el historial.',
                          },
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.builder(
                    itemCount: visibles.length,
                    itemBuilder: (context, index) =>
                        _buildReservaCard(visibles[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTabBar(int proximasCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Próximas ($proximasCount)',
              selected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              'Historial',
              selected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialFiltros(int total, int finalizadas, int canceladas) {
    final filtros = <(String, EstadoReserva?)>[
      ('Todas ($total)', null),
      ('Realizadas ($finalizadas)', EstadoReserva.finalizada),
      ('Canceladas ($canceladas)', EstadoReserva.cancelada),
    ];
    return Wrap(
      spacing: 8,
      children: [
        for (final (label, filtro) in filtros)
          ChoiceChip(
            label: Text(label),
            selected: _historialFiltro == filtro,
            onSelected: (_) => setState(() => _historialFiltro = filtro),
            backgroundColor: AppColors.indigo[50],
            selectedColor: AppColors.indigo[400],
            checkmarkColor: Colors.black,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            side: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
      ],
    );
  }

  Widget _buildTabButton(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo[400] : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReservaCard(Reserva reserva) {
    final estado = reserva.estadoActual;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _estadoColors(estado).$1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(switch (estado) {
              EstadoReserva.confirmada => Icons.event_available,
              EstadoReserva.enCurso => Icons.timelapse,
              EstadoReserva.finalizada => Icons.task_alt,
              EstadoReserva.cancelada => Icons.event_busy,
            }, color: _estadoColors(estado).$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reserva.cancha,
                        style: TextStyle(
                          color: Colors.grey[850],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${reserva.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey[850],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${reserva.sede} · ${reserva.fechaLabel}, ${reserva.horario}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildEstadoBadge(reserva),
                    const Spacer(),
                    if (reserva.isActive)
                      TextButton(
                        onPressed: () => _cancel(reserva),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 28),
                        ),
                        child: const Text('Cancelar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (fondo, texto) por estado: confirmada/en curso resaltadas, finalizada gris, cancelada roja.
  static (Color, Color) _estadoColors(EstadoReserva estado) => switch (estado) {
    EstadoReserva.confirmada => (AppColors.indigo[400]!, Colors.black),
    EstadoReserva.enCurso => (AppColors.indigo[700]!, Colors.black),
    EstadoReserva.finalizada => (Colors.grey[300]!, Colors.grey[700]!),
    EstadoReserva.cancelada => (Colors.red[50]!, Colors.red[700]!),
  };

  Widget _buildEstadoBadge(Reserva reserva) {
    final (fondo, texto) = _estadoColors(reserva.estadoActual);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reserva.estadoLabel,
        style: TextStyle(
          color: texto,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
