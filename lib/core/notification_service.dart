import 'package:flutter/foundation.dart';
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
    return true;
  }

  Future<void> reschedule(LocalStore store) async {
    await initialize();
    await _plugin.cancelAll();
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
      final repeats = isAnnual || isMonthly;
      var day = tz.TZDateTime(tz.local, entry.date!.year, entry.date!.month,
          entry.date!.day, store.reminderHour);
      if (repeats && !day.isAfter(now)) {
        if (isAnnual) {
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
}
