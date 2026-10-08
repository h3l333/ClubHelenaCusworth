import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'date_utils.dart';
import 'perfil_edit.dart';
import 'profile_widgets.dart';
import 'reserva.dart';
import 'reservas_screen.dart';
import 'sede.dart';
import 'sede_screen.dart';
import 'sedes_screen.dart';
import 'services/api_client.dart';
import 'services/profile_store.dart';
import 'user_profile.dart';
import 'widgets/common.dart';
import 'services/push_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  // La linea previa dice que "createState()" debe retornar una instancia de
  // State<HomeScreen>, especificamente _HomeScreenState.
}

class _HomeData {
  final List<Sede> sedes;
  final List<Reserva> reservas;

  const _HomeData(this.sedes, this.reservas);

  Reserva? get nextReservation {
    final active = reservas.where((r) => r.isActive).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return active.isEmpty ? null : active.first;
  }

  List<String> get notifications => [
    for (final r in reservas.where((r) => r.isActive).take(3))
      'Reserva confirmada: ${r.cancha}, ${r.sede}, ${r.fechaLabel} ${r.horario}.',
  ];
}

class _HomeScreenState extends State<HomeScreen> {
  static const _filters = ['Todos', 'Futbol', 'Tenis', 'Golf'];

  final _store = ProfileStore.instance;
  late Future<_HomeData> _future;
  bool _profileMenuOpen = false;
  int _selectedIndex = 0;
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    // TEMP-DEBUG-START: borrar al terminar de probar /device-tokens
    PushService.init().then((t) async {
      if (t == null) return;
      await ApiClient.instance.registerDeviceToken(t);
      debugPrint('registered: $t');
      await ApiClient.instance.deleteDeviceToken(t);
      debugPrint('deleted');
    });
    // TEMP-DEBUG-END
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      ApiClient.instance.getSedes(),
      ApiClient.instance.getReservas(),
    ]);
    return _HomeData(results[0] as List<Sede>, results[1] as List<Reserva>);
  }

  void _reload() => setState(() => _future = _load());

  void _goToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _profileMenuOpen = false;
      // Al volver a Inicio se refrescan las reservas (pudo reservar o cancelar en otra pestana).
      if (index == 0) _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final profile = _store.profile;
        if (profile == null) return const Scaffold(body: LoadingView());
        return _buildScaffold(profile);
      },
    );
  }

  Widget _buildScaffold(UserProfile profile) {
    final email = FirebaseAuth.instance.currentUser?.email ?? profile.email;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          switch (_selectedIndex) {
            0 => _HomeContent(
              firstName: profile.firstName,
              initials: profile.initials,
              future: _future,
              onRetry: _reload,
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) =>
                  setState(() => _selectedFilter = filter),
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
              profile: profile,
              email: email,
              onClose: () => setState(() => _profileMenuOpen = false),
              onOpenProfile: () => _goToTab(3),
              onOpenReservas: () => _goToTab(2),
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
          onTap: _goToTab,
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
  final Future<_HomeData> future;
  final VoidCallback onRetry;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onAvatarTap;

  const _HomeContent({
    required this.firstName,
    required this.initials,
    required this.future,
    required this.onRetry,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final done = snapshot.connectionState == ConnectionState.done;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                firstName: firstName,
                initials: initials,
                notifications: data?.notifications ?? const [],
                onAvatarTap: onAvatarTap,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: !done
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: LoadingView(),
                      )
                    : snapshot.hasError
                    ? ErrorRetry(message: '${snapshot.error}', onRetry: onRetry)
                    : _buildBody(data!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(_HomeData data) {
    final filteredSedes = selectedFilter == 'Todos'
        ? data.sedes
        : data.sedes.where((s) => s.sports.contains(selectedFilter)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NextReservationCard(reservation: data.nextReservation),
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
          const AssetImageWithFallback('assets/images/cancha-tenis.jpg'),
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
  final Reserva? reservation;

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
                  reservation?.cancha ?? 'Sin reservas próximas',
                  style: TextStyle(
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  reservation == null
                      ? 'Elegí una sede para reservar'
                      : '${reservation!.sede} · ${reservation!.fechaLabel}, ${reservation!.horario}',
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
    if (sedes.isEmpty) {
      return Text(
        'No hay sedes para este deporte.',
        style: TextStyle(color: Colors.grey[500]),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sedes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final sede = sedes[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => SedeScreen(sede: sede)),
            ),
            child: Container(
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
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenuOverlay extends StatelessWidget {
  final UserProfile profile;
  final String email;
  final VoidCallback onClose;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenReservas;

  const _ProfileMenuOverlay({
    required this.profile,
    required this.email,
    required this.onClose,
    required this.onOpenProfile,
    required this.onOpenReservas,
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
                        profile.initials,
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
                            profile.fullName,
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
                  'Apellido: ${profile.lastName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'DNI: ${formatDni(profile.dni)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'email: $email',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nac.: ${profile.birthDateLabel}',
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
                    onPressed: onOpenProfile,
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
                    onPressed: onOpenReservas,
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
