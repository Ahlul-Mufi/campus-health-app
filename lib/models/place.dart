class Place {
  final int id;
  final int categoryId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? phone;
  final double? rating;
  final String? googleMapsUrl;
  final String? categoryName;
  final String? openingHours;
  final String? foto;

  String? get effectiveFotoUrl => foto;

  Place({
    required this.id,
    required this.categoryId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.phone,
    this.rating,
    this.googleMapsUrl,
    this.categoryName,
    this.openingHours,
    this.foto,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      address: json['address'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      description: json['description'],
      phone: json['phone'],
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      googleMapsUrl: json['google_maps_url'],
      categoryName: json['category_name'],
      openingHours: json['opening_hours'],
      foto: json['foto'],
    );
  }
}