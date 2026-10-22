class Accommodation {
  final String id, title, imageUrl, type, description;
  final String landlordId, listingId, address, amenities, availability;
  final double monthlyPrice;
  final int totalBeds, availableBeds;
  const Accommodation({
    required this.id,
    required this.title,
    required this.monthlyPrice,
    required this.imageUrl,
    required this.type,
    this.description = '',
    this.landlordId = '',
    this.listingId = '',
    this.address = '',
    this.amenities = '',
    this.availability = 'Available',
    this.totalBeds = 0,
    this.availableBeds = 0,
  });

  factory Accommodation.fromJson(Map<String, dynamic> row) {
    final listing = row['listing'] as Map<String, dynamic>? ?? {};
    return Accommodation(
      id: row['roomid'] as String,
      landlordId: row['landlordid'] as String? ?? '',
      listingId: row['listingid'] as String? ?? '',
      title: listing['title'] as String? ?? 'Accommodation',
      address: listing['address'] as String? ?? '',
      description: listing['description'] as String? ?? '',
      amenities: listing['amenities'] as String? ?? '',
      monthlyPrice: (row['monthlyrent'] as num).toDouble(),
      type: row['roomtype'] as String? ?? '',
      imageUrl: row['image'] as String? ?? '',
      availability: row['availabilitystatus'] as String? ?? '',
      totalBeds: (row['totalbeds'] as num?)?.toInt() ?? 0,
      availableBeds: (row['availablebeds'] as num?)?.toInt() ?? 0,
    );
  }
  bool get available => availability == 'Available' && availableBeds > 0;
  String get availabilityLabel {
    if (availability != 'Available') return 'Applications closed';
    if (totalBeds == 0) return 'Awaiting landlord bed setup';
    if (availableBeds == 0) return 'Fully occupied';
    return '$availableBeds of $totalBeds beds available';
  }

  String get displayName =>
      '$title · $type · R ${monthlyPrice.toStringAsFixed(2)}';
}
