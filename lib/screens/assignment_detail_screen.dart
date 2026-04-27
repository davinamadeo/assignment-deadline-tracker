import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'edit_assignment_screen.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Assignment assignment;
  final Course course;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final courseColor = Color(int.parse(course.colorHex));
    final a = assignment;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Assignment detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAssignmentScreen(
                    assignment: a,
                    course: course,
                  ),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: cs.error,
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: courseColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: courseColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: courseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(priority: a.priority),
                      const Spacer(),
                      _CountdownChip(assignment: a),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.name,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Deadline row
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Deadline',
              value: DateFormat('EEEE, d MMMM yyyy\nHH:mm').format(a.deadline),
            ),
            const SizedBox(height: 16),

            // Status row
            _InfoRow(
              icon: a.status == AssignmentStatus.done
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              label: 'Status',
              value: a.status == AssignmentStatus.done ? 'Completed' : 'Pending',
              valueColor: a.status == AssignmentStatus.done
                  ? Colors.green
                  : cs.onSurface,
            ),
            const SizedBox(height: 16),

            // Description
            if (a.description != null && a.description!.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: a.description!,
              ),
              const SizedBox(height: 16),
            ],

            // Photo attachment
            if (a.attachmentPath != null) ...[
              Text(
                'Attachment',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(a.attachmentPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: cs.onSurfaceVariant),
                          const SizedBox(height: 4),
                          Text('Photo not found',
                              style:
                              TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 8),

            // Mark done / restore button
            if (a.status == AssignmentStatus.pending)
              FilledButton.icon(
                onPressed: () => _markDone(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as done'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.green,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _restore(context),
                icon: const Icon(Icons.restore),
                label: const Text('Restore to pending'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDone(BuildContext context) async {
    await FirestoreService.instance.markDone(assignment.id!);
    await NotificationService.instance
        .cancelNotification(NotificationService.idFromDocId(assignment.id!));
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _restore(BuildContext context) async {
    await FirestoreService.instance.updateAssignment(
      assignment.copyWith(status: AssignmentStatus.pending),
    );
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('Are you sure you want to delete "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService.instance.deleteAssignment(assignment.id!);
      await NotificationService.instance
          .cancelNotification(NotificationService.idFromDocId(assignment.id!));
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final Priority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      Priority.high => ('High', Colors.red),
      Priority.medium => ('Medium', Colors.orange),
      Priority.low => ('Low', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final Assignment assignment;
  const _CountdownChip({required this.assignment});

  @override
  Widget build(BuildContext context) {
    if (assignment.status == AssignmentStatus.done) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Text('Done',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.green)),
      );
    }

    final label = assignment.countdownLabel;
    final isOverdue = assignment.isOverdue;
    final hours = assignment.timeLeft.inHours;
    final color =
    isOverdue ? Colors.red : hours < 24 ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}