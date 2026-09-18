import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart'; // Archivo generado por `flutterfire configure`.

import 'home_screen.dart';
import 'login_screen.dart';

// Punto de entrada para la aplicación:
Future<void> main() async {
  // La siguiente línea de código se asegura que el widget binding de Flutter esté inicializado antes de que se inicie
  // Firebase:
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAuth.instance.signOut();

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
          seedColor: Colors.lime,
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(), // Este atributo se implementa en el flujo de autenticación.
    );
  }
}

// Placeholder:
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Actúa como el "esqueleto" de una pantalla individual. Contiene atributos tales como `AppBar` y `body`.
      // Una clase StreamBuilder en Flutter se usa para estar a la escucha
      // de un stream de datos y reconstruir su subarbol de widgets cuando
      // el stream emite nuevos datos.
      stream: FirebaseAuth.instance.authStateChanges(),
      // authStateChanges() emite dos valores posibles:
      //  - null en caso de que este deslogueado
      //  - User en el caso de un usuario válido logueado
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
