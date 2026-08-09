import 'hte_company_contact.dart';

/// An HTE (Host Training Establishment) in the directory -- fully
/// Admin-managed, students only ever read this. Purely a factual
/// reference/recommendation list: no application, acceptance, or
/// slot-tracking fields exist here by design.
class HteCompany {
  final int id;
  final String name;
  final String industry;
  final String location;
  final String address;
  final String email;
  final String? website;
  final DateTime? dateAccredited;
  final List<HteCompanyContact> contacts;

  const HteCompany({
    required this.id,
    required this.name,
    required this.industry,
    required this.location,
    required this.address,
    required this.email,
    this.website,
    this.dateAccredited,
    this.contacts = const [],
  });

  factory HteCompany.fromJson(Map<String, dynamic> json) {
    final contactsJson = json['contacts'] as List<dynamic>? ?? const [];
    return HteCompany(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      industry: json['industry'] as String,
      location: json['location'] as String? ?? '',
      address: json['address'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      dateAccredited: json['dateAccredited'] != null
          ? DateTime.parse(json['dateAccredited'] as String)
          : null,
      contacts: contactsJson
          .map((c) => HteCompanyContact.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
