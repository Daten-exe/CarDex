import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../cardex_provider.dart';
import '../models.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    // On demande au provider d'allumer la caméra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CarDexState>(context, listen: false).initCamera();
    });
  }

  // --- GESTION DES ACTIONS ---

  Future<void> _handleScan(BuildContext context, {bool fromGallery = false}) async {
    final state = Provider.of<CarDexState>(context, listen: false);
    XFile? photo;

    try {
      if (fromGallery) {
        photo = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 60, // Compression pour éviter l'erreur 503 de Gemini
          maxWidth: 1024,
        );
      } else {
        photo = await state.cameraController?.takePicture();
      }

      if (photo != null) {
        // L'IA travaille dans le Provider
        final car = await state.analyzeCarImage(photo);
        if (car != null && mounted) {
          _showSuccessDialog(context, car);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // On "écoute" le provider. Dès que notifyListeners() est appelé, build() se relance.
    final state = context.watch<CarDexState>();

    // Si la caméra n'est pas prête
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1411),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2EBD69))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1411),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Caméra et Viseur
          _buildScannerOverlay(state.cameraController!),

          // 2. Écran de chargement IA (géré par le Provider)
          if (state.isScanningAI)
            Container(
              color: const Color(0xFF0F1411).withOpacity(0.85),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFC7FF00)),
                  SizedBox(height: 24),
                  Text("Analyse en cours...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // 3. Boutons
          Positioned(
            bottom: 110, left: 0, right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                heroTag: 'gallery_btn',
                onPressed: state.isScanningAI ? null : () => _handleScan(context, fromGallery: true),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Galerie"),
                backgroundColor: const Color(0xFF1E2823),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                heroTag: 'camera_btn',
                onPressed: state.isScanningAI ? null : () => _handleScan(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scanner maintenant"),
                backgroundColor: const Color(0xFF2EBD69),
                foregroundColor: Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS UI (Sans logique) ---

  Widget _buildScannerOverlay(CameraController controller) {
    return IgnorePointer(
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
            child: CameraPreview(controller),
          ),
          Center(
            child: Container(
              height: 300, width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(top: 10, left: 10, child: _buildCorner(isTopLeft: true)),
                  Positioned(top: 10, right: 10, child: _buildCorner(isTopRight: true)),
                  Positioned(bottom: 10, left: 10, child: _buildCorner(isBottomLeft: true)),
                  Positioned(bottom: 10, right: 10, child: _buildCorner(isBottomRight: true)),
                  _buildScanningBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({bool isTopLeft = false, bool isBottomLeft = false, bool isTopRight = false, bool isBottomRight = false}) {
    const color = Color(0xFFC7FF00);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTopLeft || isTopRight ? const BorderSide(color: color, width: 4) : BorderSide.none,
          left: isTopLeft || isBottomLeft ? const BorderSide(color: color, width: 4) : BorderSide.none,
          right: isTopRight || isBottomRight ? const BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: isBottomLeft || isBottomRight ? const BorderSide(color: color, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTopLeft ? const Radius.circular(12) : Radius.zero,
          topRight: isTopRight ? const Radius.circular(12) : Radius.zero,
          bottomLeft: isBottomLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: isBottomRight ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildScanningBar() {
    return Center(
      child: Container(
        height: 2, width: 260,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFC7FF00).withOpacity(0), const Color(0xFFC7FF00), const Color(0xFFC7FF00).withOpacity(0)]),
          boxShadow: [BoxShadow(color: const Color(0xFFC7FF00).withOpacity(0.8), spreadRadius: 2, blurRadius: 10)],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Car car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2823),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              // CORRECTION DU BUG DE TAILLE : Utilisation de MediaQuery au lieu de double.infinity
              child: car.imageUrl.startsWith('http')
                  ? Image.network(car.imageUrl, height: 140, width: MediaQuery.of(context).size.width, fit: BoxFit.cover)
                  : Image.file(File(car.imageUrl), height: 140, width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('${car.brand} ${car.model}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
            const SizedBox(height: 8),
            Text('${car.horsepower} CV • ${car.year}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2EBD69), foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: const Text('Génial !'),
            )
          ],
        ),
      ),
    );
  }
}