import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../models.dart';
import '../cardex_provider.dart';
import 'car_detail_screen.dart';
import 'login_screen.dart';

class CarDexScreen extends StatelessWidget {
  const CarDexScreen({super.key});

  /// Gère la déconnexion de l'utilisateur.
  void _signOut(BuildContext context) async {
    try {
      // 1. Vide les listes en mémoire pour ne pas que le prochain compte voit les données du précédent
      Provider.of<CarDexState>(context, listen: false).clearState();

      // 2. Déconnexion officielle de Supabase
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      // 3. Vide l'historique de navigation et renvoie à la page Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Supprime toutes les pages précédentes
      );
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute le Provider. Dès que availableCars ou myCaptures change, cet écran se redessine.
    final state = Provider.of<CarDexState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon CarDex (${state.myCaptures.length})'), // Affiche le nombre de captures
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2EBD69)))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        // Configure la grille : 2 colonnes
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
        ),
        itemCount: state.availableCars.length, // Le nombre total de voitures dans le monde
        itemBuilder: (context, index) {
          final car = state.availableCars[index];
          // Vérifie si l'utilisateur possède cette voiture
          final isCaptured = state.hasCaptured(car.id);

          return GestureDetector(
            // On ne peut cliquer pour voir les détails QUE si on a capturé la voiture
            onTap: isCaptured ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => CarDetailScreen(car: car))) : null,
            child: Card(
              clipBehavior: Clip.antiAlias,
              // Fond différent si capturé ou non
              color: isCaptured ? const Color(0xFF1E2823) : Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Expanded(
                    child: Opacity(
                      // Si non capturé, l'image est à 20% d'opacité (effet sombre/verrouillé)
                      opacity: isCaptured ? 1 : 0.2,
                      child: car.imageUrl.startsWith('http')
                          ? Image.network(car.imageUrl, fit: BoxFit.cover, width: double.infinity)
                          : Image.file(File(car.imageUrl), fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Masque le nom si la voiture n'est pas encore capturée
                    child: Text(isCaptured ? car.model : '???', style: const TextStyle(fontWeight: FontWeight.bold)),
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