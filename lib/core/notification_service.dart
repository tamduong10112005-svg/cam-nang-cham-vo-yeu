import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'local_store.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final List<Timer> _webTimers = [];
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    await _plugin.initialize(
        settings: const InitializationSettings(
      web: WebInitializationSettings(),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false),
    ));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? true;
    }
    if (kIsWeb) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  WebFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return true;
  }

  Future<void> reschedule(LocalStore store) async {
    await initialize();
    await _plugin.cancelAll();
    if (kIsWeb) {
      _rescheduleWeb(store);
      return;
    }
    if (store.notificationEnabled('season')) {
      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, store.reminderHour);
      if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: 10,
        title: 'Cẩm nang chăm vợ yêu',
        body: 'Mở cẩm nang để xem gợi ý chăm sóc theo mùa hôm nay.',
        scheduledDate: first,
        notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
                'seasonal_daily', 'Nhắc chăm sóc hằng ngày',
                channelDescription: 'Gợi ý chăm sóc theo mùa',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority),
            iOS: DarwinNotificationDetails(
                presentAlert: true, presentSound: true)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    final now = tz.TZDateTime.now(tz.local);
    if (store.notificationEnabled('cycle') && store.cycleStart != null) {
      final predicted = store.cycleStart!
          .add(Duration(days: store.cycleLength))
          .subtract(const Duration(days: 1));
      final cycleNotice = tz.TZDateTime(tz.local, predicted.year,
          predicted.month, predicted.day, store.reminderHour);
      if (cycleNotice.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          id: 20,
          title: 'Cẩm nang chăm vợ yêu',
          body:
              'Có thể chuẩn bị sẵn vật dụng cần thiết. Mở ứng dụng để xem lịch riêng tư.',
          scheduledDate: cycleNotice,
          notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                  'private_cycle', 'Nhắc lịch riêng tư',
                  channelDescription:
                      'Thông báo chu kỳ không hiển thị dữ liệu nhạy cảm',
                  importance: Importance.defaultImportance,
                  priority: Priority.defaultPriority),
              iOS: DarwinNotificationDetails(
                  presentAlert: true, presentSound: true)),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
    for (final entry in store.planner.where((e) {
      final group = switch (e.kind) {
        'Kỷ niệm' => 'anniversary',
        'Sức khỏe' => 'health',
        _ => 'task',
      };
      return e.notification &&
          e.date != null &&
          !e.done &&
          store.notificationEnabled(group);
    })) {
      final isAnnual = entry.repeat == 'yearly';
      final isMonthly = entry.repeat == 'monthly';
      final isDaily = entry.repeat == 'daily';
      final isWeekly = entry.repeat == 'weekly';
      final repeats = isAnnual || isMonthly || isDaily || isWeekly;
      var day = tz.TZDateTime(tz.local, entry.date!.year, entry.date!.month,
          entry.date!.day, store.reminderHour);
      if (repeats && !day.isAfter(now)) {
        if (isDaily) {
          day = tz.TZDateTime(
              tz.local, now.year, now.month, now.day, store.reminderHour);
          if (!day.isAfter(now)) day = day.add(const Duration(days: 1));
        } else if (isWeekly) {
          final daysUntil = (day.weekday - now.weekday + 7) % 7;
          day = tz.TZDateTime(
                  tz.local, now.year, now.month, now.day, store.reminderHour)
              .add(Duration(days: daysUntil));
          if (!day.isAfter(now)) day = day.add(const Duration(days: 7));
        } else if (isAnnual) {
          day = tz.TZDateTime(
              tz.local, now.year + 1, day.month, day.day, store.reminderHour);
        } else {
          var year = now.year;
          var month = now.month;
          while (true) {
            final candidate = tz.TZDateTime(
                tz.local, year, month, day.day, store.reminderHour);
            if (candidate.isAfter(now)) {
              day = candidate;
              break;
            }
            month++;
            if (month == 13) {
              month = 1;
              year++;
            }
          }
        }
      }
      final offsets =
          entry.kind == 'Kỷ niệm' && isAnnual ? [30, 7, 3, 1, 0] : [0];
      for (final daysBefore in offsets) {
        var target = day.subtract(Duration(days: daysBefore));
        final scheduled = tz.TZDateTime(tz.local, target.year, target.month,
            target.day, store.reminderHour);
        if (!scheduled.isAfter(now) && !repeats) continue;
        // Move annual pre-reminders to next year if this year's date has passed.
        if (isAnnual && !scheduled.isAfter(now)) {
          target = tz.TZDateTime(tz.local, target.year + 1, target.month,
              target.day, store.reminderHour);
        }
        final id = 100 +
            ((entry.id.hashCode & 0x7fffffff) % 100000) * 100 +
            daysBefore;
        await _plugin.zonedSchedule(
          id: id,
          title: entry.title,
          body: [
            if (daysBefore > 0) 'Còn $daysBefore ngày.',
            if (entry.details.trim().isNotEmpty) entry.details.trim(),
          ].join(' '),
          scheduledDate: target,
          matchDateTimeComponents: isAnnual
              ? DateTimeComponents.dateAndTime
              : isMonthly
                  ? DateTimeComponents.dayOfMonthAndTime
                  : isDaily
                      ? DateTimeComponents.time
                      : isWeekly
                          ? DateTimeComponents.dayOfWeekAndTime
                          : null,
          notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                  'planned_events', 'Lịch đã lên kế hoạch',
                  channelDescription:
                      'Nhắc lịch với nội dung đã nhập trong ứng dụng',
                  importance: Importance.defaultImportance,
                  priority: Priority.defaultPriority,
                  visibility: NotificationVisibility.public),
              iOS: DarwinNotificationDetails(
                  presentAlert: true, presentSound: true)),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  void _rescheduleWeb(LocalStore store) {
    for (final timer in _webTimers) {
      timer.cancel();
    }
    _webTimers.clear();

    final now = DateTime.now();
    if (store.notificationEnabled('season')) {
      var first = DateTime(now.year, now.month, now.day, store.reminderHour);
      if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
      _scheduleWeb(
          10,
          'Cẩm nang chăm vợ yêu',
          'Mở cẩm nang để xem gợi ý chăm sóc theo mùa hôm nay.',
          first,
          () => _rescheduleWeb(store));
    }

    if (store.notificationEnabled('cycle') && store.cycleStart != null) {
      final predicted = store.cycleStart!
          .add(Duration(days: store.cycleLength))
          .subtract(const Duration(days: 1));
      final cycleNotice = DateTime(
          predicted.year, predicted.month, predicted.day, store.reminderHour);
      if (cycleNotice.isAfter(now)) {
        _scheduleWeb(
            20,
            'Cẩm nang chăm vợ yêu',
            'Có thể chuẩn bị sẵn vật dụng cần thiết. Mở ứng dụng để xem lịch riêng tư.',
            cycleNotice,
            () => _rescheduleWeb(store));
      }
    }

    for (final entry in store.planner.where((item) {
      final group = switch (item.kind) {
        'Kỷ niệm' => 'anniversary',
        'Sức khỏe' => 'health',
        _ => 'task',
      };
      return item.notification &&
          item.date != null &&
          !item.done &&
          store.notificationEnabled(group);
    })) {
      final isAnnual = entry.repeat == 'yearly';
      final occurrence = _nextWebOccurrence(
          entry.date!, now, store.reminderHour, entry.repeat);
      final offsets =
          entry.kind == 'Kỷ niệm' && isAnnual ? [30, 7, 3, 1, 0] : [0];
      for (final daysBefore in offsets) {
        var target = occurrence.subtract(Duration(days: daysBefore));
        if (!target.isAfter(now)) {
          if (isAnnual) {
            final nextYearOccurrence = _nextWebOccurrence(
                DateTime(occurrence.year + 1, occurrence.month, occurrence.day),
                now,
                store.reminderHour,
                'yearly');
            target = nextYearOccurrence.subtract(Duration(days: daysBefore));
          } else {
            continue;
          }
        }
        final id = 100 +
            ((entry.id.hashCode & 0x7fffffff) % 100000) * 100 +
            daysBefore;
        final body = [
          if (daysBefore > 0) 'Còn $daysBefore ngày.',
          if (entry.details.trim().isNotEmpty) entry.details.trim(),
        ].join(' ');
        _scheduleWeb(
            id, entry.title, body, target, () => _rescheduleWeb(store));
      }
    }
  }

  void _scheduleWeb(int id, String title, String body, DateTime when,
      VoidCallback reschedule) {
    final delay = when.difference(DateTime.now());
    if (delay.isNegative || delay == Duration.zero) return;
    _webTimers.add(Timer(delay, () async {
      try {
        await _plugin.show(
            id: id,
            title: title,
            body: body,
            notificationDetails:
                const NotificationDetails(web: WebNotificationDetails()));
      } catch (_) {}
      reschedule();
    }));
  }

  DateTime _nextWebOccurrence(
      DateTime initial, DateTime now, int hour, String repeat) {
    var year = now.year;
    var month = now.month;
    final day = initial.day;
    switch (repeat) {
      case 'daily':
        var candidate = DateTime(year, month, now.day, hour);
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case 'weekly':
        final daysUntil = (initial.weekday - now.weekday + 7) % 7;
        var candidate =
            DateTime(year, month, now.day, hour).add(Duration(days: daysUntil));
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
      case 'monthly':
        while (true) {
          final lastDay = DateTime(year, month + 1, 0).day;
          final candidate = DateTime(year, month, day.clamp(1, lastDay), hour,
              initial.minute, initial.second);
          if (candidate.isAfter(now)) return candidate;
          month++;
          if (month == 13) {
            month = 1;
            year++;
          }
        }
      case 'yearly':
        while (true) {
          final lastDay = DateTime(year, initial.month + 1, 0).day;
          final candidate = DateTime(year, initial.month, day.clamp(1, lastDay),
              hour, initial.minute, initial.second);
          if (candidate.isAfter(now)) return candidate;
          year++;
        }
      default:
        return DateTime(initial.year, initial.month, initial.day, hour);
    }
  }
}
