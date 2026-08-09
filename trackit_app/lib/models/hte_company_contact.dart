/// One contact person for an HTE company. [id] is null for a contact just
/// added in the Admin form (not yet saved) -- purely a local list key, the
/// server assigns the real id on save.
class HteCompanyContact {
  final int? id;
  final String name;
  final String phone;

  const HteCompanyContact({this.id, required this.name, required this.phone});

  factory HteCompanyContact.fromJson(Map<String, dynamic> json) {
    return HteCompanyContact(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}
