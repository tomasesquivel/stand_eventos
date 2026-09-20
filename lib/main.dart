import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/pantalla_principal.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nizeabxzqytvqfvyftci.supabase.co', 
    publishableKey: 'sb_publishable_z6cv9LwdC_Pd40x0N562nA_jzBAEtts',
  );
  runApp(const StandEventosApp());
}

class StandEventosApp extends StatelessWidget {
  const StandEventosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stand de Eventos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.cyan,
        ),
        fontFamily: 'Courier',
      ),
      home: const PantallaPrincipal(),
    );
  }
}

