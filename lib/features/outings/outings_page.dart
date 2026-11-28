import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/local_store.dart';
import '../../shared/widgets.dart';

String _formatMoney(int value) {
  final digits = value.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return '$grouped ₫';
}

Future<void> _shareTrip(
    OutingTrip trip, List<OutingStop> stops, int total) async {
  final lines = <String>[trip.name.toUpperCase(), ''];
  for (final stop in stops) {
    lines.add('${stop.timeRange} — ${stop.place}');
    if (stop.address.isNotEmpty) lines.add('Địa chỉ: ${stop.address}');
    if (stop.link.isNotEmpty) lines.add('Bản đồ: ${stop.link}');
    if (stop.note.isNotEmpty) lines.add('Ghi chú: ${stop.note}');
    if (stop.cost > 0) {
      lines.add('Chi phí dự kiến: ${_formatMoney(stop.cost)}');
    }
    lines.add('');
  }
  lines.add('Tổng chi phí dự kiến: ${_formatMoney(total)}');
  await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
}

class OutingsPage extends StatefulWidget {
  const OutingsPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<OutingsPage> createState() => _OutingsPageState();
}

class _OutingsPageState extends State<OutingsPage> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final trips = widget.store.outingTrips;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Tạo mục đi chơi')),
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PageHeading(
                eyebrow: 'Một ngày thật đáng nhớ',
                title: 'Lịch đi chơi',
                subtitle: 'Tạo kế hoạch riêng rồi thêm lịch trình bên trong.'),
            Expanded(
                child: trips.isEmpty
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map_outlined,
                                      size: 54, color: Color(0xFFB85F7D)),
                                  const SizedBox(height: 12),
                                  const Text('Chưa có mục đi chơi nào',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Tạo mục mới và đặt tên cho chuyến đi.',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                      onPressed: _create,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Tạo mục đi chơi')),
                                ])))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        children: trips.map(_tripCard).toList()))
          ]),
        );
      });

  Widget _tripCard(OutingTrip trip) {
    final stops =
        widget.store.outings.where((stop) => stop.tripId == trip.id).toList();
    final total = stops.fold<int>(0, (sum, stop) => sum + stop.cost);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
            child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                minVerticalPadding: 6,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1F5),
                    child: Icon(Icons.map_outlined, color: Color(0xFFB85F7D))),
                title: Text(trip.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${stops.length} điểm · ${_formatMoney(total)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _rename(trip);
                      if (value == 'delete') {
                        widget.store.deleteOutingTrip(trip.id);
                      }
                      if (value == 'share') {
                        _shareTrip(trip, stops, total);
                      }
                    },
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'share',
                              child: Text('Chia sẻ lịch trình')),
                          PopupMenuItem(
                              value: 'rename', child: Text('Đổi tên')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Xóa mục')),
                        ]),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => _OutingDetailPage(
                            store: widget.store, trip: trip))))));
  }

  Future<String?> _nameDialog({String name = ''}) async {
    final controller = TextEditingController(text: name);
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(name.isEmpty ? 'Đặt tên mục đi chơi' : 'Đổi tên mục'),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Tên kế hoạch',
                      hintText: 'Ví dụ: Kỷ niệm ngày cưới')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: const Text('Lưu')),
              ],
            ));
    controller.dispose();
    return result?.trim();
  }

  Future<void> _create() async {
    final name = await _nameDialog();
    if (name == null || name.isEmpty) return;
    await widget.store.saveOutingTrip(OutingTrip(
        id: DateTime.now().microsecondsSinceEpoch.toString(), name: name));
  }

  Future<void> _rename(OutingTrip trip) async {
    final name = await _nameDialog(name: trip.name);
    if (name == null || name.isEmpty) return;
    await widget.store.saveOutingTrip(OutingTrip(id: trip.id, name: name));
  }
}

