import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Package pour formater joliment les dates
import 'dart:io'; // Nécessaire pour manipuler des fichiers locaux (les photos du téléphone)

import '../models.dart';
import '../cardex_provider.dart';

/// L'écran "Fiche Technique" d'une voiture.
/// C'est un StatelessWidget car son affichage ne change pas une fois qu'il est chargé.
/// Toutes les infos de la voiture lui sont passées directement au moment de l'ouverture.
class CarDetailScreen extends StatelessWidget {
  // La variable qui contient toutes les données de la voiture cliquée
  final Car car;

  // Le constructeur demande obligatoirement (required) qu'on lui fournisse une voiture
  const CarDetailScreen({super.key, required this.car});

  // --- WIDGET RÉUTILISABLE : LA BARRE DE STATISTIQUE ---

  /// Fonction qui génère visuellement une barre de progression (comme les stats d'un Pokémon).
  /// Au lieu de réécrire le même code 3 fois, on crée cette fonction qu'on appellera plus tard.
  Widget _buildStatBar(String label, int value, int maxValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligne le texte à gauche
      children: [
        // La ligne contenant le nom de la stat et les valeurs textuelles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Repousse les textes aux extrémités
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$value / $maxValue', style: const TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8), // Petit espace

        // La barre de progression colorée
        ClipRRect(
          borderRadius: BorderRadius.circular(10), // Arrondit les bords de la barre
          child: LinearProgressIndicator(
            // Le calcul du remplissage : doit être un pourcentage entre 0.0 et 1.0
            value: value / maxValue,
            backgroundColor: Colors.white10, // Couleur de la barre vide (gris transparent)
            valueColor: AlwaysStoppedAnimation<Color>(color), // Couleur de la partie remplie
            minHeight: 12, // Épaisseur de la barre
          ),
        ),
        const SizedBox(height: 16), // Espace avant la stat suivante
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Récupération des données locales (SQLite)
    // On demande au Provider si l'utilisateur possède cette voiture.
    // listen: false est utilisé car on veut juste lire l'info une fois au chargement de l'écran,
    // on n'a pas besoin que l'écran se redessine en direct.
    final capture = Provider.of<CarDexState>(context, listen: false).getCaptureDetails(car.id);

    // --- DONNÉES DE VOITURE (SIMULATION POUR LE POKÉDEX-STYLE) ---
    // La puissance réelle vient de l'IA (stockée dans l'objet car)
    int actualHP = car.horsepower;
    int maxHP = 1500; // Le plafond maximal théorique (ex: Bugatti Chiron) pour calculer la barre

    // Données fictives pour le moment (l'IA ne renvoie pas encore ces infos)
    int sampleMaxSpeed = 265;
    int maxMaxSpeed = 450;

    double sampleFuelEcon = 8.5; // en L/100km
    int maxFuelEcon = 20; // Consommation max (barre vide)

    return Scaffold(
      // --- ASTUCE DE DESIGN PREMIUM ---
      // Cela permet au fond de l'écran (le dégradé) de passer SOUS la barre de titre (AppBar),
      // au lieu que l'AppBar coupe l'écran avec une couleur unie.
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: Text('${car.brand} ${car.model}'),
        backgroundColor: Colors.transparent, // Rend l'AppBar invisible pour voir le dégradé dessous
        elevation: 0, // Retire la petite ombre sous l'AppBar
        iconTheme: const IconThemeData(color: Colors.white), // Flèche de retour en blanc
      ),

      // Permet de faire défiler la page si le contenu dépasse la taille de l'écran
      body: SingleChildScrollView(
        child: Container(
          // --- LE FOND DÉGRADÉ ---
          decoration: const BoxDecoration(
            // Un RadialGradient crée un effet de halo lumineux circulaire
            gradient: RadialGradient(
              colors: [
                Color(0xFF2EBD69), // Vert lumineux au centre du halo
                Color(0xFF0F1411), // Noir/Vert très sombre sur les bords
              ],
              // Le centre du halo est décalé vers le haut (là où se trouve la photo)
              center: Alignment(0.0, -0.8),
              radius: 1.2, // Taille du halo
              stops: [0.0, 1.0], // Transition douce entre les deux couleurs
            ),
          ),
          child: Column(
            children: [
              // Espace vide pour compenser l'AppBar transparente (sinon la photo serait sous l'heure du téléphone)
              const SizedBox(height: 100),

              // --- IMAGE DE LA VOITURE AVEC EFFET GLOW (NÉON) ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Création de l'effet d'ombre portée lumineuse (Néon)
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC7FF00).withOpacity(0.15), // Lueur vert citron légère
                      spreadRadius: 2, // Étend la lumière
                      blurRadius: 25, // Floute la lumière (plus c'est haut, plus c'est doux)
                      offset: const Offset(0, 10), // Décale l'ombre vers le bas
                    ),
                  ],
                ),
                // ClipRRect force l'image à respecter l'arrondi du Container (borderRadius: 20)
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  // LOGIQUE D'AFFICHAGE DE L'IMAGE
                  // Si l'URL commence par "http", c'est une image venant d'internet (Supabase)
                  child: car.imageUrl.startsWith('http')
                      ? Image.network(
                    car.imageUrl,
                    height: 250,
                    width: double.infinity, // Prend toute la largeur possible
                    fit: BoxFit.cover, // Recadre l'image pour qu'elle remplisse la zone sans se déformer
                    // Si l'image internet crash (pas de réseau), on affiche une icône brisée
                    errorBuilder: (context, error, stackTrace) => const SizedBox(height: 250, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white54))),
                  )
                  // Sinon, c'est un chemin de fichier local (une photo prise avec la caméra)
                      : Image.file(
                    File(car.imageUrl),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Pareil, sécurité si le fichier a été supprimé du téléphone
                    errorBuilder: (context, error, stackTrace) => const SizedBox(height: 250, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white54))),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Titre principal sous l'image
              Text(
                '${car.brand} ${car.model}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              // Petit sous-titre stylisé pour renforcer le thème "collection"
              const Text(
                'Véhicule Terrestre',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),

              const SizedBox(height: 30),

              // --- SECTION DES STATISTIQUES (LA FICHE TECHNIQUE) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2823), // Un fond gris/vert sombre pour détacher la boîte
                  // Arrondit uniquement les deux coins supérieurs
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Appel de notre fonction _buildStatBar créée tout en haut du fichier
                    _buildStatBar('Puissance (CV)', actualHP, maxHP, Colors.redAccent),
                    _buildStatBar('Vitesse Max (km/h)', sampleMaxSpeed, maxMaxSpeed, Colors.blueAccent),

                    // Logique inversée pour la consommation :
                    // Moins on consomme, plus la barre doit être remplie (car c'est positif).
                    // On fait donc maxEcon - sampleEcon pour afficher la barre dans le bon sens.
                    _buildStatBar('Consommation (L/100km)', maxFuelEcon - sampleFuelEcon.toInt(), maxFuelEcon, Colors.greenAccent),

                    // --- STATISTIQUE MONDIALE DE RARETÉ ---
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero, // Retire les marges par défaut
                      title: const Text('Rareté globale', style: TextStyle(fontWeight: FontWeight.bold)),
                      // Affiche combien de personnes sur l'appli ont scanné cette voiture
                      subtitle: Text('${car.captureCount} utilisateur(s) ont trouvé ce modèle'),
                      leading: const Icon(Icons.public, color: Color(0xFFC7FF00)), // Icône de planète
                    ),

                    // --- SECTION DÉTAILS DE LA CAPTURE PERSONNELLE ---
                    // Ce code ne s'affiche QUE si la variable "capture" n'est pas nulle
                    // (c'est-à-dire que l'utilisateur a scanné cette voiture lui-même)
                    if (capture != null) ...[
                      const Divider(color: Colors.white10, height: 30), // Ligne de séparation

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Détails de la rencontre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),

                      // Affichage de la date précise du scan
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        // DateFormat vient du package 'intl' pour transformer le DateTime en texte lisible
                        subtitle: Text(DateFormat('dd/MM/yyyy à HH:mm').format(capture.captureDate)),
                        leading: const Icon(Icons.calendar_today, color: Colors.white54),
                      ),

                      // Affichage du lieu (ou si c'était un scan manuel / IA)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lieu'),
                        subtitle: Text(capture.locationString),
                        leading: const Icon(Icons.location_on, color: Colors.white54),
                      ),
                    ],

                    // Espace final très important en bas pour éviter que le dernier texte
                    // ne soit caché par la barre de navigation de l'écran principal
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}