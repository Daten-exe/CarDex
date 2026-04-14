/// Ce fichier définit les structures de données utilisées dans l'application.
/// Il permet de manipuler des objets Dart structurés au lieu de simples dictionnaires (Map).

class Car {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int horsepower;
  final String imageUrl;
  final int captureCount; // Le nombre de fois que cette voiture a été capturée globalement

  /// Constructeur de la classe Car.
  /// Les accolades {} indiquent que les paramètres sont nommés.
  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.horsepower,
    required this.imageUrl,
    this.captureCount = 1, // Vaut 1 par défaut si non précisé lors de la création
  });

  /// Constructeur "factory" (usine) qui permet de créer un objet Car
  /// à partir d'un format JSON (un dictionnaire de données).
  /// Très utile lors de la récupération de données depuis la base de données Supabase.
  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      horsepower: json['horsepower'],
      imageUrl: json['image_url'],
      captureCount: json['capture_count'] ?? 1, // Utilise 1 si 'capture_count' est null
    );
  }
}

class CapturedCar {
  final String id;
  final String carId; // L'identifiant de la voiture scannée (lien avec la classe Car)
  final DateTime captureDate; // La date et l'heure exactes du scan
  final String locationString; // Le lieu où la capture a été effectuée

  /// Constructeur de la classe CapturedCar.
  CapturedCar({
    required this.id,
    required this.carId,
    required this.captureDate,
    required this.locationString,
  });
}