import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = FirestoreService.instance;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await _db.getCourses();
    if (mounted) setState(() => _courses = courses);
  }

  Future<void> _restoreAssignment(Assignment a) async {
    await _db.updateAssignment(a.copyWith(status: AssignmentStatus.pending));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('↩️ Assignment restored to pending')),
      );
    }
  }

  Future<void> _deleteAssignment(Assignment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('"${a.title}" will be removed from history.'),
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
    if (confirm == true) await _db.deleteAssignment(a.id!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: StreamBuilder<List<Assignment>>(
        stream: _db.watchDoneAssignments(),
        builder: (context, snap) {
          final assignments =
          snap.hasError ? <Assignment>[] : (snap.data ?? <Assignment>[]);
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                title: const Text(
                  'History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(height: 1, color: cs.outlineVariant),
                ),
              ),

              if (loading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (assignments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 72,
                              color: cs.onSurfaceVariant.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No completed assignments yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mark assignments as done and they'll appear here.",
                          textAlign: TextAlign.center,
                            style:
                            TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '${assignments.length} completed',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final a = assignments[i];
                          final course = _courses.firstWhere(
                                (c) => c.id == a.courseId,
                            orElse: () => const Course(
                              name: 'Unknown',
                              code: '?',
                              colorHex: '0xFF9E9E9E',
                            ),
                          );
                          return _HistoryCard(
                            assignment: a,
                            course: course,
                            onRestore: () => _restoreAssignment(a),
                            onDelete: () => _deleteAssignment(a),
                          );
                        },
                        childCount: assignments.length,
                      ),
                    ),
                  ),
                ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Assignment assignment;
  final Course course;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.assignment,
    required this.course,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final courseColor = Color(int.parse(course.colorHex));
    final a = assignment;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Done checkmark stripe
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: courseColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.code.isNotEmpty ? course.code : '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: courseColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✓ Done',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: cs.onSurface.withOpacity(0.4),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Was due: ${DateFormat('EEE, d MMM · HH:mm').format(a.deadline)}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, size: 20),
                  color: cs.primary,
                  tooltip: 'Restore to pending',
                  onPressed: onRestore,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: cs.error,
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}