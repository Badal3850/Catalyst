import 'package:flutter/services.dart';

import '../../core/constants.dart';

/// Represents a calendar event to be created.
class CalendarEventRequest {
  const CalendarEventRequest({
    required this.title,
    required this.startTime,
    this.endTime,
    this.description,
    this.location,
  });

  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;
  final String? location;

  Map<String, dynamic> toMap() => {
        'title': title,
        'startTimeMs': startTime.millisecondsSinceEpoch,
        'endTimeMs': (endTime ?? startTime.add(const Duration(hours: 1)))
            .millisecondsSinceEpoch,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      };
}

/// Represents a local reminder / alarm.
class ReminderRequest {
  const ReminderRequest({
    required this.title,
    required this.triggerTime,
    this.body,
  });

  final String title;
  final DateTime triggerTime;
  final String? body;

  Map<String, dynamic> toMap() => {
        'title': title,
        'triggerTimeMs': triggerTime.millisecondsSinceEpoch,
        if (body != null) 'body': body,
      };
}

/// Bridges Flutter to the native calendar and reminder APIs.
///
/// Uses [MethodChannel]s to invoke:
/// - **Android:** `android.permission.WRITE_CALENDAR` and
///   `android.permission.RECEIVE_BOOT_COMPLETED` via the Calendar Provider.
/// - **iOS:** `EventKit.EKEventStore` for calendars and `UserNotifications`
///   for reminders.
class CalendarService {
  static const MethodChannel _calendarChannel =
      MethodChannel(AppConstants.calendarChannel);

  static const MethodChannel _reminderChannel =
      MethodChannel(AppConstants.reminderChannel);

  /// Creates a calendar event. Returns the platform-assigned event ID, or
  /// `null` if the operation failed.
  Future<String?> createEvent(CalendarEventRequest event) async {
    try {
      final result = await _calendarChannel.invokeMethod<String>(
        'createEvent',
        event.toMap(),
      );
      return result;
    } on PlatformException catch (e) {
      // Log and surface the error gracefully rather than crashing.
      // ignore: avoid_print
      print('CalendarService.createEvent error: ${e.message}');
      return null;
    }
  }

  /// Schedules a local reminder / notification.
  Future<bool> scheduleReminder(ReminderRequest reminder) async {
    try {
      final result = await _reminderChannel.invokeMethod<bool>(
        'scheduleReminder',
        reminder.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('CalendarService.scheduleReminder error: ${e.message}');
      return false;
    }
  }

  /// Checks whether the app has calendar write permission.
  Future<bool> hasCalendarPermission() async {
    try {
      return await _calendarChannel.invokeMethod<bool>(
            'hasPermission',
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests calendar write permission from the OS.
  Future<bool> requestCalendarPermission() async {
    try {
      return await _calendarChannel.invokeMethod<bool>(
            'requestPermission',
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
