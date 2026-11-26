import 'package:material_ui/material_ui.dart';
import '../../core/local_store.dart';
import '../../core/notification_service.dart';
import '../../shared/widgets.dart';

class CyclePage extends StatelessWidget {
  const CyclePage({super.key, required this.store});
  final LocalStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final start = store.cycleStart;
        final next = start?.add(Duration(days: store.cycleLength));
        final today = DateTime.now();
        final days = next
            ?.difference(DateTime(today.year, today.month, today.day))
            .inDays;
        return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              const PageHeading(
                  eyebrow: 'Chăm sóc riêng tư',
                  title: 'Theo dõi chu kỳ',
                  subtitle: 'Ghi nhận nhẹ nhàng, dự đoán chỉ để tham khảo.'),
              SoftCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Icon(Icons.lock_outline, color: Color(0xFFB85F7D)),
                      const SizedBox(width: 8),
                      Text('Thông tin lưu trên thiết bị',
                          style: TextStyle(
                              color: Colors.brown.shade500, fontSize: 13))
                    ]),
                    const SizedBox(height: 18),
                    Text(
                        next == null
                            ? 'Chưa có dữ liệu chu kỳ'
                            : (days! <= 0
                                ? 'Kỳ tiếp theo dự kiến'
                                : 'Khoảng $days ngày nữa'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    if (next != null) ...[
                      const SizedBox(height: 5),
                      Text('Ngày dự kiến ${_date(next)}',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFB85F7D),
                              fontWeight: FontWeight.w700))
                    ],
                    const SizedBox(height: 18),
                    Wrap(spacing: 8, children: [
                      OutlinedButton.icon(
                          onPressed: () => _editCycle(context),
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: Text(start == null
                              ? 'Nhập kỳ gần nhất'
                              : 'Cập nhật thông tin')),
                      OutlinedButton.icon(
                          onPressed: () => _editLog(context),
                          icon: const Icon(Icons.note_add_outlined),
                          label: const Text('Ghi triệu chứng')),
                    ]),
                  ])),
              const SizedBox(height: 14),
              SoftCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Lưu ý quan trọng',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                        'Ngày hiển thị là ước tính dựa trên chu kỳ trung bình đã nhập. Chu kỳ có thể thay đổi; ứng dụng không chẩn đoán bệnh và không phải biện pháp tránh thai.',
                        style: TextStyle(
                            height: 1.5, color: Colors.brown.shade500)),
                  ])),
              if (start != null) ...[
                const SizedBox(height: 18),
                const SectionLabel('Thông tin hiện tại'),
                const SizedBox(height: 10),
                SoftCard(
                    child: Column(children: [
                  _InfoRow(label: 'Ngày bắt đầu gần nhất', value: _date(start)),
                  const Divider(height: 20),
                  _InfoRow(
                      label: 'Độ dài chu kỳ trung bình',
                      value: '${store.cycleLength} ngày')
                ])),
              ],
              const SizedBox(height: 20),
              const SectionLabel('Lịch sử chu kỳ & ghi chú'),
              const SizedBox(height: 10),
              if (store.cycles.isEmpty)
                const SoftCard(
                    child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                            'Các lần ghi chu kỳ và triệu chứng sẽ xuất hiện tại đây.'))),
              ...store.cycles.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SoftCard(
                      child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF5DCE5),
                        child: Icon(Icons.water_drop_outlined,
                            color: Color(0xFFB85F7D))),
                    title: Text('Bắt đầu ${_date(log.start)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        [
                          if (log.end != null) 'Kết thúc ${_date(log.end!)}',
                          if (log.symptoms.isNotEmpty) log.symptoms,
                          if (log.mood.isNotEmpty) 'Tâm trạng: ${log.mood}',
                          if (log.pain > 0) 'Đau ${log.pain}/5'
                        ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                        tooltip: 'Xóa ghi chú',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteLog(context, log)),
                    onTap: () => _editLog(context, log),
                  )))),
            ]);
      });

  Future<void> _editCycle(BuildContext context) async {
    DateTime selected = store.cycleStart ?? DateTime.now();
    final length = TextEditingController(text: '${store.cycleLength}');
    final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheet) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      22, 4, 22, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin chu kỳ',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 21)),
                        const SizedBox(height: 8),
                        Text('Chỉ lưu trên thiết bị này.',
                            style: TextStyle(color: Colors.brown.shade400)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selected,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now());
                              if (picked != null) {
                                setSheet(() => selected = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('Ngày bắt đầu: ${_date(selected)}')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: length,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Độ dài chu kỳ trung bình',
                                suffixText: 'ngày',
                                helperText: 'Nhập từ 21 đến 45 ngày')),
                        const SizedBox(height: 18),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Lưu thông tin'))),
                        if (store.cycleStart != null)
                          Center(
                              child: TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Xóa ngày chu kỳ đã lưu'))),
                      ]),
                )));
    if (result == true) {
      await store.saveCycle(
          selected, (int.tryParse(length.text) ?? 28).clamp(21, 45).toInt());
      await NotificationService.instance.reschedule(store);
    }
    if (result == false && store.cycleStart != null) {
      await store.saveCycle(null, store.cycleLength);
      await NotificationService.instance.reschedule(store);
    }
    length.dispose();
  }

  Future<void> _editLog(BuildContext context, [CycleLog? old]) async {
    DateTime start = old?.start ?? store.cycleStart ?? DateTime.now();
    DateTime? end = old?.end;
    final symptoms = TextEditingController(text: old?.symptoms ?? '');
    final mood = TextEditingController(text: old?.mood ?? '');
    var pain = old?.pain ?? 0;
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheet) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      22, 4, 22, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            old == null
                                ? 'Ghi nhận chu kỳ'
                                : 'Sửa ghi chú chu kỳ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 21)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: start,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now());
                              if (d != null) setSheet(() => start = d);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text('Ngày bắt đầu: ${_date(start)}')),
                        OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: end ?? start,
                                  firstDate: start,
                                  lastDate: DateTime.now());
                              if (d != null) setSheet(() => end = d);
                            },
                            icon: const Icon(Icons.stop),
                            label: Text(end == null
                                ? 'Thêm ngày kết thúc (nếu biết)'
                                : 'Ngày kết thúc: ${_date(end!)}')),
                        TextField(
                            controller: symptoms,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                                labelText:
                                    'Triệu chứng / vật dụng cần chuẩn bị')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: mood,
                            decoration:
                                const InputDecoration(labelText: 'Tâm trạng')),
                        const SizedBox(height: 8),
                        Text('Mức đau bụng: $pain/5'),
                        Slider(
                            value: pain.toDouble(),
                            min: 0,
                            max: 5,
                            divisions: 5,
                            label: '$pain',
                            onChanged: (v) => setSheet(() => pain = v.round())),
                        const SizedBox(height: 8),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Lưu ghi chú'))),
                      ])),
                )));
    if (saved == true) {
      final log = CycleLog(
          id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          start: start,
          end: end,
          symptoms: symptoms.text.trim(),
          mood: mood.text.trim(),
          pain: pain);
      await store.saveCycleLog(log);
      if (store.cycleStart == null || start.isAfter(store.cycleStart!)) {
        await store.saveCycle(start, store.cycleLength);
      }
      await NotificationService.instance.reschedule(store);
    }
    symptoms.dispose();
    mood.dispose();
  }

  Future<void> _deleteLog(BuildContext context, CycleLog log) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Xóa ghi chú chu kỳ?'),
                content: const Text('Không thể hoàn tác thao tác này.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'))
                ]));
    if (yes == true) await store.deleteCycle(log.id);
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(label, style: TextStyle(color: Colors.brown.shade400))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
      ]);
}
