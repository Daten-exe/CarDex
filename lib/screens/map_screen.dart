import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../cardex_provider.dart';
import '../models.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupère l'état global
    final state = Provider.of<CarDexState>(context);
    // Isole la liste des captures de l'utilisateur
    final captures = state.myCaptures;

    return Scaffold(
      appBar: AppBar(title: const Text('Carte des trouvailles')),
      // Si la liste est vide, on affiche un texte central
      body: captures.isEmpty
          ? const Center(child: Text('Aucun véhicule géolocalisé pour le moment.'))
      // Sinon, on génère une liste déroulante (ListView)
          : ListView.builder(
        itemCount: captures.length,
        itemBuilder: (context, index) {
          final cap = captures[index]; // L'objet capture SQLite

          // L'objet capture ne contient que l'ID de la voiture.
          // Il faut aller chercher les vraies infos (marque, modèle) dans le catalogue.
          final car = state.availableCars.firstWhere(
                (c) => c.id == cap.carId,
            // orElse est une sécurité : si la voiture a été supprimée du serveur,
            // on évite un crash en renvoyant une voiture "vide" par défaut.
            orElse: () => Car(id: '', brand: 'Voiture', model: 'Inconnue', year: 2024, horsepower: 0, imageUrl: ''),
          );

          // Si on n'a pas trouvé la voiture (l'ID est vide), on retourne une boîte invisible (SizedBox.shrink)
          if (car.id.isEmpty) return const SizedBox.shrink();

          // Affiche la ligne d'information
          return ListTile(
            leading: const Icon(Icons.location_pin, color: Colors.redAccent),
            title: Text('${car.brand} ${car.model}'),
            subtitle: Text(cap.locationString),
            // Formate la date au format court
            trailing: Text(DateFormat('dd/MM/yy').format(cap.captureDate)),
          );
        },
      ),
    );
  }
}