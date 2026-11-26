import 'package:material_ui/material_ui.dart';

class PageHeading extends StatelessWidget {
  const PageHeading(
      {super.key, required this.eyebrow, required this.title, this.subtitle});
  final String eyebrow;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFFB85F7D))),
          const SizedBox(height: 6),
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: const Color(0xFF342630))),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: Colors.brown.shade400))
          ],
        ]),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF342630)));
}

class SoftCard extends StatelessWidget {
  const SoftCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: padding, child: child));
}
