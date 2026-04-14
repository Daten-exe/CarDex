import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

// Importation des différents écrans et logiques de l'application
import 'cardex_provider.dart';
import 'screens/login_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/cardex_screen.dart';
import 'screens/map_screen.dart';

// Variable globale pour pouvoir utiliser les capteurs photo de l'appareil depuis n'importe quel fichier.
late List<CameraDescription> cameras;

/// Fonction main() : le point d'entrée unique de l'application Flutter.
/// Elle est asynchrone (async) car elle doit attendre l'initialisation de certains services.
void main() async {
  // S'assure que le pont entre le code Dart et le moteur natif Flutter est bien établi
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation des caméras physiques de l'appareil (avant, arrière, etc.)
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Erreur caméras: $e");
    cameras = []; // S'assure que l'app ne crashe pas si aucune caméra n'est trouvée (ex: émulateurs)
  }

  // 2. Initialisation de la connexion aux serveurs Supabase
  await Supabase.initialize(
    url: 'https://wyzpssuzycirpfzznota.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5enBzc3V6eWNpcnBmenpub3RhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5ODg4NTksImV4cCI6MjA5MTU2NDg1OX0.kGAzTa-WBr5nRqLDtG2MHZ67pl5iWuF-K-lMH8hhKnk',
  );

  // 3. Lancement de l'application en enveloppant l'app racine dans le Provider global.
  // Cela rend l'état "CarDexState" accessible partout dans l'arbre des widgets.
  runApp(
    ChangeNotifierProvider(
      create: (_) => CarDexState(),
      child: const CarDexApp(),
    ),
  );
}

/// Widget racine de l'application.
/// Il configure le nom de l'app, les couleurs globales (Thème) et l'écran de démarrage.
class CarDexApp extends StatelessWidget {
  const CarDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarDex Premium',
      debugShowCheckedModeBanner: false, // Retire la bannière "DEBUG" en haut à droite

      // --- CONFIGURATION DU THÈME DE L'APPLICATION ---
      // Met en place un thème sombre personnalisé évoquant un "Pokédex" avec des touches de vert.
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1411), // Fond principal (vert très sombre)

        // Définition de la palette de couleurs principale
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2EBD69),       // Couleur principale (Vert émeraude)
          secondary: Color(0xFFC7FF00),     // Couleur d'accentuation (Vert citron)
          surface: Color(0xFF1E2823),       // Couleur de fond des éléments (comme les cartes)
          background: const Color(0xFF0F1411),
          onSurface: Colors.white,          // Couleur du texte sur les surfaces
        ),

        // Style des textes par défaut dans toute l'application
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),

        // Style spécifique de la barre de navigation en bas de l'écran
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF171F1B),
          selectedItemColor: Color(0xFF2EBD69),
          unselectedItemColor: Colors.white24,
          showUnselectedLabels: false, // Cache le texte des onglets non sélectionnés
          type: BottomNavigationBarType.fixed,
        ),

        // Style des boutons flottants (Floating Action Button)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2EBD69),
          foregroundColor: Colors.black, // Icône noire sur fond vert
        ),
      ),

      // --- CHOIX DE L'ÉCRAN DE DÉPART (ROUTAGE) ---
      // Vérifie le token d'authentification enregistré sur l'appareil.
      // S'il n'y a personne de connecté, on affiche l'écran de connexion.
      // Sinon, on affiche directement l'application principale (MainNavigation).
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginScreen()
          : const MainNavigation(),
    );
  }
}

/// Écran "cadre" qui contient la barre de navigation du bas et permet
/// d'alterner entre les différentes pages de l'application (Scanner, Collection, Carte).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Garde en mémoire l'index (la page) actuellement sélectionné. 0 = Scanner.
  int _selectedIndex = 0;

  // Liste des widgets (écrans) correspondants à chaque onglet.
  final List<Widget> _screens = [
    const ScannerScreen(), // Index 0
    const CarDexScreen(),  // Index 1
    const MapScreen(),     // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le corps de l'écran affiche la vue correspondant à l'index sélectionné
      body: _screens[_selectedIndex],

      // La barre de navigation persistante en bas de l'écran
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        // Lorsque l'utilisateur clique sur un onglet, met à jour l'index et reconstruit la vue (setState)
        onTap: (index) => setState(() => _selectedIndex = index),

        // Définition des onglets avec leurs icônes (état normal et état actif)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'CarDex',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Carte',
          ),
        ],
      ),
    );
  }
}