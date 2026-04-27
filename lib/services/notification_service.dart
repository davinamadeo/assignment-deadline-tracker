import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelKey = 'assignment_reminders';

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Assignment Reminders',
          channelDescription: 'Reminders before assignment deadlines',
          defaultColor: const Color(0xFF6750A4),
          ledColor: const Color(0xFF6750A4),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: false,
    );
  }

  // Returns true if the basic notification permission is already granted.
  Future<bool> isNotificationAllowed() =>
      AwesomeNotifications().isNotificationAllowed();

  // Requests basic notification permission (shows system dialog on Android 13+).
  Future<void> requestBasicPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
    }
  }

  // Returns true if PreciseAlarms permission is already granted.
  Future<bool> isPreciseAlarmGranted() async {
    final notGranted = await AwesomeNotifications().checkPermissionList(
      permissions: [NotificationPermission.PreciseAlarms],
    );
    return !notGranted.contains(NotificationPermission.PreciseAlarms);
  }

  // Opens the system Alarms & Reminders settings page (Android 12+).
  Future<void> requestPreciseAlarm() async {
    await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [NotificationPermission.PreciseAlarms],
    );
  }

  // @deprecated — kept for compatibility; call requestBasicPermission() instead.
  Future<void> requestPermission() => requestBasicPermission();

  Future<void> scheduleDeadlineReminder({
    required int id,
    required String assignmentTitle,
    required String courseName,
    required DateTime deadline,
    int minutesBefore = 60,
  }) async {
    final scheduledAt = deadline.subtract(Duration(minutes: minutesBefore));

    if (scheduledAt.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: '⏰ Deadline soon: $assignmentTitle',
        body: '$courseName is due in $minutesBefore minutes!',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledAt,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // Converts a Firestore doc ID to a safe positive notification ID.
  // String.hashCode can be negative; Android requires a positive int.
  static int idFromDocId(String docId) => docId.hashCode.abs();

  void setListeners({
    required Future<void> Function(ReceivedAction) onActionReceived,
  }) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }
}