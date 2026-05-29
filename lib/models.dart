class Car {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int horsepower;
  final String imageUrl;
  final int captureCount;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.horsepower,
    required this.imageUrl,
    this.captureCount = 1,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? 'Inconnue',
      model: json['model']?.toString() ?? 'Inconnu',
      year: (json['year'] as num?)?.toInt() ?? 2024,
      horsepower: (json['horsepower'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      captureCount: (json['capture_count'] as num?)?.toInt() ?? 1,
    );
  }
}

class CapturedCar {
  final String id;
  final String carId;
  final DateTime captureDate;
  final String locationString;

  CapturedCar({
    required this.id,
    required this.carId,
    required this.captureDate,
    required this.locationString,
  });
}
