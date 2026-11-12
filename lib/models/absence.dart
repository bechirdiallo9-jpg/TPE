class Absence {
  final String agentId;
  final DateTime date;
  final String reason;
  final String? replacementAgentId;

  Absence({
    required this.agentId,
    required this.date,
    required this.reason,
    this.replacementAgentId,
  });
}
