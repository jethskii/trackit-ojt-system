/// The student's OJT company, as self-reported by the student via the
/// Confirm Company Details form -- independent of the HTE Directory (their
/// actual company may not even be listed there). This is the source of
/// truth for the Home/Profile company card.
class CompanyDetails {
  final String name;
  final String address;
  final String industry;
  final String supervisorName;
  final String contactNumber;

  /// The geofence center for Attendance clock in/out, captured by the
  /// student standing at the company (see "Set My Location"). Null until
  /// they've captured it -- there's no Admin module yet to set a verified
  /// location instead.
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  const CompanyDetails({
    required this.name,
    required this.address,
    required this.industry,
    required this.supervisorName,
    required this.contactNumber,
    this.latitude,
    this.longitude,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      name: json['name'] as String,
      address: json['address'] as String,
      industry: json['industry'] as String,
      supervisorName: json['supervisorName'] as String,
      contactNumber: json['contactNumber'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'industry': industry,
    'supervisorName': supervisorName,
    'contactNumber': contactNumber,
    'latitude': latitude,
    'longitude': longitude,
  };

  CompanyDetails copyWithLocation({
    required double latitude,
    required double longitude,
  }) {
    return CompanyDetails(
      name: name,
      address: address,
      industry: industry,
      supervisorName: supervisorName,
      contactNumber: contactNumber,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
