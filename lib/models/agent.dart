class Agent {
  final String id;
  final String firstName;
  final String lastInitial;
  final String phone;

  Agent({
    required this.id,
    required this.firstName,
    required this.lastInitial,
    required this.phone,
  });

  String get displayName => '$firstName $lastInitial.';

  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: j['id'],
        firstName: j['firstName'],
        lastInitial: j['lastInitial'],
        phone: j['phone'],
      );
}
