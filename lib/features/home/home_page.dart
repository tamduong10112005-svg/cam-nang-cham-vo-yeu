import 'package:material_ui/material_ui.dart';
import '../../core/local_store.dart';
import '../../shared/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, required this.onOpen});
  final LocalStore store;
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final now = DateTime.now();
          final next = store.cycleStart?.add(Duration(days: store.cycleLength));
          final until =
              next?.difference(DateTime(now.year, now.month, now.day)).inDays;
          final todayTasks = store.planner.where((entry) {
            final date = entry.date;
            return !entry.done &&
                date != null &&
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }).toList();
          final upcoming = store.planner
              .where((entry) => entry.kind == 'Kỷ niệm' && entry.date != null)
              .map((entry) {
            final date = entry.date!;
            var occurrence = DateTime(now.year, date.month, date.day);
            if (occurrence.isBefore(DateTime(now.year, now.month, now.day))) {
              occurrence = DateTime(now.year + 1, date.month, date.day);
            }
            return (entry: entry, date: occurrence);
          }).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          final nextEvent = upcoming.isEmpty ? null : upcoming.first;
          final greeting = now.hour < 11
              ? 'Chào buổi sáng'
              : now.hour < 17
                  ? 'Chào buổi chiều'
                  : 'Chào buổi tối';
          return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(greeting,
                            style: TextStyle(
                                color: Colors.brown.shade400, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(
                            store.nickname.isEmpty
                                ? 'Hôm nay yêu nàng nhé'
                                : 'Hôm nay bên ${store.nickname} nhé',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF342630)))
                      ])),
                  const CircleAvatar(
                      backgroundColor: Color(0xFFF5DCE5),
                      child: Icon(Icons.favorite, color: Color(0xFFB85F7D)))
                ]),
                const SizedBox(height: 22),
                Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFB85F7D), Color(0xFFD88EA5)]),
                        borderRadius: BorderRadius.circular(26)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              color: Colors.white70),
                          const SizedBox(height: 14),
                          Text('Một điều nhỏ hôm nay',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: .8))),
                          const SizedBox(height: 4),
                          const Text('Lắng nghe nàng bằng cả sự chú tâm.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18)),
                          const SizedBox(height: 12),
                          Text('${now.day} tháng ${now.month}, ${now.year}',
                              style: const TextStyle(color: Colors.white))
                        ])),
                const SizedBox(height: 22),
                const SectionLabel('Quan tâm hôm nay'),
                const SizedBox(height: 10),
                SoftCard(
                    child: Column(children: [
                  _TodayRow(
                      icon: Icons.event_available,
                      title: 'Gợi ý chăm sóc theo mùa',
                      detail: 'Những việc nhỏ để nàng thoải mái hơn',
                      onTap: () => onOpen(3)),
                  const Divider(height: 22),
                  _TodayRow(
                      icon: Icons.water_drop_outlined,
                      title: 'Chu kỳ',
                      detail: until == null
                          ? 'Thêm thông tin để xem dự đoán'
                          : until <= 0
                              ? 'Dự kiến hôm nay · tham khảo'
                              : 'Còn khoảng $until ngày · dự đoán tham khảo',
                      onTap: () => onOpen(2)),
                  const Divider(height: 22),
                  _TodayRow(
                      icon: Icons.check_circle_outline,
                      title: 'Việc cần làm hôm nay',
                      detail: todayTasks.isEmpty
                          ? 'Chưa có việc nào được lên lịch hôm nay'
                          : '${todayTasks.length} việc cần quan tâm',
                      onTap: () => onOpen(3)),
                  const Divider(height: 22),
                  _TodayRow(
                      icon: Icons.celebration_outlined,
                      title: 'Kỷ niệm sắp tới',
                      detail: nextEvent == null
                          ? 'Thêm sinh nhật, ngày cưới hoặc ngày đặc biệt'
                          : '${nextEvent.entry.title} · ${nextEvent.date.day}/${nextEvent.date.month}/${nextEvent.date.year}',
                      onTap: () => onOpen(3)),
                ])),
                const SizedBox(height: 22),
                const SectionLabel('Sổ tay của nàng'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _QuickStat(
                          icon: Icons.restaurant,
                          value:
                              '${store.notes.where((e) => e.category == 'Món ăn').length}',
                          label: 'Món ăn')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _QuickStat(
                          icon: Icons.place_outlined,
                          value:
                              '${store.notes.where((e) => e.category == 'Địa điểm').length}',
                          label: 'Địa điểm')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _QuickStat(
                          icon: Icons.favorite_border,
                          value: '${store.notes.length}',
                          label: 'Ghi nhớ'))
                ]),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                    onPressed: () => onOpen(1),
                    icon: const Icon(Icons.add),
                    label: const Text('Ghi lại điều nàng yêu thích')),
              ]);
        },
      );
}

class _TodayRow extends StatelessWidget {
  const _TodayRow(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Row(children: [
        CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFF1F5),
            child: Icon(icon, size: 19, color: const Color(0xFFB85F7D))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(detail,
              style: TextStyle(color: Colors.brown.shade400, fontSize: 12))
        ])),
        const Icon(Icons.chevron_right, color: Colors.black38)
      ]));
}

class _QuickStat extends StatelessWidget {
  const _QuickStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 9),
      child: Column(children: [
        Icon(icon, color: const Color(0xFFB85F7D), size: 19),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(color: Colors.brown.shade400, fontSize: 11))
      ]));
}
