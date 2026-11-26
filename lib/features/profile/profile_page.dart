import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_update_service.dart';
import '../../core/local_store.dart';
import '../../core/notification_service.dart';
import '../../core/security.dart';
import '../../shared/widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store});
  final LocalStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              const PageHeading(
                  eyebrow: 'Không gian của hai người',
                  title: 'Hồ sơ',
                  subtitle: 'Cá nhân hóa cách cẩm nang đồng hành.'),
              SoftCard(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF5DCE5),
                          child:
                              Icon(Icons.favorite, color: Color(0xFFB85F7D))),
                      title: const Text('Tên gọi thân mật',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(store.nickname.isEmpty
                          ? 'Chưa thêm'
                          : store.nickname),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editNickname(context))),
              const SizedBox(height: 14),
              const SectionLabel('Sao lưu dữ liệu'),
              const SizedBox(height: 10),
              SoftCard(
                  child: Column(children: [
                const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.phone_android, color: Color(0xFFB85F7D)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Dữ liệu chỉ lưu trên thiết bị',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 5),
                            Text(
                                'Ứng dụng không gửi dữ liệu lên máy chủ. Tệp sao lưu chứa dữ liệu cá nhân; hãy lưu ở nơi riêng tư.',
                                style: TextStyle(height: 1.4)),
                          ])),
                    ]),
                const Divider(height: 24),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () => _export(context),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Tạo bản sao lưu'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () => _import(context),
                          icon: const Icon(Icons.restore),
                          label: const Text('Khôi phục'))),
                ]),
              ])),
              const SizedBox(height: 14),
              const SectionLabel('Khóa ứng dụng'),
              const SizedBox(height: 10),
              SoftCard(
                  child: Column(children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pin_outlined,
                        color: Color(0xFFB85F7D)),
                    title: Text(
                        store.hasPin ? 'Đổi hoặc tắt mã PIN' : 'Đặt mã PIN',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(store.hasPin
                        ? 'Ứng dụng yêu cầu mã khi mở lại'
                        : 'Khóa các ghi chú riêng tư'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configurePin(context)),
                if (store.hasPin)
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mở khóa bằng sinh trắc học'),
                      subtitle:
                          const Text('Face ID / vân tay nếu thiết bị hỗ trợ'),
                      value: store.biometricEnabled,
                      onChanged: (v) => _setBiometric(context, v)),
              ])),
              const SizedBox(height: 14),
              SoftCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('CẨM NANG CHĂM VỢ YÊU',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, letterSpacing: .3)),
                    const SizedBox(height: 6),
                    Text(
                        'Hiểu nàng hơn – Yêu nàng đúng cách – Đồng hành trọn đời.',
                        style: TextStyle(color: Colors.brown.shade400)),
                    const SizedBox(height: 10),
                    const Text('Phiên bản 1.0 · Lưu trữ cục bộ'),
                    const Divider(height: 24),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.system_update_alt,
                            color: Color(0xFFB85F7D)),
                        title: const Text('Cập nhật ứng dụng',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text(
                            'Kiểm tra và tải phiên bản mới từ GitHub'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _checkForUpdate(context)),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined,
                            color: Color(0xFFB85F7D)),
                        title: const Text('Chính sách quyền riêng tư'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPrivacyPolicy(context)),
                  ])),
              const SizedBox(height: 20),
              TextButton.icon(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa dữ liệu trên thiết bị'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700)),
            ]),
      );

  Future<void> _checkForUpdate(BuildContext context) async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật APK từ GitHub hiện chỉ hỗ trợ Android.')));
      return;
    }

    if (!AppUpdateService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bản phát hành này chưa được nối với kho GitHub.')));
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Đang kiểm tra phiên bản mới…')),
        ]),
      ),
    );
    AppRelease? release;
    Object? checkError;
    try {
      release = await AppUpdateService.checkForUpdate();
    } catch (error) {
      checkError = error;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (checkError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không kiểm tra được: $checkError')));
      return;
    }
    if (release == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ứng dụng đang ở phiên bản mới nhất.')));
      return;
    }
    final availableRelease = release;

    final install = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Có phiên bản ${availableRelease.version}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Text(availableRelease.releaseNotes.isEmpty
                ? 'Bạn có muốn tải và cài đặt bản cập nhật này không?'
                : availableRelease.releaseNotes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tải bản cập nhật'),
          ),
        ],
      ),
    );
    if (install != true || !context.mounted) return;

    try {
      final allowed = await AppUpdateService.ensureInstallPermission();
      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Hãy cho phép cài ứng dụng từ nguồn này trong Cài đặt, rồi quay lại bấm cập nhật lần nữa.')));
        }
        return;
      }
      if (!context.mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Đang tải bản cập nhật…')),
          ]),
        ),
      );
      var started = false;
      Object? downloadError;
      try {
        started = await AppUpdateService.downloadAndInstall(availableRelease);
      } catch (error) {
        downloadError = error;
      }
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (downloadError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Không tải được bản cập nhật: $downloadError')));
      } else if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Android chưa cho phép cài gói cập nhật.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không mở được trình cài đặt: $error')));
      }
    }
  }

  Future<void> _showPrivacyPolicy(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Quyền riêng tư'),
            content: const SizedBox(
                width: 440,
                height: 480,
                child: SingleChildScrollView(
                    child: Text(
                        '''Cẩm nang chăm vợ yêu lưu thông tin bạn nhập trên thiết bị này, gồm biệt danh, ghi chú, ảnh, kế hoạch và dữ liệu chu kỳ. Hồ sơ, ghi chú, lịch và cài đặt riêng tư được mã hóa trên thiết bị. Ảnh nằm trong vùng lưu trữ riêng của ứng dụng nhưng chưa được mã hóa riêng.

Ứng dụng không gửi dữ liệu lên máy chủ, không dùng quảng cáo, phân tích theo dõi hoặc AI. Ứng dụng không đọc dữ liệu sức khỏe từ Health Connect. Xác thực vân tay/khuôn mặt do hệ điều hành xử lý; ứng dụng chỉ nhận kết quả xác thực.

Khi bạn chủ động tạo bản sao lưu, ứng dụng tạo tệp JSON không mã hóa (có thể kèm ảnh) và mở bảng chia sẻ của hệ điều hành. Ứng dụng hoặc dịch vụ bạn chọn để lưu/chia sẻ tệp có chính sách riêng. Hãy giữ tệp sao lưu an toàn và xóa bản sao khi không cần.

Khi mở địa điểm, địa chỉ hoặc link bạn chọn được chuyển tới Google Maps hoặc ứng dụng/trình duyệt bên ngoài. Các dịch vụ đó có thể xử lý dữ liệu theo chính sách của họ.

Thông báo lịch có thể hiển thị tiêu đề và ghi chú bạn đã nhập trên màn hình khóa, tùy cài đặt thiết bị. Tắt hiển thị nội dung trong cài đặt thông báo của Android nếu bạn muốn ẩn.

Bạn có thể xóa dữ liệu trong ứng dụng hoặc gỡ ứng dụng. Tệp sao lưu đã xuất cần được xóa riêng. Dữ liệu chu kỳ chỉ là ước tính, không phải biện pháp tránh thai hay tư vấn y tế. Ứng dụng không phải thiết bị y tế, không chẩn đoán, điều trị, chữa khỏi hoặc phòng ngừa bệnh. Hãy hỏi chuyên gia y tế về tư vấn, chẩn đoán hoặc điều trị.

Liên hệ nhà phát triển: [thêm địa chỉ email hỗ trợ trước khi phát hành].'''))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'))
            ],
          ));

  Future<void> _editNickname(BuildContext context) async {
    final c = TextEditingController(text: store.nickname);
    final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Tên gọi thân mật'),
              content: TextField(
                  controller: c,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      hintText: 'Ví dụ: Mây, nàng thơ...')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Lưu'))
              ],
            ));
    if (save == true) await store.saveNickname(c.text);
    c.dispose();
  }

  Future<void> _export(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}${Platform.pathSeparator}cam-nang-cham-vo-yeu-${DateTime.now().toIso8601String().substring(0, 10)}.json');
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(await store.exportData()),
          flush: true);
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: 'Bản sao lưu Cẩm nang chăm vợ yêu',
          text: 'Tệp có dữ liệu cá nhân. Hãy lưu ở nơi riêng tư.'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tạo được bản sao lưu: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ['json']);
      if (result.isEmpty || !context.mounted) return;
      final data = jsonDecode(utf8.decode(await result.first.readAsBytes()))
          as Map<String, dynamic>;
      if (!context.mounted) return;
      final yes = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Khôi phục bản sao lưu?'),
                content: const Text(
                    'Dữ liệu hiện có sẽ được thay bằng dữ liệu trong tệp.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Khôi phục'))
                ],
              ));
      if (yes == true) {
        await store.importData(data);
        await NotificationService.instance.reschedule(store);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Đã khôi phục dữ liệu trên thiết bị.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tệp sao lưu không hợp lệ: $e')));
      }
    }
  }

  Future<void> _configurePin(BuildContext context) async {
    if (store.hasPin) {
      final current = TextEditingController();
      final valid = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Xác nhận mã PIN hiện tại'),
                content: TextField(
                    controller: current,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mã PIN')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () async {
                        final ok = await verifyPin(current.text, store.pinHash);
                        if (context.mounted) Navigator.pop(context, ok);
                      },
                      child: const Text('Tiếp tục'))
                ],
              ));
      current.dispose();
      if (valid != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Mã PIN chưa đúng.')));
        }
        return;
      }
      if (!context.mounted) return;
      final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
                  child: Wrap(children: [
                ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Đổi mã PIN'),
                    onTap: () => Navigator.pop(context, 'change')),
                ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Tắt mã PIN'),
                    onTap: () => Navigator.pop(context, 'off')),
              ])));
      if (action == 'off') {
        await store.savePinHash(null);
        return;
      }
      if (action != 'change') return;
    }
    if (!context.mounted) return;
    final first = TextEditingController();
    final second = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Đặt mã PIN'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: first,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration: const InputDecoration(
                        labelText: 'Mã PIN mới (4–8 số)')),
                TextField(
                    controller: second,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration:
                        const InputDecoration(labelText: 'Nhập lại mã PIN'))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Lưu'))
              ],
            ));
    if (ok == true) {
      if (first.text.length < 4 ||
          first.text.length > 8 ||
          !RegExp(r'^\d+$').hasMatch(first.text) ||
          first.text != second.text) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Mã PIN cần 4–8 chữ số và hai lần nhập phải khớp.')));
        }
      } else {
        await store.savePinHash(await createPinHash(first.text));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đã bật khóa PIN.')));
        }
      }
    }
    first.dispose();
    second.dispose();
  }

  Future<void> _setBiometric(BuildContext context, bool enabled) async {
    if (enabled) {
      try {
        final auth = LocalAuthentication();
        if (!await auth.isDeviceSupported() || !await auth.canCheckBiometrics) {
          throw StateError('unsupported');
        }
        if (!await auth.authenticate(
            localizedReason: 'Xác nhận bật mở khóa sinh trắc học',
            biometricOnly: true)) {
          return;
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Thiết bị chưa sẵn sàng cho sinh trắc học.')));
        }
        return;
      }
    }
    await store.setBiometricEnabled(enabled);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Xóa dữ liệu?'),
              content: const Text(
                  'Ghi chú, lịch, thông tin chu kỳ, mã PIN và cài đặt trên thiết bị này sẽ bị xóa.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ lại')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa dữ liệu'))
              ],
            ));
    if (clear == true) await store.clearAll();
  }
}
