import 'package:flutter/material.dart';

import '../booking_sheet.dart';
import '../sede.dart';
import '../theme/app_colors.dart';
import 'common.dart';

// Tarjeta de cancha con imagen, caracteristicas, precio y boton de reserva.
// Se usa en el detalle de sede y en el listado general de canchas.
class CanchaCard extends StatelessWidget {
  const CanchaCard({
    super.key,
    required this.cancha,
    required this.sede,
    this.showSede = false,
  });

  final Cancha cancha;
  final Sede sede;
  final bool showSede;

  @override
  Widget build(BuildContext context) {
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
                Text(
                  cancha.name,
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (showSede) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${sede.name} · ${sede.address} · ${sede.horarioLabel}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (cancha.subtype != null)
                            _Badge(cancha.subtype!, icon: Icons.sports_soccer),
                          for (final feature in cancha.features)
                            _Badge(feature),
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
                    onPressed: () => showBookingSheet(context, cancha, sede),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
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

  static IconData _iconForFeature(String feature) {
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