class _OutingDetailPage extends StatefulWidget {
  const _OutingDetailPage({required this.store, required this.trip});
  final LocalStore store;
  final OutingTrip trip;
  @override
  State<_OutingDetailPage> createState() => _OutingDetailPageState();
}

class _OutingDetailPageState extends State<_OutingDetailPage> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final stops = widget.store.outings
            .where((stop) => stop.tripId == widget.trip.id)
            .toList()
          ..sort((a, b) {
            final aOrder = int.tryParse(a.id);
            final bOrder = int.tryParse(b.id);
            if (aOrder != null && bOrder != null) {
              return aOrder.compareTo(bOrder);
            }
            return a.id.compareTo(b.id);
          });
        final totalCost = stops.fold<int>(0, (sum, stop) => sum + stop.cost);
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm khung giờ')),
          body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
                  child: Row(children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Danh sách mục đi chơi'),
                    Expanded(
                        child: Text(widget.trip.name,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800))),
                  ])),
              const PageHeading(
                  eyebrow: 'Kế hoạch của hai người',
                  title: 'Lịch trình',
                  subtitle: 'Lên lịch từng khung giờ và địa điểm.'),
              Expanded(
                  child: stops.isEmpty
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.map_outlined,
                                        size: 54, color: Color(0xFFB85F7D)),
                                    const SizedBox(height: 12),
                                    const Text(
                                        'Chuyến đi của hai bạn bắt đầu từ đây',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Thêm khung giờ, nơi muốn đến, ghi chú và ảnh kỷ niệm.',
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                        onPressed: () => _edit(),
                                        icon: const Icon(Icons.add),
                                        label: const Text(
                                            'Lên lịch điểm đến đầu tiên')),
                                  ])))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                              if (stops.isNotEmpty)
                                SoftCard(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(children: [
                                        const Icon(Icons.payments_outlined,
                                            color: Color(0xFFB85F7D)),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                            child: Text('Tổng chi phí dự kiến',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700))),
                                        Text(_money(totalCost),
                                            style: const TextStyle(
                                                fontSize: 18,
                                                color: Color(0xFFB85F7D),
                                                fontWeight: FontWeight.w800)),
                                      ]),
                                    ])),
                              const SizedBox(height: 12),
                              ...List.generate(stops.length,
                                  (index) => _card(stops[index], index + 1)),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  onPressed: () => _edit(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm điểm đến tiếp theo')),
                            ]))
            ]),
          ),
        );
      });

  Widget _card(OutingStop s, int sequence) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF5DCE5),
              child: Text('$sequence',
                  style: const TextStyle(
                      color: Color(0xFFB85F7D), fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s.timeRange,
                    style: const TextStyle(
                        color: Color(0xFFB85F7D), fontWeight: FontWeight.w800)),
                Text(s.place,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ])),
          PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _edit(s);
                if (v == 'delete') widget.store.deleteOutingStop(s.id);
              },
              itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa'))
                  ]),
        ]),
        if (s.imagePath != null && File(s.imagePath!).existsSync()) ...[
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(s.imagePath!),
                  width: double.infinity, height: 190, fit: BoxFit.cover))
        ],
        if (s.address.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8), child: Text(s.address)),
        if (s.cost > 0)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Dự kiến: ${_money(s.cost)}',
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        if (s.note.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s.note, style: const TextStyle(height: 1.4))),
        if (s.link.isNotEmpty || s.address.isNotEmpty)
          TextButton.icon(
              onPressed: () => _open(s),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Mở địa điểm trên bản đồ')),
      ])));

  Uri? _uri(String link, String address) {
    final raw = link.trim();
    if (raw.isNotEmpty) {
      final u = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
      return u != null &&
              (u.scheme == 'http' || u.scheme == 'https') &&
              u.host.isNotEmpty
          ? u
          : null;
    }
    if (address.trim().isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/',
        {'api': '1', 'query': address.trim()});
  }

  String _money(int value) {
    final digits = value.toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
      grouped.write(digits[i]);
    }
    return '$grouped ₫';
  }

  Future<void> _open(OutingStop s) async {
    final u = _uri(s.link, s.address);
    if (u == null) {
      return;
    }
    try {
      if (!await launchUrl(u, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không mở được địa điểm.')));
      }
    } catch (_) {}
  }

  Future<void> _edit([OutingStop? old]) async {
    final time = TextEditingController(text: old?.timeRange ?? '');
    final place = TextEditingController(text: old?.place ?? '');
    final address = TextEditingController(text: old?.address ?? '');
    final link = TextEditingController(text: old?.link ?? '');
    final note = TextEditingController(text: old?.note ?? '');
    final cost = TextEditingController(
        text: old == null || old.cost == 0 ? '' : old.cost.toString());
    var photo = old?.imagePath;
    final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
                padding: EdgeInsets.fromLTRB(
                    22, 4, 22, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(old == null ? 'Thêm khung giờ' : 'Sửa điểm đến',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 21)),
                      const SizedBox(height: 16),
                      TextField(
                          controller: time,
                          decoration: const InputDecoration(
                              labelText: 'Khung giờ',
                              hintText: 'Ví dụ: 08:00 – 10:00')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: place,
                          decoration:
                              const InputDecoration(labelText: 'Nơi cần đi')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: address,
                          decoration: const InputDecoration(
                              labelText: 'Địa chỉ cụ thể')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: link,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                              labelText: 'Link bản đồ (nếu có)')),
                      const SizedBox(height: 12),
                      TextField(
                          controller: note,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(labelText: 'Ghi chú')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: cost,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Chi phí dự kiến (đồng)',
                              hintText: 'Để trống nếu chưa biết')),
                      const SizedBox(height: 10),
                      if (photo != null && File(photo!).existsSync())
                        ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(photo!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover)),
                      Row(children: [
                        TextButton.icon(
                            onPressed: () async {
                              try {
                                final x = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 82,
                                    maxWidth: 1800);
                                if (x != null) {
                                  final p = await widget.store
                                      .saveImageBytes(await x.readAsBytes());
                                  setSheet(() => photo = p);
                                }
                              } on PlatformException {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Không thể mở thư viện ảnh.')));
                                }
                              }
                            },
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label:
                                Text(photo == null ? 'Thêm ảnh' : 'Đổi ảnh')),
                        if (photo != null)
                          TextButton(
                              onPressed: () => setSheet(() => photo = null),
                              child: const Text('Gỡ ảnh'))
                      ]),
                      TextButton.icon(
                          onPressed: () async {
                            final u = _uri(link.text, address.text);
                            if (u == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Nhập link hoặc địa chỉ trước.')));
                              return;
                            }
                            await launchUrl(u,
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.directions_outlined),
                          label: const Text('Thử mở bản đồ')),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () {
                                if (time.text.trim().isEmpty ||
                                    place.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Hãy nhập khung giờ và nơi cần đi.')));
                                  return;
                                }
                                Navigator.pop(ctx, true);
                              },
                              child: const Text('Lưu điểm đến'))),
                    ])))));
    if (saved == true) {
      await widget.store.saveOutingStop(OutingStop(
          id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          tripId: widget.trip.id,
          timeRange: time.text.trim(),
          place: place.text.trim(),
          address: address.text.trim(),
          link: link.text.trim(),
          note: note.text.trim(),
          imagePath: photo,
          cost:
              int.tryParse(cost.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0));
      if (old?.imagePath != null && old!.imagePath != photo) {
        await widget.store.deleteImage(old.imagePath!);
      }
    } else if (photo != null && photo != old?.imagePath) {
      await widget.store.deleteImage(photo!);
    }
    time.dispose();
    place.dispose();
    address.dispose();
    link.dispose();
    note.dispose();
    cost.dispose();
  }
}

