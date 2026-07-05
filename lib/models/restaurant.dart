/// A restaurant as returned by the Yelp Fusion API.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.rating,
    this.price,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.alias,
    this.isClosed,
    this.reviewCount,
    this.url,
    this.imageUrl,
    this.address,
    this.city,
    this.state,
    this.zip,
  });

  final String id;
  final String name;
  final double? rating;
  final String? price;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String? alias;
  final bool? isClosed;
  final int? reviewCount;
  final String? url;
  final String? imageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>? ?? const {};
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      rating: (json['rating'] as num?)?.toDouble(),
      price: json['price'] as String?,
      phone: json['phone'] as String?,
      latitude: (coordinates['latitude'] as num?)?.toDouble(),
      longitude: (coordinates['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distance'] as num?)?.toDouble(),
      alias: json['alias'] as String?,
      isClosed: json['is_closed'] as bool?,
      reviewCount: json['review_count'] as int?,
      url: json['url'] as String?,
      imageUrl: json['image_url'] as String?,
      address: location['address1'] as String?,
      city: location['city'] as String?,
      state: location['state'] as String?,
      zip: location['zip_code'] as String?,
    );
  }

  /// Minimal representation persisted to Firestore (saved list / history).
  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'rating': rating,
        'price': price,
        'imageUrl': imageUrl,
        'address': fullAddress,
      };

  String get fullAddress =>
      [address, city, state, zip].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  double get distanceMiles => (distanceMeters ?? 0) / 1609.344;
}
