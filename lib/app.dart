import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'core/local_store.dart';
import 'core/security.dart';
import 'features/cycle/cycle_page.dart';
import 'features/home/home_page.dart';
import 'features/notebook/notebook_page.dart';
import 'features/outings/outings_page.dart';
import 'features/profile/profile_page.dart';
import 'features/reminders/reminders_page.dart';

const _rose = Color(0xFFB85F7D);
const _ink = Color(0xFF342630);

class LoveCareApp extends StatelessWidget {
  const LoveCareApp({super.key, required this.store});
  final LocalStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final accent = Color(store.themeColorValue);
        final soft =
            Color.alphaBlend(accent.withValues(alpha: .12), Colors.white);
        return MaterialApp(
          title: 'Cẩm nang chăm vợ yêu',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: soft,
            colorScheme: ColorScheme.fromSeed(
                seedColor: accent,
                primary: accent,
                onSurface: _ink,
                surface: Colors.white),
            appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFFFF8FA),
                foregroundColor: _ink,
                elevation: 0),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xFFF2E8EC))),
            ),
            inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFFFF8FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none)),
          ),
          home: LockGate(store: store),
        );
      });
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store});
  final LocalStore store;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ProfilePage.checkForUpdate(context, automatic: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
          store: widget.store,
          onOpen: (index) => setState(() => _index = index)),
      NotebookPage(store: widget.store),
      CyclePage(store: widget.store),
      OutingsPage(store: widget.store),
      RemindersPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(
          bottom: false, child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF5DCE5),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Sổ tay'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Chu kỳ'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Đi chơi'),
          NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: 'Nhắc nhở'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.store});
  final LocalStore store;
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked;
  final _pin = TextEditingController();
  final _auth = LocalAuthentication();
  bool _failed = false;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.store.hasPin;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.store.hasPin && mounted) {
      setState(() {
        _locked = true;
        _pin.clear();
      });
    }
  }

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final accepted = await verifyPin(_pin.text, widget.store.pinHash);
    if (!mounted) return;
    setState(() {
      _locked = accepted ? false : _locked;
      _failed = !accepted;
      _busy = false;
    });
    _pin.clear();
  }

  Future<void> _biometric() async {
    setState(() => _busy = true);
    try {
      final ok = await _auth.authenticate(
          localizedReason: 'Mở Cẩm nang chăm vợ yêu', biometricOnly: true);
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Không thể xác thực sinh trắc học. Hãy dùng mã PIN.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return MainShell(store: widget.store);
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFF5DCE5),
                child: Icon(Icons.lock_outline, size: 30, color: _rose)),
            const SizedBox(height: 18),
            const Text('Cẩm nang đang khóa',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 8),
            const Text('Nhập mã PIN để xem thông tin riêng tư.',
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            TextField(
                controller: _pin,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                onSubmitted: (_) => _unlock(),
                decoration: InputDecoration(
                    labelText: 'Mã PIN',
                    errorText: _failed ? 'Mã PIN chưa đúng' : null)),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _busy ? null : _unlock,
                    child: const Text('Mở khóa'))),
            if (!kIsWeb && widget.store.biometricEnabled)
              TextButton.icon(
                  onPressed: _busy ? null : _biometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Mở bằng sinh trắc học')),
          ])),
    ))));
  }
}
