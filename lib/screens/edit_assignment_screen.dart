import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class EditAssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  final Course course;

  const EditAssignmentScreen({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late DateTime _deadline;
  late Priority _priority;
  String? _attachmentPath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleCtrl = TextEditingController(text: a.title);
    _descCtrl = TextEditingController(text: a.description ?? '');
    _deadline = a.deadline;
    _priority = a.priority;
    _attachmentPath = a.attachmentPath;
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
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
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
    setState(() => _loading = true);

    final updated = widget.assignment.copyWith(
      title: _titleCtrl.text.trim(),
      description:
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      deadline: _deadline,
      priority: _priority,
      attachmentPath: _attachmentPath,
    );

    await FirestoreService.instance.updateAssignment(updated);

    // Reschedule notification with new deadline
    final notifId = NotificationService.idFromDocId(widget.assignment.id!);
    await NotificationService.instance.cancelNotification(notifId);
    await NotificationService.instance.scheduleDeadlineReminder(
      id: notifId,
      assignmentTitle: updated.title,
      courseName: widget.course.name,
      deadline: updated.deadline,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit assignment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Course (read-only)
            Text('Course', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse(widget.course.colorHex)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${widget.course.code} — ${widget.course.name}',
                      style: TextStyle(color: cs.onSurface)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text('Title', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
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
                border: OutlineInputBorder(),
                hintText: 'Any extra notes...',
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM yyyy · HH:mm').format(_deadline),
                  style: TextStyle(color: cs.onSurface),
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
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: cs.surfaceVariant,
                    child: Center(
                        child: Text('Photo not found',
                            style:
                            TextStyle(color: cs.onSurfaceVariant))),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _attachmentPath = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error),
                    ),
                  ),
                ],
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
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}