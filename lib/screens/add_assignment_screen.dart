import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  final List<Course> courses;
  const AddAssignmentScreen({super.key, required this.courses});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Course? _selectedCourse;
  DateTime? _deadline;
  Priority _priority = Priority.medium;
  String? _attachmentPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.courses.isNotEmpty ? widget.courses.first : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _attachmentPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course.')),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a deadline.')),
      );
      return;
    }

    setState(() => _loading = true);

    final assignment = Assignment(
      courseId: _selectedCourse!.id!,
      title: _titleCtrl.text.trim(),
      description:
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      deadline: _deadline!,
      priority: _priority,
      attachmentPath: _attachmentPath,
    );

    final docId =
    await FirestoreService.instance.insertAssignment(assignment);

    await NotificationService.instance.scheduleDeadlineReminder(
      id: docId.hashCode,
      assignmentTitle: assignment.title,
      courseName: _selectedCourse!.name,
      deadline: assignment.deadline,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New assignment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Course
            Text('Course', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<Course>(
              value: _selectedCourse,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: widget.courses.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.colorHex)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${c.code} — ${c.name}'),
                  ]),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCourse = v),
            ),
            const SizedBox(height: 20),

            // Title
            Text('Title', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Week 5 lab report',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any extra notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Deadline
            Text('Deadline', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: _deadline != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _deadline = null),
                  )
                      : null,
                ),
                child: Text(
                  _deadline == null
                      ? 'Tap to set deadline'
                      : DateFormat('EEEE, d MMMM yyyy · HH:mm')
                      .format(_deadline!),
                  style: TextStyle(
                    color: _deadline == null ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Priority
            Text('Priority', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(
                    value: Priority.low,
                    label: Text('Low'),
                    icon: Icon(Icons.arrow_downward, size: 16)),
                ButtonSegment(
                    value: Priority.medium,
                    label: Text('Medium'),
                    icon: Icon(Icons.remove, size: 16)),
                ButtonSegment(
                    value: Priority.high,
                    label: Text('High'),
                    icon: Icon(Icons.arrow_upward, size: 16)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) =>
                  setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),

            // Camera
            Text('Attachment (optional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_attachmentPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_attachmentPath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _attachmentPath = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove photo'),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a photo of assignment brief'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: _loading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save assignment'),
            ),
          ],
        ),
      ),
    );
  }
}