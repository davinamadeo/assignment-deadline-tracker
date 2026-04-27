import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';

class _CourseColor {
  final String hex;
  final Color color;
  const _CourseColor(this.hex, this.color);
}

const List<_CourseColor> _courseColors = [
  _CourseColor('0xFF6750A4', Color(0xFF6750A4)),
  _CourseColor('0xFF0077B6', Color(0xFF0077B6)),
  _CourseColor('0xFF2D9B5A', Color(0xFF2D9B5A)),
  _CourseColor('0xFFE65100', Color(0xFFE65100)),
  _CourseColor('0xFFC62828', Color(0xFFC62828)),
  _CourseColor('0xFF00838F', Color(0xFF00838F)),
  _CourseColor('0xFFF9A825', Color(0xFFF9A825)),
  _CourseColor('0xFF6A1B9A', Color(0xFF6A1B9A)),
];

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _db = FirestoreService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My courses')),
      body: StreamBuilder<List<Course>>(
        stream: _db.watchCourses(),
        builder: (context, snap) {
          final courses = snap.data ?? [];
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('No courses yet'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCourseDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add course'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = courses[i];
              final color = Color(int.parse(c.colorHex));
              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.5),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Text(
                    c.code.isNotEmpty ? c.code[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(c.code),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showCourseDialog(existing: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _deleteCourse(context, c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCourseDialog({Course? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final codeCtrl = TextEditingController(text: existing?.code);
    String selectedHex =
        existing?.colorHex ?? _courseColors.first.hex;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add course' : 'Edit course'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Course name',
                    hintText: 'e.g. Mobile Programming',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Course code',
                    hintText: 'e.g. ETS234',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color',
                    style: Theme.of(ctx).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _courseColors.map((item) {
                    final isSelected = selectedHex == item.hex;
                    return GestureDetector(
                      onTap: () => setLocal(() => selectedHex = item.hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: item.color.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final course = Course(
                  id: existing?.id,
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  colorHex: selectedHex,
                );
                if (existing == null) {
                  await _db.insertCourse(course);
                } else {
                  await _db.updateCourse(course);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCourse(BuildContext context, Course c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
            'Deleting "${c.name}" will also delete all its assignments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) await _db.deleteCourse(c.id!);
  }
}