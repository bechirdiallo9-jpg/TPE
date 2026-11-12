enum InterventionStatus { planned, enRoute, onSite, done }

class TaskItem {
  final String label;
  bool done;

  TaskItem({required this.label, this.done = false});
}

class Intervention {
  final String id;
  final String agentId;
  final String siteId;
  final DateTime plannedStart;
  final Duration plannedDuration;
  InterventionStatus status;
  DateTime? arrivedAt;
  DateTime? leftAt;
  final List<TaskItem> tasks;
  final List<String> photosBefore; // chemins de fichiers ou d'assets
  final List<String> photosAfter;
  String comment;

  Intervention({
    required this.id,
    required this.agentId,
    required this.siteId,
    required this.plannedStart,
    required this.plannedDuration,
    required this.status,
    this.arrivedAt,
    this.leftAt,
    required this.tasks,
    required this.photosBefore,
    required this.photosAfter,
    this.comment = '',
  });

  bool get isLate =>
      status == InterventionStatus.planned &&
      DateTime.now().isAfter(plannedStart.add(const Duration(minutes: 15)));

  Duration? get timeOnSite =>
      (arrivedAt != null && leftAt != null) ? leftAt!.difference(arrivedAt!) : null;
}
