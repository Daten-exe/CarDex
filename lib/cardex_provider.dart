import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import 'config.dart';
import 'models.dart';

const _uuid = Uuid();

class CarDexState extends ChangeNotifier {
  final List<CameraDescription> cameras;

  List<Car> _availableCars = [];
  List<CapturedCar> _myCaptures = [];
  bool _isLoading = true;

  CameraController? _cameraController;
  bool _isScanningAI = false;

  List<Car> get availableCars => _availableCars;
  List<CapturedCar> get myCaptures => _myCaptures;
  bool get isLoading => _isLoading;
  bool get isScanningAI => _isScanningAI;
  CameraController? get cameraController => _cameraController;
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  CarDexState({required this.cameras}) {
    initApp();
  }

  Future<void> initApp() async {
    _isLoading = true;
    notifyListeners();
    await _fetchCarsFromSupabase();
    await _loadCapturesFromSupabase();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> initCamera() async {
    if (cameras.isEmpty) return;
    await _cameraController?.dispose();
    _cameraController = null;
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<Car?> analyzeCarImage(XFile photo) async {
    _isScanningAI = true;
    notifyListeners();
    try {
      final bytes = await File(photo.path).readAsBytes();
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final prompt = TextPart(
        "Analyse cette image de voiture. Répond STRICTEMENT avec un JSON valide : "
        "brand (string), model (string), year (int), horsepower (int).",
      );
      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', bytes)])
      ]);
      if (response.text == null) return null;
      final data = jsonDecode(response.text!);
      final brand = data['brand']?.toString() ?? 'Inconnue';
      final modelName = data['model']?.toString() ?? 'Inconnu';
      final year = int.tryParse(data['year'].toString()) ?? 2024;
      final horsepower = int.tryParse(data['horsepower'].toString()) ?? 0;
      Car? carToCapture;
      try {
        carToCapture = _availableCars.firstWhere(
          (c) =>
              c.brand.toLowerCase() == brand.toLowerCase() &&
              c.model.toLowerCase() == modelName.toLowerCase(),
        );
        await incrementGlobalCapture(carToCapture);
      } catch (_) {
        carToCapture = Car(
          id: _uuid.v4(),
          brand: brand,
          model: modelName,
          year: year,
          horsepower: horsepower,
          imageUrl: photo.path,
          captureCount: 1,
        );
        await addNewCarToDatabase(carToCapture);
      }
      await addCapture(carToCapture.id);
      _isScanningAI = false;
      notifyListeners();
      return carToCapture;
    } catch (e) {
      debugPrint("Erreur IA: $e");
      _isScanningAI = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _fetchCarsFromSupabase() async {
    try {
      final response = await Supabase.instance.client.from('cars').select();
      _availableCars = response.map((json) => Car.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur Fetch Cars: $e');
    }
  }

  Future<void> addNewCarToDatabase(Car car) async {
    try {
      await Supabase.instance.client.from('cars').insert({
        'id': car.id, 'brand': car.brand, 'model': car.model,
        'year': car.year, 'horsepower': car.horsepower,
        'image_url': car.imageUrl, 'capture_count': 1,
      });
      _availableCars.add(car);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur Insert Car: $e');
    }
  }

  Future<void> incrementGlobalCapture(Car car) async {
    try {
      final newCount = car.captureCount + 1;
      await Supabase.instance.client
          .from('cars')
          .update({'capture_count': newCount})
          .eq('id', car.id);
      final index = _availableCars.indexWhere((c) => c.id == car.id);
      if (index != -1) {
        _availableCars[index] = Car(
          id: car.id, brand: car.brand, model: car.model,
          year: car.year, horsepower: car.horsepower,
          imageUrl: car.imageUrl, captureCount: newCount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur Update Count: $e');
    }
  }

  Future<void> _loadCapturesFromSupabase() async {
    if (currentUserId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('captures')
          .select()
          .eq('userId', currentUserId!);
      _myCaptures = response
          .map((map) => CapturedCar(
                id: map['id'], carId: map['carId'],
                captureDate: DateTime.parse(map['captureDate']),
                locationString: map['locationString'],
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur Fetch Captures Supabase: $e');
    }
  }

  bool hasCaptured(String carId) => _myCaptures.any((c) => c.carId == carId);

  Future<void> addCapture(String carId) async {
    if (currentUserId == null || hasCaptured(carId)) return;
    final newCapture = CapturedCar(
      id: _uuid.v4(), carId: carId,
      captureDate: DateTime.now(), locationString: 'Scan IA (Cloud)',
    );
    _myCaptures.insert(0, newCapture);
    notifyListeners();
    try {
      await Supabase.instance.client.from('captures').insert({
        'id': newCapture.id, 'carId': newCapture.carId,
        'userId': currentUserId,
        'captureDate': newCapture.captureDate.toIso8601String(),
        'locationString': newCapture.locationString,
      });
    } catch (e) {
      _myCaptures.removeWhere((c) => c.id == newCapture.id);
      notifyListeners();
      debugPrint('Erreur Insert Capture Supabase: $e');
      rethrow;
    }
  }

  CapturedCar? getCaptureDetails(String carId) {
    try {
      return _myCaptures.firstWhere((c) => c.carId == carId);
    } catch (_) {
      return null;
    }
  }

  void clearState() {
    _myCaptures = [];
    _isLoading = true;
    notifyListeners();
  }
}
