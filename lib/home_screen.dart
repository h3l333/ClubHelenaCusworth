import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'perfil_edit.dart';
import 'profile_widgets.dart';
import 'reservas_screen.dart';
import 'sede.dart';
import 'sedes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  // La linea previa dice que "createState()" debe retornar una instancia de
  // State<HomeScreen>, especificamente _HomeScreenState.
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock: se reemplazará por datos reales del perfil del usuario más adelante.
  static const _fullName = 'Juan Pérez';
  static const _dni = '30.123.456';
  static const _birthDate = '12/04/1990';
  static const _mockNotifications = [
    'Tu reserva de la cancha 3 fue confirmada.',
    'Recordá tu turno de mañana a las 18:00.',
  ];
  static const _nextReservation = {
    'cancha': 'Cancha 3 - Fútbol',
    'sede': 'Sede Norte',
    'horario': 'Mañana, 18:00',
  };
  static const _filters = ['Todos', 'Futbol', 'Tenis', 'Golf'];

  bool _profileMenuOpen = false;
  int _selectedIndex = 0;
  String _selectedFilter = 'Todos';

  String get _firstName => _fullName.trim().split(RegExp(r'\s+')).first;

  String get _lastName => _fullName.trim().split(RegExp(r'\s+')).last;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          switch (_selectedIndex) {
            0 => _HomeContent(
              firstName: _firstName,
              initials: initialsFor(_fullName),
              notifications: _mockNotifications,
              nextReservation: _nextReservation,
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) =>
                  setState(() => _selectedFilter = filter),
              sedes: kSedes,
              onAvatarTap: () =>
                  setState(() => _profileMenuOpen = !_profileMenuOpen),
            ),
            1 => const SedesScreen(),
            2 => const ReservasScreen(),
            3 => const PerfilEdit(),
            _ => const SizedBox.shrink(),
          },
          if (_profileMenuOpen)
            _ProfileMenuOverlay(
              fullName: _fullName,
              lastName: _lastName,
              dni: _dni,
              birthDate: _birthDate,
              email: email,
              onClose: () => setState(() => _profileMenuOpen = false),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.lime[700],
          unselectedItemColor: Colors.grey[500],
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'Sedes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String firstName;
  final String initials;
  final List<String> notifications;
  final Map<String, String> nextReservation;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final List<Sede> sedes;
  final VoidCallback onAvatarTap;

  const _HomeContent({
    required this.firstName,
    required this.initials,
    required this.notifications,
    required this.nextReservation,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.sedes,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final filteredSedes = selectedFilter == 'Todos'
        ? sedes
        : sedes.where((sede) => sede.sports.contains(selectedFilter)).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeader(
            firstName: firstName,
            initials: initials,
            notifications: notifications,
            onAvatarTap: onAvatarTap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NextReservationCard(reservation: nextReservation),
                const SizedBox(height: 28),
                _FilterButtons(
                  filters: filters,
                  selectedFilter: selectedFilter,
                  onSelected: onFilterSelected,
                ),
                const SizedBox(height: 16),
                Text(
                  'SEDES DISPONIBLES',
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                _SedesCarousel(sedes: filteredSedes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String firstName;
  final String initials;
  final List<String> notifications;
  final VoidCallback onAvatarTap;

  const _HomeHeader({
    required this.firstName,
    required this.initials,
    required this.notifications,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/cancha-tenis.jpg', fit: BoxFit.cover),
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
            right: 8,
            child: Row(
              children: [
                NotificationsMenuButton(notifications: notifications),
                ProfileAvatarButton(initials: initials, onTap: onAvatarTap),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'SPORTS CLUB',
                  style: TextStyle(
                    color: Colors.lime[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ZONA DEPORTIVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1,
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

class _NextReservationCard extends StatelessWidget {
  final Map<String, String> reservation;

  const _NextReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.lime[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima reserva',
                  style: TextStyle(color: Colors.lime[900], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  reservation['cancha']!,
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${reservation['sede']} · ${reservation['horario']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButtons extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _FilterButtons({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => onSelected(filter),
            backgroundColor: Colors.yellow[50],
            selectedColor: Colors.lime[400],
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
}

class _SedesCarousel extends StatelessWidget {
  final List<Sede> sedes;

  const _SedesCarousel({required this.sedes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sedes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final sede = sedes[index];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.lime[700]),
                const SizedBox(height: 8),
                Text(
                  sede.name,
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sede.sports.join(' y '),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenuOverlay extends StatelessWidget {
  final String fullName;
  final String lastName;
  final String dni;
  final String birthDate;
  final String email;
  final VoidCallback onClose;

  const _ProfileMenuOverlay({
    required this.fullName,
    required this.lastName,
    required this.dni,
    required this.birthDate,
    required this.email,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 48,
          right: 12,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.lime[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        initialsFor(fullName),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[850],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MIEMBRO ACTIVO',
                            style: TextStyle(
                              color: Colors.lime[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Apellido: $lastName',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'DNI: $dni',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'email: $email',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nac.: $birthDate',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Perfil completo'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[850],
                      side: BorderSide(color: Colors.grey[700]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Mis Reservas'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey[850],
                      side: BorderSide(color: Colors.grey[700]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
