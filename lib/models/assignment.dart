enum Priority { low, medium, high }

enum AssignmentStatus { pending, done }

class Assignment {
  final String? id; // Firestore document ID
  final String courseId;
  final String title;
  final String? description;
  final DateTime deadline;
  final Priority priority;
  final AssignmentStatus status;
  final String? attachmentPath;

  const Assignment({
    this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.deadline,
    this.priority = Priority.medium,
    this.status = AssignmentStatus.pending,
    this.attachmentPath,
  });

  bool get isOverdue =>
      status == AssignmentStatus.pending && deadline.isBefore(DateTime.now());

  Duration get timeLeft => deadline.difference(DateTime.now());

  String get countdownLabel {
    if (status == AssignmentStatus.done) return 'Done';
    final diff = timeLeft;
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  Assignment copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    DateTime? deadline,
    Priority? priority,
    AssignmentStatus? status,
    String? attachmentPath,
  }) =>
      Assignment(
        id: id ?? this.id,
        courseId: courseId ?? this.courseId,
        title: title ?? this.title,
        description: description ?? this.description,
        deadline: deadline ?? this.deadline,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        attachmentPath: attachmentPath ?? this.attachmentPath,
      );

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String(),
    'priority': priority.index,
    'status': status.index,
    'attachmentPath': attachmentPath,
  };

  factory Assignment.fromMap(String id, Map<String, dynamic> m) => Assignment(
    id: id,
    courseId: m['courseId'] as String,
    title: m['title'] as String,
    description: m['description'] as String?,
    deadline: DateTime.parse(m['deadline'] as String),
    priority: Priority.values[m['priority'] as int],
    status: AssignmentStatus.values[m['status'] as int],
    attachmentPath: m['attachmentPath'] as String?,
  );
}