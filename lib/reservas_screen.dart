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
  late Future<List<Reserva>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getReservas();
  }

  void _reload() => setState(() => _future = ApiClient.instance.getReservas());

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
      await ApiClient.instance.cancelReserva(reserva.id);
      if (!mounted) return;
      showSnack(context, 'Reserva cancelada');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, describeError(e));
    }
    _reload();
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
              return _buildContent(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Reserva> reservas) {
    final proximas = reservas.where((r) => r.isActive).toList();
    // El historial muestra primero lo mas reciente.
    final historial = reservas
        .where((r) => !r.isActive)
        .toList()
        .reversed
        .toList();
    final visibles = _selectedTab == 0 ? proximas : historial;

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
          '${proximas.length} activas - ${historial.length} historial',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildTabBar(proximas.length),
        const SizedBox(height: 20),
        Expanded(
          child: visibles.isEmpty
              ? Center(
                  child: Text(
                    _selectedTab == 0
                        ? 'No tenés reservas próximas.'
                        : 'No tenés reservas en el historial.',
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
    final inactive = !reserva.isActive;
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
              color: inactive ? Colors.grey[300] : AppColors.indigo[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reserva.isCancelada
                  ? Icons.event_busy
                  : inactive
                  ? Icons.history
                  : Icons.event_available,
              color: Colors.black,
            ),
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

  Widget _buildEstadoBadge(Reserva reserva) {
    final inactive = !reserva.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inactive ? Colors.grey[200] : AppColors.indigo[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reserva.estadoLabel,
        style: TextStyle(
          color: inactive ? Colors.grey[600] : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
