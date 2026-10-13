import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

import 'sede.dart';
import 'services/api_client.dart';
import 'widgets/cancha_card.dart';
import 'widgets/common.dart';

// Listado de todas las canchas con su sede, filtrable por tipo (pestaña "Canchas").
class CanchasScreen extends StatefulWidget {
  const CanchasScreen({super.key});

  @override
  State<CanchasScreen> createState() => _CanchasScreenState();
}

class _CanchasScreenState extends State<CanchasScreen> {
  late Future<List<({Cancha cancha, Sede sede})>> _future;
  String _selectedSport = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getCanchas();
  }

  void _reload() => setState(() => _future = ApiClient.instance.getCanchas());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canchas',
                style: TextStyle(
                  color: Colors.grey[850],
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Todas las canchas del club, por tipo',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<({Cancha cancha, Sede sede})>>(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<({Cancha cancha, Sede sede})> items) {
    // Los tipos salen de los datos, asi un deporte nuevo en el backend aparece solo.
    final sports = ['Todos', ...{for (final i in items) i.cancha.sport}];
    final filtered = _selectedSport == 'Todos'
        ? items
        : items.where((i) => i.cancha.sport == _selectedSport).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = sports[index];
              final selected = sport == _selectedSport;
              return ChoiceChip(
                label: Text(sport),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSport = sport),
                backgroundColor: AppColors.indigo[50],
                selectedColor: AppColors.indigo[400],
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: Colors.grey[700]!, width: 1),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? Text(
                  'No hay canchas para este filtro.',
                  style: TextStyle(color: Colors.grey[500]),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => CanchaCard(
                    cancha: filtered[i].cancha,
                    sede: filtered[i].sede,
                    showSede: true,
                  ),
                ),
        ),
      ],
    );
  }
}
