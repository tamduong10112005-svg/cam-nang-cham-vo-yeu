import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stored_image.dart';

@immutable
class NoteEntry {
  const NoteEntry(
      {required this.id,
      required this.title,
      required this.category,
      this.note = '',
      this.locationAddress = '',
      this.locationUrl = '',
      this.favorite = false,
      this.imagePath});
  final String id, title, category, note;
  final String locationAddress, locationUrl;
  final bool favorite;
  final String? imagePath;
  NoteEntry copyWith(
          {String? title,
          String? category,
          String? note,
          String? locationAddress,
          String? locationUrl,
          bool? favorite}) =>
      NoteEntry(
          id: id,
          title: title ?? this.title,
          category: category ?? this.category,
          note: note ?? this.note,
          locationAddress: locationAddress ?? this.locationAddress,
          locationUrl: locationUrl ?? this.locationUrl,
          favorite: favorite ?? this.favorite,
          imagePath: imagePath);
  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'note': note,
        'locationAddress': locationAddress,
        'locationUrl': locationUrl,
        'favorite': favorite,
        'imagePath': imagePath
      };
  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Khác',
      note: json['note'] as String? ?? '',
      locationAddress: json['locationAddress'] as String? ?? '',
      locationUrl: json['locationUrl'] as String? ?? '',
      favorite: json['favorite'] as bool? ?? false,
      imagePath: json['imagePath'] as String?);
}

@immutable
class PlannerEntry {
  const PlannerEntry(
      {required this.id,
      required this.kind,
      required this.title,
      this.details = '',
      this.date,
      this.priority = 1,
      this.done = false,
      this.notification = false,
      this.repeat = 'none'});
  final String id, kind, title, details;
  final DateTime? date;
  final int priority;
  final bool done, notification;
  // none, daily, weekly, monthly, or yearly.
  final String repeat;
  PlannerEntry copyWith(
          {String? title,
          String? details,
          DateTime? date,
          int? priority,
          bool? done,
          bool? notification,
          String? repeat}) =>
      PlannerEntry(
          id: id,
          kind: kind,
          title: title ?? this.title,
          details: details ?? this.details,
          date: date ?? this.date,
          priority: priority ?? this.priority,
          done: done ?? this.done,
          notification: notification ?? this.notification,
          repeat: repeat ?? this.repeat);
  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'details': details,
        'date': date?.toIso8601String(),
        'priority': priority,
        'done': done,
        'notification': notification,
        'repeat': repeat
      };
  factory PlannerEntry.fromJson(Map<String, dynamic> json) => PlannerEntry(
      id: json['id'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      done: json['done'] as bool? ?? false,
      notification: json['notification'] as bool? ?? false,
      repeat: json['repeat'] as String? ?? 'none');
}

