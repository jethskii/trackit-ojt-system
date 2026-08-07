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

  const CompanyDetails({
    required this.name,
    required this.address,
    required this.industry,
    required this.supervisorName,
    required this.contactNumber,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      name: json['name'] as String,
      address: json['address'] as String,
      industry: json['industry'] as String,
      supervisorName: json['supervisorName'] as String,
      contactNumber: json['contactNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'industry': industry,
    'supervisorName': supervisorName,
    'contactNumber': contactNumber,
  };
}
