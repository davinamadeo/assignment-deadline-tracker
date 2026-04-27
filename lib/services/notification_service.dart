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

  Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

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
      schedule: NotificationCalendar.fromDate(date: scheduledAt),
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

  void setListeners({
    required Future<void> Function(ReceivedAction) onActionReceived,
  }) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }
}