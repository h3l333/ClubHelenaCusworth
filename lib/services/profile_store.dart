import 'package:flutter/foundation.dart';

import '../user_profile.dart';
import 'api_client.dart';

enum ProfileStatus { idle, loading, ready, notFound, error, registering }

// Perfil del usuario actual (fila de Postgres). Lo consumen AuthGate y las pantallas.
class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final instance = ProfileStore._();

  ProfileStatus status = ProfileStatus.idle;
  UserProfile? profile;
  String? error;

  bool get isRegistering => status == ProfileStatus.registering;

  Future<void> load() async {
    status = ProfileStatus.loading;
    error = null;
    notifyListeners();
    try {
      profile = await ApiClient.instance.getMe();
      status = ProfileStatus.ready;
    } on ApiException catch (e) {
      // 404: autenticado en Firebase pero sin perfil en la base (ej. primer login con Google).
      status = e.isNotFound ? ProfileStatus.notFound : ProfileStatus.error;
      error = e.message;
    } catch (e) {
      status = ProfileStatus.error;
      error = describeError(e);
    }
    notifyListeners();
  }

  void setProfile(UserProfile value) {
    profile = value;
    status = ProfileStatus.ready;
    error = null;
    notifyListeners();
  }

  // Durante el registro Firebase emite el usuario antes de que exista el perfil;
  // AuthGate mantiene la pantalla de registro hasta que termine.
  void beginRegistration() {
    status = ProfileStatus.registering;
    notifyListeners();
  }

  void cancelRegistration() {
    status = ProfileStatus.idle;
    notifyListeners();
  }

  // Sin notificar: se invoca al desmontar la pantalla principal.
  void clear() {
    status = ProfileStatus.idle;
    profile = null;
    error = null;
  }
}
