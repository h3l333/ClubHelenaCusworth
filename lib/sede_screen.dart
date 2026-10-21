import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

import 'sede.dart';
import 'services/api_client.dart';
import 'widgets/cancha_card.dart';
import 'widgets/common.dart';

// Detalle de una sede: carga sus canchas del backend y permite reservarlas.
class SedeScreen extends StatefulWidget {
  final Sede sede;

  const SedeScreen({super.key, required this.sede});

  @override
  State<SedeScreen> createState() => _SedeScreenState();
}

class _SedeScreenState extends State<SedeScreen> {
  late Future<Sede> _future;
  String _selectedSport = 'Todos';
  String _selectedFutbolType = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getSede(widget.sede.id);
  }

  void _retry() =>
      setState(() => _future = ApiClient.instance.getSede(widget.sede.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            FutureBuilder<Sede>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: LoadingView(),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorRetry(
                    message: describeError(snapshot.error!),
                    onRetry: _retry,
                  );
                }
                return _buildCanchas(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanchas(Sede sede) {
    final sports = [
      'Todos',
      ...{for (final c in sede.canchas) c.sport},
    ];
    final filteredCanchas = sede.canchas.where((c) {
      if (_selectedSport != 'Todos' && c.sport != _selectedSport) return false;
      if (_selectedSport == 'Futbol' &&
          _selectedFutbolType != 'Todos' &&
          c.subtype != _selectedFutbolType) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSportFilters(sports),
          if (_selectedSport == 'Futbol') ...[
            const SizedBox(height: 10),
            _buildFutbolTypeFilters(),
          ],
          const SizedBox(height: 20),
          if (filteredCanchas.isEmpty)
            Text(
              'No hay canchas para este filtro.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          for (final cancha in filteredCanchas)
            CanchaCard(cancha: cancha, sede: widget.sede),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetImageWithFallback(widget.sede.resolvedHeaderImage),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: const [0.35, 1],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEDE',
                  style: TextStyle(
                    color: AppColors.indigo[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.sede.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                _OutlinedText(widget.sede.address),
                _OutlinedText('Abierto de ${widget.sede.horarioLabel}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilters(List<String> sports) {
    return SizedBox(
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
            onSelected: (_) => setState(() {
              _selectedSport = sport;
              _selectedFutbolType = 'Todos';
            }),
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
    );
  }

  Widget _buildFutbolTypeFilters() {
    const types = ['Todos', 'Futbol 5', 'Futbol 11'];
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final selected = type == _selectedFutbolType;
          return GestureDetector(
            onTap: () => setState(() => _selectedFutbolType = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.indigo[400] : AppColors.indigo[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                type,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Texto oscuro con contorno blanco: un trazo blanco debajo y el relleno encima.
class _OutlinedText extends StatelessWidget {
  final String text;

  const _OutlinedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
