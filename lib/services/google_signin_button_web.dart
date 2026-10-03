import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

// En Web, google_sign_in no soporta authenticate(): hay que embeber el boton
// que renderiza Google Identity Services y esperar el resultado por stream.
Widget? buildGoogleSignInButton() => web_only.renderButton();
