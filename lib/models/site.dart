class Site {
  final String id;
  final String clientName;
  final String address;
  final String city;
  final String instructions; // consignes : code d'accès, local matériel...

  Site({
    required this.id,
    required this.clientName,
    required this.address,
    required this.city,
    required this.instructions,
  });

  String get fullAddress => '$address, $city';

  factory Site.fromJson(Map<String, dynamic> j) => Site(
        id: j['id'],
        clientName: j['clientName'],
        address: j['address'],
        city: j['city'],
        instructions: j['instructions'],
      );
}
