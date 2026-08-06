class HteCompany {
  final String id;
  final String name;
  final String industry;
  final String address;
  final int availablePositions;
  final String email;
  final String phone;
  final String? website;
  final String description;
  final int availableSlots;

  const HteCompany({
    required this.id,
    required this.name,
    required this.industry,
    required this.address,
    required this.availablePositions,
    required this.email,
    required this.phone,
    this.website,
    required this.description,
    required this.availableSlots,
  });

  factory HteCompany.fromJson(Map<String, dynamic> json) {
    return HteCompany(
      id: json['id'].toString(),
      name: json['name'] as String,
      industry: json['industry'] as String,
      address: json['address'] as String,
      availablePositions: (json['available_positions'] as num).toInt(),
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String?,
      description: json['description'] as String? ?? '',
      availableSlots: (json['available_slots'] as num).toInt(),
    );
  }
}
