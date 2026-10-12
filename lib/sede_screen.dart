import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

import 'booking_sheet.dart';
import 'sede.dart';
import 'services/api_client.dart';
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
          for (final cancha in filteredCanchas) _buildCanchaCard(cancha),
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
                Text(
                  widget.sede.address,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
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

  Widget _buildCanchaCard(Cancha cancha) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.indigo[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AssetImageWithFallback(cancha.resolvedImage),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (cancha.subtype != null)
                            _buildBadge(
                              cancha.subtype!,
                              icon: Icons.sports_soccer,
                            ),
                          for (final feature in cancha.features)
                            _buildBadge(feature),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${cancha.price.toStringAsFixed(0)}/h',
                      style: TextStyle(
                        color: Colors.grey[850],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('VER HORARIOS / RESERVAR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo[400],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () =>
                        showBookingSheet(context, cancha, widget.sede),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? _iconForFeature(label),
            size: 12,
            color: AppColors.indigo[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'outdoor':
        return Icons.wb_sunny_outlined;
      case 'indoor':
        return Icons.home_outlined;
      case 'iluminada':
        return Icons.lightbulb_outline;
      case 'techada':
        return Icons.roofing_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}
