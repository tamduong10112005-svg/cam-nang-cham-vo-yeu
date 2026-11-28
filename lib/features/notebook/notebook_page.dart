import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/local_store.dart';
import '../../core/stored_image.dart';
import '../../shared/widgets.dart';

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  String _category = 'Tất cả';
  String _query = '';
  final _search = TextEditingController();
  final _categories = const [
    'Tất cả',
    'Món ăn',
    'Địa điểm',
    'Sở thích',
    'Nhật ký'
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final q = _query.trim().toLowerCase();
        final entries = widget.store.notes
            .where((e) =>
                (_category == 'Tất cả' || e.category == _category) &&
                (q.isEmpty ||
                    '${e.title} ${e.note} ${e.category} ${e.locationAddress} ${e.locationUrl}'
                        .toLowerCase()
                        .contains(q)))
            .toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Ghi lại')),
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PageHeading(
                eyebrow: 'Những điều nàng thích',
                title: 'Sổ tay của nàng',
                subtitle: 'Món ăn, nơi muốn đến, sở thích và kỷ niệm.'),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Tìm trong sổ tay',
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                })))),
            const SizedBox(height: 8),
            SizedBox(
                height: 42,
                child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      return ChoiceChip(
                          label: Text(item),
                          selected: _category == item,
                          onSelected: (_) => setState(() => _category = item));
                    })),
            const SizedBox(height: 8),
            Expanded(
                child: entries.isEmpty
                    ? _EmptyNotebook(onAdd: () => _edit())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return SoftCard(
                              child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _leading(entry),
                            title: Text(entry.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                [
                                  entry.category,
                                  if (entry.locationAddress.isNotEmpty)
                                    entry.locationAddress,
                                  if (entry.locationUrl.isNotEmpty)
                                    entry.locationUrl,
                                  if (entry.note.isNotEmpty) entry.note,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            trailing: Wrap(children: [
                              if (entry.category == 'Địa điểm')
                                IconButton(
                                    tooltip: 'Mở bản đồ',
                                    icon: const Icon(Icons.directions_outlined),
                                    onPressed: () => _openMap(entry)),
                              IconButton(
                                  tooltip: entry.favorite
                                      ? 'Bỏ yêu thích'
                                      : 'Yêu thích',
                                  icon: Icon(
                                      entry.favorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: const Color(0xFFB85F7D)),
                                  onPressed: () => widget.store.saveEntry(entry
                                      .copyWith(favorite: !entry.favorite))),
                              PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(entry);
                                    if (v == 'delete') _delete(entry);
                                  },
                                  itemBuilder: (context) => const [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Chỉnh sửa')),
                                        PopupMenuItem(
                                            value: 'delete', child: Text('Xóa'))
                                      ]),
                            ]),
                            onTap: () => _edit(entry),
                          ));
                        },
                      )),
          ]),
        );
      });

  Widget _leading(NoteEntry entry) {
    final path = entry.imagePath;
    if (path != null && storedImageExists(path)) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: storedImageWidget(path,
              width: 50, height: 50, fit: BoxFit.cover));
    }
    return CircleAvatar(
        backgroundColor: const Color(0xFFFFF1F5),
        child: Icon(_icon(entry.category), color: const Color(0xFFB85F7D)));
  }

  IconData _icon(String category) => switch (category) {
        'Món ăn' => Icons.restaurant,
        'Địa điểm' => Icons.place_outlined,
        'Nhật ký' => Icons.auto_stories_outlined,
        _ => Icons.favorite_border
      };

  Future<void> _openMap(NoteEntry entry) async {
    final uri = _locationUri(entry.locationUrl, entry.locationAddress);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Thêm đường link hoặc địa chỉ cụ thể để mở.')));
      }
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không mở được ứng dụng bản đồ.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không mở được ứng dụng bản đồ.')));
      }
    }
  }

  Uri? _locationUri(String link, String address) {
    final value = link.trim();
    if (value.isNotEmpty) {
      final withScheme = value.contains('://') ? value : 'https://$value';
      final uri = Uri.tryParse(withScheme);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty) {
        return uri;
      }
      return null;
    }
    final place = address.trim();
    if (place.isEmpty) return null;
    return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(place)}');
  }

  Future<void> _delete(NoteEntry entry) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Xóa khỏi sổ tay?'),
                content: Text('“${entry.title}” sẽ bị xóa khỏi thiết bị.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Giữ lại')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'))
                ]));
    if (yes == true) await widget.store.deleteEntry(entry.id);
  }

  Future<void> _edit([NoteEntry? entry]) async {
    final title = TextEditingController(text: entry?.title ?? '');
    final note = TextEditingController(text: entry?.note ?? '');
    final address = TextEditingController(
        text: entry?.locationAddress.isNotEmpty == true
            ? entry!.locationAddress
            : (entry?.category == 'Địa điểm' ? entry?.note ?? '' : ''));
    final locationUrl = TextEditingController(text: entry?.locationUrl ?? '');
    var category = entry?.category ?? 'Món ăn';
    var imagePath = entry?.imagePath;
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
                            entry == null
                                ? 'Ghi điều nàng thích'
                                : 'Chỉnh sửa ghi chú',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 21)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration:
                                const InputDecoration(labelText: 'Danh mục'),
                            items: const [
                              'Món ăn',
                              'Địa điểm',
                              'Sở thích',
                              'Nhật ký'
                            ]
                                .map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setSheet(() => category = v);
                            }),
                        const SizedBox(height: 12),
                        TextField(
                            controller: title,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                                labelText: category == 'Nhật ký'
                                    ? 'Tiêu đề kỷ niệm'
                                    : category == 'Địa điểm'
                                        ? 'Tên quán / địa điểm'
                                        : 'Tên / tiêu đề')),
                        const SizedBox(height: 12),
                        if (category == 'Địa điểm') ...[
                          TextField(
                              controller: address,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                  labelText: 'Địa chỉ cụ thể',
                                  hintText: 'Số nhà, đường, quận, thành phố')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: locationUrl,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                  labelText: 'Đường link địa điểm',
                                  hintText:
                                      'Google Maps, website hoặc link chia sẻ')),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                            controller: note,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            decoration: InputDecoration(
                                labelText: 'Ghi chú thêm',
                                hintText: _hint(category))),
                        const SizedBox(height: 10),
                        if (imagePath != null && storedImageExists(imagePath!))
                          ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: storedImageWidget(imagePath!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover)),
                        Row(children: [
                          TextButton.icon(
                              onPressed: () async {
                                try {
                                  final image = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: kIsWeb ? 65 : 82,
                                      maxWidth: kIsWeb ? 1000 : 1800);
                                  if (image != null) {
                                    final path = await widget.store
                                        .saveImageBytes(
                                            await image.readAsBytes());
                                    setSheet(() => imagePath = path);
                                  }
                                } on PlatformException catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Không thể truy cập ảnh trên thiết bị.')));
                                  }
                                }
                              },
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: Text(
                                  imagePath == null ? 'Thêm ảnh' : 'Đổi ảnh')),
                          if (imagePath != null)
                            TextButton(
                                onPressed: () =>
                                    setSheet(() => imagePath = null),
                                child: const Text('Gỡ ảnh'))
                        ]),
                        if (category == 'Địa điểm')
                          TextButton.icon(
                              onPressed: () {
                                final uri = _locationUri(
                                    locationUrl.text, address.text);
                                if (uri == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Nhập link hoặc địa chỉ cụ thể trước.')));
                                } else {
                                  launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Thử mở địa điểm trên bản đồ')),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Lưu vào sổ tay'))),
                      ])),
                )));
    if (saved == true && title.text.trim().isNotEmpty) {
      final oldPath = entry?.imagePath;
      await widget.store.saveEntry(NoteEntry(
          id: entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.text.trim(),
          category: category,
          note: note.text.trim(),
          locationAddress: category == 'Địa điểm' ? address.text.trim() : '',
          locationUrl: category == 'Địa điểm' ? locationUrl.text.trim() : '',
          favorite: entry?.favorite ?? false,
          imagePath: imagePath));
      if (oldPath != null && oldPath != imagePath) {
        await widget.store.deleteImage(oldPath);
      }
    } else if (imagePath != null && imagePath != entry?.imagePath) {
      await widget.store.deleteImage(imagePath!);
    }
    title.dispose();
    note.dispose();
    address.dispose();
    locationUrl.dispose();
  }

  String _hint(String category) => switch (category) {
        'Món ăn' => 'Nguyên liệu, món không thích, dị ứng, món muốn thử…',
        'Địa điểm' => 'Số điện thoại, món ngon, giá tham khảo, đánh giá…',
        'Sở thích' =>
          'Màu, hoa, nước hoa, mỹ phẩm, size, điều nàng không thích…',
        _ => 'Viết điều muốn lưu giữ, ngày tháng và kỷ niệm…',
      };
}

class _EmptyNotebook extends StatelessWidget {
  const _EmptyNotebook({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.menu_book_outlined,
                size: 54, color: Color(0xFFD9A5B6)),
            const SizedBox(height: 14),
            const Text('Sổ tay còn đang chờ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Lưu món nàng thích, nơi muốn đến và những kỷ niệm đáng nhớ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.brown.shade400)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Tạo ghi chú đầu tiên')),
          ])));
}
