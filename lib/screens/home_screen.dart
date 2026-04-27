import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'add_assignment_screen.dart';
import 'assignment_detail_screen.dart';
import 'course_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = FirestoreService.instance;
  final _auth = AuthService();

  String? _selectedCourseId;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    NotificationService.instance.requestPermission();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await _db.getCourses();
    if (mounted) setState(() => _courses = courses);
  }

  Future<void> _markDone(Assignment a) async {
    await _db.markDone(a.id!);
    await NotificationService.instance.cancelNotification(a.id.hashCode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${a.title}" marked as done'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _db.updateAssignment(
              a.copyWith(status: AssignmentStatus.pending),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAssignment(Assignment a) async {
    await _db.deleteAssignment(a.id!);
    await NotificationService.instance.cancelNotification(a.id.hashCode);
  }

  Future<void> _openAddAssignment() async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add a course first.'),
          action: SnackBarAction(label: 'Add course', onPressed: _openCourses),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddAssignmentScreen(courses: _courses)),
    );
  }

  Future<void> _openCourses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CourseScreen()),
    );
    _loadCourses();
  }

  // Safe display name: never empty, never crashes
  String _getFirstName(User? user) {
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) {
      final first = name.split(' ').first;
      if (first.isNotEmpty) return first;
    }
    final email = user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;
    final firstName = _getFirstName(user);
    final avatarLetter = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    final stream = _selectedCourseId == null
        ? _db.watchPendingAssignments()
        : _db.watchAssignmentsByCourse(_selectedCourseId!);

    return Scaffold(
      backgroundColor: cs.surface,
      body: StreamBuilder<List<Assignment>>(
        stream: stream,
        builder: (context, snap) {
          // Treat errors (e.g. missing Firestore index) as empty list
          final assignments =
          snap.hasError ? <Assignment>[] : (snap.data ?? <Assignment>[]);
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          return CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.book_outlined),
                    tooltip: 'Manage courses',
                    onPressed: _openCourses,
                  ),
                  PopupMenuButton<String>(
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(user?.email ?? ''),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('Log out'),
                        ]),
                      ),
                    ],
                    onSelected: (v) async {
                      if (v == 'logout') await _auth.logout();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $firstName 👋',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${assignments.length} pending assignment${assignments.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Course filter chips ───────────────────────────
              if (_courses.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCourseId == null,
                            onSelected: (_) =>
                                setState(() => _selectedCourseId = null),
                          ),
                        ),
                        ..._courses.map((c) {
                          final color = Color(int.parse(c.colorHex));
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(c.code),
                              selected: _selectedCourseId == c.id,
                              selectedColor: color.withOpacity(0.2),
                              checkmarkColor: color,
                              side: BorderSide(
                                color: _selectedCourseId == c.id
                                    ? color
                                    : cs.outlineVariant,
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedCourseId = c.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // ── Assignment list ───────────────────────────────
              if (loading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (assignments.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    hasCourses: _courses.isNotEmpty,
                    onAddCourse: _openCourses,
                  ),
                )
              else
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
                        return _AssignmentCard(
                          assignment: a,
                          course: course,
                          onMarkDone: () => _markDone(a),
                          onDelete: () => _deleteAssignment(a),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignmentDetailScreen(
                                  assignment: a,
                                  course: course,
                                ),
                              ),
                            );
                            _loadCourses();
                          },
                        );
                      },
                      childCount: assignments.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAssignment,
        icon: const Icon(Icons.add),
        label: const Text('Add assignment'),
      ),
    );
  }
}

// ── Assignment card ───────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final Course course;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.course,
    required this.onMarkDone,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final courseColor = Color(int.parse(course.colorHex));
    final a = assignment;

    return Dismissible(
      key: Key('assignment_${a.id}'),
      background: _swipeBg(
          color: Colors.green,
          icon: Icons.check,
          alignment: Alignment.centerLeft),
      secondaryBackground: _swipeBg(
          color: cs.error,
          icon: Icons.delete,
          alignment: Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        }
        return true;
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          onMarkDone();
        } else {
          onDelete();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: courseColor,
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
                          _pill(
                            course.code.isNotEmpty ? course.code : '?',
                            courseColor,
                          ),
                          const SizedBox(width: 6),
                          _PriorityBadge(priority: a.priority),
                          const Spacer(),
                          if (a.attachmentPath != null)
                            Icon(Icons.image_outlined,
                                size: 16, color: cs.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (a.description != null && a.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          a.description!,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('EEE, d MMM · HH:mm').format(a.deadline),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                          const Spacer(),
                          _CountdownBadge(assignment: a),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: Colors.green,
                  tooltip: 'Mark as done',
                  onPressed: onMarkDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _swipeBg(
      {required Color color,
        required IconData icon,
        required Alignment alignment}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white),
      );

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete assignment?'),
      content:
      Text('Are you sure you want to delete "${assignment.title}"?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ── Priority badge ────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final Priority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      Priority.high => ('High', Colors.red),
      Priority.medium => ('Medium', Colors.orange),
      Priority.low => ('Low', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Countdown badge ───────────────────────────────────────────

class _CountdownBadge extends StatelessWidget {
  final Assignment assignment;
  const _CountdownBadge({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final label = assignment.countdownLabel;
    final isOverdue = assignment.isOverdue;
    final hoursLeft = assignment.timeLeft.inHours;
    final color = isOverdue
        ? Colors.red
        : hoursLeft < 24
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasCourses;
  final VoidCallback onAddCourse;

  const _EmptyState({required this.hasCourses, required this.onAddCourse});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCourses
                  ? Icons.assignment_turned_in_outlined
                  : Icons.school_outlined,
              size: 72,
              color: cs.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasCourses ? 'All clear!' : 'No courses yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasCourses
                  ? 'No pending assignments. Tap the button below to add one.'
                  : 'Start by adding your courses, then track your assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!hasCourses)
              FilledButton.icon(
                onPressed: onAddCourse,
                icon: const Icon(Icons.add),
                label: const Text('Add a course'),
              ),
          ],
        ),
      ),
    );
  }
}