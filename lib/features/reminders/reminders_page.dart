import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/local_store.dart';
import '../../core/notification_service.dart';
import '../../shared/widgets.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  String _kind = 'Kỷ niệm';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final entries = widget.store.planner
              .where((e) => e.kind == _kind)
              .toList()
            ..sort((a, b) =>
                (a.date ?? DateTime(2200)).compareTo(b.date ?? DateTime(2200)));
          final rainy =
              widget.store.seasonMonths.contains(DateTime.now().month);
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm lịch')),
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageHeading(
                  eyebrow: 'Chu đáo mỗi ngày',
                  title: 'Lịch & nhắc nhở',
                  subtitle:
                      'Kỷ niệm, việc chăm sóc và sức khỏe — lưu trên máy.'),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'Kỷ niệm',
                            label: Text('Kỷ niệm'),
                            icon: Icon(Icons.celebration_outlined)),
                        ButtonSegment(
                            value: 'Việc chăm sóc',
                            label: Text('Việc cần làm'),
                            icon: Icon(Icons.checklist)),
                        ButtonSegment(
                            value: 'Sức khỏe',
                            label: Text('Sức khỏe'),
                            icon: Icon(Icons.health_and_safety_outlined)),
                      ],
                      selected: {
                        _kind
                      },
                      onSelectionChanged: (s) =>
                          setState(() => _kind = s.first))),
              const SizedBox(height: 12),
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                    if (_kind == 'Kỷ niệm') _seasonPanel(rainy),
                    if (entries.isEmpty) _emptyState(),
                    if (kIsWeb) _webReminderNotice(),
                    ...entries.map(_entryCard),
                    const SizedBox(height: 8),
                    _dailyReminderCard(),
                    const SizedBox(height: 10),
                    _notificationGroupsCard(),
                    if (_kind == 'Kỷ niệm')
                      const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                              'Kỷ niệm được nhắc trước 7, 3, 1 ngày và đúng ngày. Thông báo chỉ ghi nội dung chung để giữ riêng tư.',
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: Color(0xFF826E77)))),
                  ])),
            ]),
          );
        },
      );

  Widget _webReminderNotice() => const Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Text(
          'Trên iPhone, hãy thêm ứng dụng vào Màn hình chính và cho phép thông báo. Nhắc hẹn chạy khi ứng dụng đang mở; để báo đúng giờ khi đã đóng ứng dụng cần máy chủ gửi thông báo.',
          style:
              TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF826E77)),
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 20),
        child: Center(
            child: Column(children: [
          Icon(_kind == 'Kỷ niệm' ? Icons.event : Icons.favorite_border,
              size: 44, color: const Color(0xFFD9A5B6)),
          const SizedBox(height: 10),
          Text('Chưa có ${_kind.toLowerCase()}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm mới')),
        ])),
      );

  Widget _entryCard(PlannerEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.delete_outline)),
          onDismissed: (_) async {
            await widget.store.deletePlanner(entry.id);
            await NotificationService.instance.reschedule(widget.store);
          },
          child: SoftCard(
              child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _kind == 'Việc chăm sóc'
                ? Checkbox(
                    value: entry.done,
                    onChanged: (v) async {
                      await widget.store.savePlanner(entry.copyWith(done: v));
                      await NotificationService.instance
                          .reschedule(widget.store);
                    })
                : CircleAvatar(
                    backgroundColor: const Color(0xFFFFF1F5),
                    child: Icon(
                        _kind == 'Sức khỏe'
                            ? Icons.health_and_safety_outlined
                            : Icons.event,
                        color: const Color(0xFFB85F7D))),
            title: Text(entry.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration:
                        entry.done ? TextDecoration.lineThrough : null)),
            subtitle: Text(
                [
                  if (entry.date != null) _date(entry.date!),
                  if (entry.repeat == 'monthly') 'Lặp hằng tháng',
                  if (entry.repeat == 'yearly') 'Lặp hằng năm',
                  if (entry.repeat == 'daily') 'Lặp hằng ngày',
                  if (entry.repeat == 'weekly') 'Lặp hằng tuần',
                  if (entry.details.isNotEmpty) entry.details,
                  if (entry.notification) 'Có thông báo hiện nội dung'
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(entry)),
            onTap: () => _edit(entry),
          )),
        ),
      );

  Widget _seasonPanel(bool rainy) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor:
                    rainy ? const Color(0xFFE9F1FA) : const Color(0xFFFFF1D5),
                child: Icon(
                    rainy ? Icons.umbrella_outlined : Icons.wb_sunny_outlined,
                    color: const Color(0xFFB85F7D))),
            const SizedBox(width: 10),
            Expanded(
                child: Text(rainy ? 'Mùa mưa' : 'Mùa nắng',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            TextButton(
                onPressed: _configureSeason, child: const Text('Tùy chỉnh'))
          ]),
          const SizedBox(height: 8),
          ...(rainy
                  ? [
                      'Mang áo mưa hoặc ô',
                      'Kiểm tra giày và túi chống nước',
                      'Chọn món nóng như canh, súp'
                    ]
                  : [
                      'Uống đủ nước, mang mũ và kính',
                      'Dùng kem chống nắng',
                      'Gợi ý đồ uống giải nhiệt'
                    ])
              .map((s) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 17, color: Color(0xFFB85F7D)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s))
                  ]))),
        ])),
      );

  Widget _dailyReminderCard() => SoftCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.notifications_active_outlined,
            color: Color(0xFFB85F7D)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nhắc hằng ngày theo mùa',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Tháng mưa: ${widget.store.seasonMonths.map((m) => 'T$m').join(', ')}',
              style: TextStyle(color: Colors.brown.shade400)),
          const SizedBox(height: 8),
          Text(
              'Giờ nhắc chung: ${widget.store.reminderHour.toString().padLeft(2, '0')}:00'),
          TextButton.icon(
              onPressed: _configureSeason,
              icon: const Icon(Icons.tune),
              label: const Text('Chọn tháng mùa mưa & giờ nhắc')),
        ])),
      ]));

  Widget _notificationGroupsCard() => SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bật/tắt từng nhóm thông báo',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Tên lịch và ghi chú có thể hiện ngoài màn hình khóa.',
              style: TextStyle(color: Colors.brown.shade400, fontSize: 12)),
          _groupSwitch(
              'season', 'Gợi ý mùa mưa / mùa nắng', Icons.wb_sunny_outlined),
          _groupSwitch('cycle', 'Nhắc chu kỳ', Icons.water_drop_outlined),
          _groupSwitch('anniversary', 'Kỷ niệm', Icons.celebration_outlined),
          _groupSwitch('health', 'Sức khỏe', Icons.health_and_safety_outlined),
          _groupSwitch('task', 'Việc chăm sóc', Icons.checklist),
        ]),
      );

  Widget _groupSwitch(String group, String label, IconData icon) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: const Color(0xFFB85F7D)),
        title: Text(label),
        value: widget.store.notificationEnabled(group),
        onChanged: (value) => _toggleGroup(group, value),
      );

  Future<void> _toggleGroup(String group, bool enabled) async {
    if (enabled && !await NotificationService.instance.requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Bạn chưa cấp quyền thông báo. Có thể bật quyền trong Cài đặt.')));
      }
      return;
    }
    await widget.store.saveNotificationGroup(group, enabled);
    await NotificationService.instance.reschedule(widget.store);
  }

  Future<void> _configureSeason() async {
    var months = widget.store.seasonMonths.toSet();
    var hour = widget.store.reminderHour;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: const Text('Mùa mưa & giờ nhắc'),
                  content: SizedBox(
                      width: 360,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Chọn các tháng được xem là mùa mưa:')),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 4,
                            children: List.generate(12, (i) {
                              final m = i + 1;
                              return FilterChip(
                                  label: Text('T$m'),
                                  selected: months.contains(m),
                                  onSelected: (v) => setDialog(() =>
                                      v ? months.add(m) : months.remove(m)));
                            })),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                            initialValue: hour,
                            decoration: const InputDecoration(
                                labelText: 'Giờ nhắc hằng ngày'),
                            items: List.generate(
                                24,
                                (h) => DropdownMenuItem(
                                    value: h,
                                    child: Text(
                                        '${h.toString().padLeft(2, '0')}:00'))),
                            onChanged: (v) {
                              if (v != null) setDialog(() => hour = v);
                            }),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () async {
                          await widget.store
                              .saveSeasonMonths(months.toList()..sort());
                          await widget.store.saveReminderHour(hour);
                          await NotificationService.instance
                              .reschedule(widget.store);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Lưu'))
                  ],
                )));
  }

  Future<void> _edit([PlannerEntry? entry]) async {
    final title = TextEditingController(text: entry?.title ?? '');
    final details = TextEditingController(text: entry?.details ?? '');
    DateTime? date = entry?.date;
    var priority = entry?.priority ?? 1;
    var notification = entry?.notification ?? true;
    var repeat = entry?.repeat ?? (_kind == 'Kỷ niệm' ? 'yearly' : 'none');
    var done = entry?.done ?? false;
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheet) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      22, 6, 22, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(entry == null ? 'Thêm $_kind' : 'Chỉnh sửa lịch',
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        TextField(
                            controller: title,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                                labelText: 'Tên sự kiện / công việc')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: details,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText:
                                    'Ghi chú, kế hoạch hoặc thông tin cần chuẩn bị')),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100));
                              if (picked != null) setSheet(() => date = picked);
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text(date == null
                                ? 'Chọn ngày'
                                : 'Ngày ${_date(date!)}')),
                        DropdownButtonFormField<String>(
                            initialValue: repeat,
                            decoration: const InputDecoration(
                                labelText: 'Lặp lại lịch nhắc'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'none', child: Text('Không lặp')),
                              DropdownMenuItem(
                                  value: 'daily', child: Text('Hằng ngày')),
                              DropdownMenuItem(
                                  value: 'weekly', child: Text('Hằng tuần')),
                              DropdownMenuItem(
                                  value: 'monthly', child: Text('Hằng tháng')),
                              DropdownMenuItem(
                                  value: 'yearly', child: Text('Hằng năm')),
                            ],
                            onChanged: (v) {
                              if (v != null) setSheet(() => repeat = v);
                            }),
                        if (_kind == 'Việc chăm sóc')
                          DropdownButtonFormField<int>(
                              initialValue: priority,
                              decoration:
                                  const InputDecoration(labelText: 'Ưu tiên'),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Thấp')),
                                DropdownMenuItem(
                                    value: 1, child: Text('Bình thường')),
                                DropdownMenuItem(value: 2, child: Text('Cao'))
                              ],
                              onChanged: (v) {
                                if (v != null) setSheet(() => priority = v);
                              }),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hiện nội dung thông báo'),
                            subtitle: const Text(
                                'Tên lịch và ghi chú có thể hiện trên màn hình khóa'),
                            value: notification,
                            onChanged: (v) => setSheet(() => notification = v)),
                        if (_kind == 'Việc chăm sóc')
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Đã hoàn thành'),
                              value: done,
                              onChanged: (v) =>
                                  setSheet(() => done = v ?? false)),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Lưu'))),
                      ])),
                )));
    if (saved == true && title.text.trim().isNotEmpty) {
      final item = PlannerEntry(
          id: entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          kind: _kind,
          title: title.text.trim(),
          details: details.text.trim(),
          date: date,
          priority: priority,
          done: done,
          notification: notification,
          repeat: repeat);
      await widget.store.savePlanner(item);
      if (notification &&
          !await NotificationService.instance.requestPermission() &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Đã lưu lịch; hãy cấp quyền thông báo để nhận lời nhắc.')));
      }
      await NotificationService.instance.reschedule(widget.store);
    }
    title.dispose();
    details.dispose();
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
