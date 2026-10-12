import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_colors.dart';

import 'firebase_options.dart'; // Archivo generado por `flutterfire configure`.

import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'services/profile_store.dart';
import 'widgets/common.dart';

// Punto de entrada para la aplicación:
Future<void> main() async {
  // La siguiente línea de código se asegura que el widget binding de Flutter esté inicializado antes de que se inicie
  // Firebase:
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // MaterialApp actua de "wrapper" o "envoltorio" para la aplicación. Se suele tener solo una instancia hacia la raíz del
      // árbol de widgets. Configura apariencia y routing (por ejemplo, con el atributo `home`).
      title: 'Sports club.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// Decide que pantalla mostrar segun el estado de autenticacion de Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Una clase StreamBuilder en Flutter se usa para estar a la escucha
      // de un stream de datos y reconstruir su subarbol de widgets cuando
      // el stream emite nuevos datos.
      stream: FirebaseAuth.instance.authStateChanges(),
      // authStateChanges() emite dos valores posibles:
      //  - null en caso de que este deslogueado
      //  - User en el caso de un usuario válido logueado
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }

        return ListenableBuilder(
          listenable: ProfileStore.instance,
          builder: (context, _) {
            // Mientras se registra, Firebase ya emitio el usuario pero el perfil todavia
            // no existe: se mantiene LoginScreen para no perder su estado ni sus errores.
            if (ProfileStore.instance.isRegistering || !snapshot.hasData) {
              return const LoginScreen();
            }
            return const ProfileGate();
          },
        );
      },
    );
  }
}

// Con un usuario autenticado, carga su perfil desde el backend antes de mostrar la app.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _store = ProfileStore.instance;

  @override
  void dispose() {
    _store.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        switch (_store.status) {
          case ProfileStatus.ready:
            return const HomeScreen();
          case ProfileStatus.notFound:
            return const CompleteProfileScreen();
          case ProfileStatus.error:
            return Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ErrorRetry(
                        message: _store.error ?? 'No se pudo cargar tu perfil.',
                        onRetry: _store.load,
                      ),
                    ),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            );
          case ProfileStatus.idle:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _store.status == ProfileStatus.idle) _store.load();
            });
            return const Scaffold(body: LoadingView());
          case ProfileStatus.loading:
          case ProfileStatus.registering:
            return const Scaffold(body: LoadingView());
        }
      },
    );
  }
}
