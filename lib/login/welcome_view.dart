import 'package:flutter/material.dart';

import '../widgets/common.dart';

class WelcomeView extends StatelessWidget {
  final VoidCallback onStart;

  const WelcomeView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.lime[400],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lime.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'CLUB DEPORTIVO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[850],
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestión de Espacios Deportivos - Zona Oeste',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: limeFilledStyle(),
            onPressed: onStart,
            child: const Text('Comenzar'),
          ),
        ),
      ],
    );
  }
}
