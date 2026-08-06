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
}