@immutable
class CycleLog {
  const CycleLog(
      {required this.id,
      required this.start,
      this.end,
      this.symptoms = '',
      this.mood = '',
      this.pain = 0});
  final String id, symptoms, mood;
  final DateTime start;
  final DateTime? end;
  final int pain;
  Map<String, Object?> toJson() => {
        'id': id,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'symptoms': symptoms,
        'mood': mood,
        'pain': pain
      };
  factory CycleLog.fromJson(Map<String, dynamic> json) => CycleLog(
      id: json['id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.tryParse(json['end'] as String? ?? ''),
      symptoms: json['symptoms'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      pain: (json['pain'] as num?)?.toInt() ?? 0);
}

@immutable
class OutingStop {
  const OutingStop({
    required this.id,
    this.tripId = '',
    required this.timeRange,
    required this.place,
    this.note = '',
    this.address = '',
    this.link = '',
    this.imagePath,
    this.cost = 0,
  });
  final String id, timeRange, place, note, address, link;
  final String tripId;
  final String? imagePath;
  final int cost;
  Map<String, Object?> toJson() => {
        'id': id,
        'tripId': tripId,
        'timeRange': timeRange,
        'place': place,
        'note': note,
        'address': address,
        'link': link,
        'imagePath': imagePath,
        'cost': cost,
      };
  factory OutingStop.fromJson(Map<String, dynamic> json) => OutingStop(
        id: json['id'] as String,
        tripId: json['tripId'] as String? ?? '',
        timeRange: json['timeRange'] as String? ?? '',
        place: json['place'] as String? ?? '',
        note: json['note'] as String? ?? '',
        address: json['address'] as String? ?? '',
        link: json['link'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        cost: (json['cost'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class OutingTrip {
  const OutingTrip({required this.id, required this.name});
  final String id, name;
  Map<String, Object?> toJson() => {'id': id, 'name': name};
  factory OutingTrip.fromJson(Map<String, dynamic> json) =>
      OutingTrip(id: json['id'] as String, name: json['name'] as String? ?? '');
}

class LocalStore extends ChangeNotifier {
  static const _notesKey = 'notes.v1',
      _plannerKey = 'planner.v1',
      _outingsKey = 'outings.v1',
      _outingTripsKey = 'outingTrips.v1',
      _cyclesKey = 'cycles.v1';
  static const _cycleStartKey = 'cycle.start.v1',
      _cycleLengthKey = 'cycle.length.v1',
      _nicknameKey = 'wife.nickname.v1';
  static const _seasonKey = 'season.months.v1',
      _reminderKey = 'reminders.enabled.v1',
      _reminderTimeKey = 'reminders.time.v1';
  static const _pinKey = 'security.pinHash.v1',
      _bioKey = 'security.biometric.v1';
  static const _secureKeyName = 'loveCare.dataKey.v1',
      _privateKey = 'private.settings.enc.v1';
  final _secureStorage = const FlutterSecureStorage();
  final _cipher = AesGcm.with256bits();
  late SharedPreferences _prefs;
  late SecretKey _dataKey;
  Map<String, dynamic> _private = {};
  List<NoteEntry> _notes = [];
  List<PlannerEntry> _planner = [];
  List<OutingStop> _outings = [];
  List<OutingTrip> _outingTrips = [];
  List<CycleLog> _cycles = [];
  List<NoteEntry> get notes => List.unmodifiable(_notes);
  List<PlannerEntry> get planner => List.unmodifiable(_planner);
  List<OutingStop> get outings => List.unmodifiable(_outings);
  List<OutingTrip> get outingTrips => List.unmodifiable(_outingTrips);
  List<CycleLog> get cycles => List.unmodifiable(_cycles);
  DateTime? get cycleStart =>
      DateTime.tryParse(_private['cycleStart'] as String? ?? '');
  int get cycleLength => (_private['cycleLength'] as num?)?.toInt() ?? 28;
  String get nickname => _private['nickname'] as String? ?? '';
  int get themeColorValue =>
      (_private['themeColor'] as num?)?.toInt() ?? 0xFFB85F7D;
  bool get hasPin => _prefs.getString(_pinKey) != null;
  String? get pinHash => _prefs.getString(_pinKey);
  bool get biometricEnabled => _prefs.getBool(_bioKey) ?? false;
  static const _notificationGroups = [
    'season',
    'cycle',
    'anniversary',
    'health',
    'task'
  ];
  bool notificationEnabled(String group) =>
      _prefs.getBool('notifications.$group.v1') ??
      ((group == 'season' || group == 'cycle')
          ? (_prefs.getBool(_reminderKey) ?? false)
          : false);
  Map<String, bool> get notificationSettings => {
        for (final group in _notificationGroups)
          group: notificationEnabled(group)
      };
  bool get remindersEnabled => _notificationGroups.any(notificationEnabled);
  int get reminderHour => _prefs.getInt(_reminderTimeKey) ?? 20;
  List<int> get seasonMonths =>
      _prefs.getStringList(_seasonKey)?.map(int.parse).toList() ??
      [5, 6, 7, 8, 9, 10];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    var keyText = await _secureStorage.read(key: _secureKeyName);
    if (keyText == null) {
      final generated = await _cipher.newSecretKey();
      final keyBytes = await generated.extractBytes();
      keyText = base64Encode(keyBytes);
      await _secureStorage.write(key: _secureKeyName, value: keyText);
    }
    _dataKey = SecretKey(base64Decode(keyText));
    final settings = await _readSecureValue(_privateKey);
    if (settings != null) {
      _private = Map<String, dynamic>.from(jsonDecode(settings) as Map);
    }
    final legacyStart = _prefs.getString(_cycleStartKey);
    final legacyLength = _prefs.getInt(_cycleLengthKey);
    final legacyNickname = _prefs.getString(_nicknameKey);
    _private['cycleStart'] ??= legacyStart;
    _private['cycleLength'] ??= legacyLength;
    _private['nickname'] ??= legacyNickname;
    await _prefs.remove(_cycleStartKey);
    await _prefs.remove(_cycleLengthKey);
    await _prefs.remove(_nicknameKey);
    await _savePrivate();
    _notes = await _decodeList(_notesKey, NoteEntry.fromJson);
    _planner = await _decodeList(_plannerKey, PlannerEntry.fromJson);
    _outings = await _decodeList(_outingsKey, OutingStop.fromJson);
    _outingTrips = await _decodeList(_outingTripsKey, OutingTrip.fromJson);
    if (_outingTrips.isEmpty && _outings.isNotEmpty) {
      const legacyId = 'legacy-outing-plan';
      _outingTrips = const [OutingTrip(id: legacyId, name: 'Chuyến đi đã lưu')];
      _outings = _outings
          .map((stop) => OutingStop(
                id: stop.id,
                tripId: legacyId,
                timeRange: stop.timeRange,
                place: stop.place,
                note: stop.note,
                address: stop.address,
                link: stop.link,
                imagePath: stop.imagePath,
                cost: stop.cost,
              ))
          .toList();
      await _saveList(_outingTripsKey, _outingTrips, (e) => e.toJson());
      await _saveList(_outingsKey, _outings, (e) => e.toJson());
    }
    _cycles = await _decodeList(_cyclesKey, CycleLog.fromJson);
    if (_cycles.isEmpty && cycleStart != null) {
      _cycles = [
        CycleLog(
            id: cycleStart!.millisecondsSinceEpoch.toString(),
            start: cycleStart!)
      ];
      await _saveList(_cyclesKey, _cycles, (e) => e.toJson());
    }
  }

  Future<String> _encrypt(String clear) async {
    final box = await _cipher.encryptString(clear, secretKey: _dataKey);
    return 'enc1:${base64Encode(box.nonce)}:${base64Encode(box.cipherText)}:${base64Encode(box.mac.bytes)}';
  }

  Future<String> _decrypt(String encoded) async {
    if (!encoded.startsWith('enc1:')) return encoded;
    final parts = encoded.substring(5).split(':');
    if (parts.length != 3) {
      throw const FormatException('Dữ liệu mã hóa không hợp lệ.');
    }
    final box = SecretBox(base64Decode(parts[1]),
        nonce: base64Decode(parts[0]), mac: Mac(base64Decode(parts[2])));
    return _cipher.decryptString(box, secretKey: _dataKey);
  }

  Future<String?> _readSecureValue(String key) async {
    final raw = await _secureStorage.read(key: key);
    return raw == null ? null : _decrypt(raw);
  }

  Future<List<T>> _decodeList<T>(
      String key, T Function(Map<String, dynamic>) parse) async {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final clear = await _decrypt(raw);
      final items = (jsonDecode(clear) as List)
          .map((e) => parse(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!raw.startsWith('enc1:')) await _writeEncryptedPreference(key, clear);
      return items;
    } on Exception {
      return [];
    }
  }

  Future<void> _writeEncryptedPreference(String key, String clear) async =>
      _prefs.setString(key, await _encrypt(clear));
  Future<void> _savePrivate() async => _secureStorage.write(
      key: _privateKey, value: await _encrypt(jsonEncode(_private)));
  Future<void> _saveList<T>(String key, List<T> values,
      Map<String, Object?> Function(T) toJson) async {
    await _writeEncryptedPreference(
        key, jsonEncode(values.map(toJson).toList()));
    notifyListeners();
  }

  Future<void> saveEntry(NoteEntry entry) async {
    final i = _notes.indexWhere((e) => e.id == entry.id);
    if (i < 0) {
      _notes = [entry, ..._notes];
    } else {
      _notes[i] = entry;
    }
    await _saveList(_notesKey, _notes, (e) => e.toJson());
  }

  Future<void> deleteEntry(String id) async {
    final existing = _notes.where((e) => e.id == id).firstOrNull;
    if (existing?.imagePath != null) await deleteImage(existing!.imagePath!);
    _notes.removeWhere((e) => e.id == id);
    await _saveList(_notesKey, _notes, (e) => e.toJson());
  }

  Future<String> saveImageBytes(List<int> bytes) => saveStoredImage(bytes);

  Future<void> deleteImage(String path) => deleteStoredImage(path);

  Future<void> saveOutingStop(OutingStop stop) async {
    final i = _outings.indexWhere((e) => e.id == stop.id);
    if (i < 0) {
      _outings = [..._outings, stop];
    } else {
      _outings[i] = stop;
    }
    await _saveList(_outingsKey, _outings, (e) => e.toJson());
  }

  Future<void> saveOutingTrip(OutingTrip trip) async {
    final i = _outingTrips.indexWhere((e) => e.id == trip.id);
    if (i < 0) {
      _outingTrips = [..._outingTrips, trip];
    } else {
      _outingTrips[i] = trip;
    }
    await _saveList(_outingTripsKey, _outingTrips, (e) => e.toJson());
  }

  Future<void> deleteOutingTrip(String id) async {
    final removed = _outings.where((e) => e.tripId == id).toList();
    for (final stop in removed) {
      if (stop.imagePath != null) await deleteImage(stop.imagePath!);
    }
    _outings.removeWhere((e) => e.tripId == id);
    _outingTrips.removeWhere((e) => e.id == id);
    await _saveList(_outingsKey, _outings, (e) => e.toJson());
    await _saveList(_outingTripsKey, _outingTrips, (e) => e.toJson());
  }

  Future<void> deleteOutingStop(String id) async {
    final stop = _outings.where((e) => e.id == id).firstOrNull;
    if (stop?.imagePath != null) await deleteImage(stop!.imagePath!);
    _outings.removeWhere((e) => e.id == id);
    await _saveList(_outingsKey, _outings, (e) => e.toJson());
  }

  Future<void> savePlanner(PlannerEntry item) async {
    final i = _planner.indexWhere((e) => e.id == item.id);
    if (i < 0) {
      _planner = [item, ..._planner];
    } else {
      _planner[i] = item;
    }
    await _saveList(_plannerKey, _planner, (e) => e.toJson());
  }

  Future<void> deletePlanner(String id) async {
    _planner.removeWhere((e) => e.id == id);
    await _saveList(_plannerKey, _planner, (e) => e.toJson());
  }

  Future<void> saveCycle(DateTime? start, int length) async {
    if (start == null) {
      _private.remove('cycleStart');
    } else {
      final day = DateTime(start.year, start.month, start.day);
      _private['cycleStart'] = day.toIso8601String();
      if (!_cycles.any((e) =>
          e.start.year == day.year &&
          e.start.month == day.month &&
          e.start.day == day.day)) {
        _cycles.add(
            CycleLog(id: day.millisecondsSinceEpoch.toString(), start: day));
        _cycles.sort((a, b) => b.start.compareTo(a.start));
        await _saveList(_cyclesKey, _cycles, (e) => e.toJson());
      }
    }
    _private['cycleLength'] = length.clamp(21, 45).toInt();
    await _savePrivate();
    notifyListeners();
  }

  Future<void> saveCycleLog(CycleLog log) async {
    final i = _cycles.indexWhere((e) => e.id == log.id);
    if (i < 0) {
      _cycles = [log, ..._cycles];
    } else {
      _cycles[i] = log;
    }
    _cycles.sort((a, b) => b.start.compareTo(a.start));
    await _saveList(_cyclesKey, _cycles, (e) => e.toJson());
  }

  Future<void> deleteCycle(String id) async {
    final removed = _cycles.where((e) => e.id == id).firstOrNull;
    _cycles.removeWhere((e) => e.id == id);
    if (removed != null && removed.start == cycleStart) {
      if (_cycles.isEmpty) {
        _private.remove('cycleStart');
      } else {
        _private['cycleStart'] = _cycles.first.start.toIso8601String();
      }
      await _savePrivate();
    }
    await _saveList(_cyclesKey, _cycles, (e) => e.toJson());
  }

  Future<void> saveNickname(String value) async {
    _private['nickname'] = value.trim();
    await _savePrivate();
    notifyListeners();
  }

  Future<void> saveThemeColor(int value) async {
    _private['themeColor'] = value;
    await _savePrivate();
    notifyListeners();
  }

  Future<void> saveSeasonMonths(List<int> months) async {
    await _prefs.setStringList(
        _seasonKey, months.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> saveReminderSettings(bool enabled, int hour) async {
    await saveNotificationGroup('season', enabled);
    await saveReminderHour(hour);
  }

  Future<void> saveNotificationGroup(String group, bool enabled) async {
    if (!_notificationGroups.contains(group)) return;
    await _prefs.setBool('notifications.$group.v1', enabled);
    await _prefs.setBool(
        _reminderKey,
        _notificationGroups.any(
            (item) => item == group ? enabled : notificationEnabled(item)));
    notifyListeners();
  }

  Future<void> saveReminderHour(int hour) async {
    await _prefs.setInt(_reminderTimeKey, hour.clamp(0, 23));
    notifyListeners();
  }

  Future<void> savePinHash(String? hash) async {
    if (hash == null) {
      await _prefs.remove(_pinKey);
      await _prefs.setBool(_bioKey, false);
    } else {
      await _prefs.setString(_pinKey, hash);
    }
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool(_bioKey, value);
    notifyListeners();
  }

  Future<Map<String, Object?>> exportData() async {
    final exportedNotes = <Map<String, Object?>>[];
    for (final note in _notes) {
      final item = note.toJson()..remove('imagePath');
      if (note.imagePath != null) {
        final bytes = await readStoredImage(note.imagePath!);
        if (bytes != null) item['imageBytes'] = base64Encode(bytes);
      }
      exportedNotes.add(item);
    }
    final exportedOutings = <Map<String, Object?>>[];
    for (final stop in _outings) {
      final item = stop.toJson()..remove('imagePath');
      if (stop.imagePath != null) {
        final bytes = await readStoredImage(stop.imagePath!);
        if (bytes != null) item['imageBytes'] = base64Encode(bytes);
      }
      exportedOutings.add(item);
    }
    return {
      'format': 'love-care-backup-v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': exportedNotes,
      'planner': _planner.map((e) => e.toJson()).toList(),
      'outings': exportedOutings,
      'outingTrips': _outingTrips.map((e) => e.toJson()).toList(),
      'cycles': _cycles.map((e) => e.toJson()).toList(),
      'settings': {
        'cycleStart': cycleStart?.toIso8601String(),
        'cycleLength': cycleLength,
        'nickname': nickname,
        'themeColor': themeColorValue,
        'seasonMonths': seasonMonths,
        'remindersEnabled': remindersEnabled,
        'notificationSettings': notificationSettings,
        'reminderHour': reminderHour
      },
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data['format'] != 'love-care-backup-v1') {
      throw const FormatException('Tệp sao lưu không đúng định dạng.');
    }
    List<T> read<T>(String key, T Function(Map<String, dynamic>) parser) =>
        ((data[key] as List?) ?? [])
            .map((e) => parser(Map<String, dynamic>.from(e as Map)))
            .toList();
    for (final note in _notes) {
      if (note.imagePath != null) await deleteImage(note.imagePath!);
    }
    for (final stop in _outings) {
      if (stop.imagePath != null) await deleteImage(stop.imagePath!);
    }
    final noteData = (data['notes'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _notes = [];
    for (final item in noteData) {
      final imageBytes = item.remove('imageBytes') as String?;
      var note = NoteEntry.fromJson(item);
      if (imageBytes != null) {
        note = NoteEntry(
          id: note.id,
          title: note.title,
          category: note.category,
          note: note.note,
          favorite: note.favorite,
          imagePath: await saveImageBytes(base64Decode(imageBytes)),
        );
      }
      _notes.add(note);
    }
    _planner = read('planner', PlannerEntry.fromJson);
    _outings = [];
    for (final raw in (data['outings'] as List? ?? [])) {
      final item = Map<String, dynamic>.from(raw as Map);
      final imageBytes = item.remove('imageBytes') as String?;
      var stop = OutingStop.fromJson(item);
      if (imageBytes != null) {
        stop = OutingStop(
          id: stop.id,
          tripId: stop.tripId,
          timeRange: stop.timeRange,
          place: stop.place,
          note: stop.note,
          address: stop.address,
          link: stop.link,
          imagePath: await saveImageBytes(base64Decode(imageBytes)),
          cost: stop.cost,
        );
      }
      _outings.add(stop);
    }
    _outingTrips = read('outingTrips', OutingTrip.fromJson);
    if (_outingTrips.isEmpty && _outings.isNotEmpty) {
      const legacyId = 'legacy-outing-plan';
      _outingTrips = const [OutingTrip(id: legacyId, name: 'Chuyến đi đã lưu')];
      _outings = _outings
          .map((stop) => OutingStop(
                id: stop.id,
                tripId: stop.tripId.isEmpty ? legacyId : stop.tripId,
                timeRange: stop.timeRange,
                place: stop.place,
                note: stop.note,
                address: stop.address,
                link: stop.link,
                imagePath: stop.imagePath,
                cost: stop.cost,
              ))
          .toList();
    }
    _cycles = read('cycles', CycleLog.fromJson);
    final settings =
        Map<String, dynamic>.from((data['settings'] as Map?) ?? {});
    _private = {
      'cycleStart': settings['cycleStart'],
      'cycleLength': (settings['cycleLength'] as num?)?.toInt() ?? 28,
      'nickname': settings['nickname'] as String? ?? '',
      'themeColor': (settings['themeColor'] as num?)?.toInt() ?? 0xFFB85F7D
    };
    await _saveList(_notesKey, _notes, (e) => e.toJson());
    await _saveList(_plannerKey, _planner, (e) => e.toJson());
    await _saveList(_outingsKey, _outings, (e) => e.toJson());
    await _saveList(_outingTripsKey, _outingTrips, (e) => e.toJson());
    await _saveList(_cyclesKey, _cycles, (e) => e.toJson());
    await _savePrivate();
    final months = (settings['seasonMonths'] as List?)
        ?.map((e) => (e as num).toInt().toString())
        .toList();
    if (months != null) await _prefs.setStringList(_seasonKey, months);
    final notificationSettings = Map<String, dynamic>.from(
        settings['notificationSettings'] as Map? ?? {});
    for (final group in _notificationGroups) {
      if (notificationSettings[group] is bool) {
        await _prefs.setBool(
            'notifications.$group.v1', notificationSettings[group] as bool);
      }
    }
    await _prefs.setBool(
        _reminderKey, settings['remindersEnabled'] as bool? ?? false);
    await _prefs.setInt(
        _reminderTimeKey, (settings['reminderHour'] as num?)?.toInt() ?? 20);
    notifyListeners();
  }

  Future<void> clearAll() async {
    for (final note in _notes) {
      if (note.imagePath != null) await deleteImage(note.imagePath!);
    }
    for (final stop in _outings) {
      if (stop.imagePath != null) await deleteImage(stop.imagePath!);
    }
    _notes = [];
    _planner = [];
    _outings = [];
    _outingTrips = [];
    _cycles = [];
    _private = {};
    await _prefs.clear();
    await _secureStorage.delete(key: _privateKey);
    notifyListeners();
  }
}
