import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

bool isPhone(BuildContext context) => MediaQuery.sizeOf(context).width < 600;
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;
double gutter(BuildContext context) => isPhone(context) ? 16 : 28;

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

final _dayMonth = DateFormat('d MMM');
final _dayMonthYear = DateFormat('d MMM y');
final _clock = DateFormat('h:mm a');
final _weekday = DateFormat('EEEE, d MMMM');

String fmtDay(DateTime d) => d.year == DateTime.now().year
    ? _dayMonth.format(d)
    : _dayMonthYear.format(d);

String fmtLongDay(DateTime d) => _weekday.format(d);

/// "Today", "Tomorrow", "Yesterday" or a short date.
String fmtDue(DateTime d) => switch (daysBetween(DateTime.now(), d)) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => fmtDay(d),
    };

String fmtWhen(DateTime d) => sameDay(d, DateTime.now())
    ? _clock.format(d)
    : '${fmtDay(d)}, ${_clock.format(d)}';

String ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return fmtDay(d);
}

String fmtMinutes(int m) =>
    m < 60 ? '${m}m' : '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

String pct(double v) => '${(v * 100).round()}%';

String plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

// ---------------------------------------------------------------------------
// Links
// ---------------------------------------------------------------------------

Future<void> openExternal(String url) async {
  final trimmed = url.trim();
  final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed');
  if (uri == null || !await launchUrl(uri)) {
    toast('Could not open that link');
  }
}

Future<void> dial(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  if (!await launchUrl(uri)) toast('Could not start a call on this device');
}

/// The workspace is served under /app/; the marketing site lives at the root.
Future<void> backToWebsite() =>
    launchUrl(Uri.base.resolve('/'), webOnlyWindowName: '_self');

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.onInk = true, this.size = 22});

  final bool onInk;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = onInk ? C.onInk : C.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: C.brand, width: size * 0.21),
          ),
        ),
        SizedBox(width: size * 0.12),
        Text('Morals', style: dx(size, color: fg)),
        SizedBox(width: size * 0.4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: onInk ? C.inkRaised : C.sunken,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: onInk ? C.inkLine : C.hairline),
          ),
          child: Text(
            'WORKSPACE',
            style: tx(9, w: FontWeight.w800, ls: 0.9,
                color: onInk ? C.onInkMuted : C.muted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// People
// ---------------------------------------------------------------------------

class Avatar extends StatelessWidget {
  const Avatar(this.user, {super.key, this.size = 28, this.tooltip = true});

  final AppUser? user;
  final double size;
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    final u = user;
    if (u == null) {
      return Tooltip(
        message: tooltip ? 'Unassigned' : '',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.sunken,
            border: Border.all(color: C.hairlineStrong),
          ),
          child: Icon(Icons.person_outline_rounded,
              size: size * 0.58, color: C.faint),
        ),
      );
    }
    final color = seedColor(u.id);
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        u.initials,
        style: tx(size * 0.38, w: FontWeight.w800, color: Colors.white, h: 1),
      ),
    );
    final photo = u.photoUrl;
    return Tooltip(
      message: tooltip ? u.name : '',
      child: photo == null
          ? initials
          : ClipOval(
              child: Image.network(
                photo,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initials,
              ),
            ),
    );
  }
}

class UserLabel extends StatelessWidget {
  const UserLabel(this.user, {super.key, this.size = 24, this.subtitle});

  final AppUser? user;
  final double size;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(user, size: size, tooltip: false),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Unassigned',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(13.5,
                    w: FontWeight.w600,
                    color: user == null ? C.muted : C.text),
              ),
              if (subtitle != null)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(12, color: C.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// White card with a hairline border. Lifts slightly on hover when tappable.
class Panel extends StatefulWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = kRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final lifted = tappable && _hover;
    final box = AnimatedContainer(
      duration: kMotion,
      padding: widget.padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: lifted ? C.hairlineStrong : C.hairline),
        boxShadow: [
          BoxShadow(
            color: C.ink.withValues(alpha: lifted ? 0.07 : 0),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.child,
    );
    if (!tappable) return box;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: box,
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = C.muted, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = Color.lerp(color, C.ink, 0.28)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tint(color, 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(11.5, w: FontWeight.w700, color: fg, h: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class DeptTag extends StatelessWidget {
  const DeptTag(this.dept, {super.key});

  final Dept dept;

  @override
  Widget build(BuildContext context) =>
      Tag(dept.label, color: deptColor(dept), icon: deptIcon(dept));
}

class PriorityMark extends StatelessWidget {
  const PriorityMark(this.priority, {super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    final icon = switch (priority) {
      TaskPriority.low => Icons.keyboard_arrow_down_rounded,
      TaskPriority.medium => Icons.drag_handle_rounded,
      TaskPriority.high => Icons.keyboard_arrow_up_rounded,
      TaskPriority.urgent => Icons.keyboard_double_arrow_up_rounded,
    };
    return Tooltip(
      message: '${priority.label} priority',
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Page chrome
// ---------------------------------------------------------------------------

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final phone = isPhone(context);
    final g = gutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(g, phone ? 16 : 28, g, phone ? 12 : 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: dx(phone ? 26 : 30)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: tx(14, color: C.muted)),
              ],
            ],
          ),
          if (actions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.count});

  final String text;
  final Widget? trailing;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(text, style: tx(15, w: FontWeight.w800)),
          if (count != null) ...[
            const SizedBox(width: 8),
            CountPill(count!),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill(this.count, {super.key, this.color});

  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c ?? C.sunken,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: tx(11.5,
            w: FontWeight.w800, color: c == null ? C.muted : Colors.white),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 24, vertical: compact ? 24 : 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: C.sunken,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: C.muted, size: 24),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: tx(16, w: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: tx(14, color: C.muted, h: 1.5)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing placeholder block shown while the first snapshot loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: C.sunken,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 5, this.height = 52});

  final int rows;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Skeleton(height: height, radius: kRadiusSm),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data visuals
// ---------------------------------------------------------------------------

class Bar extends StatelessWidget {
  const Bar(this.value, {super.key, this.color = C.brand, this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: C.sunken,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          widthFactor: v,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

class Ring extends StatelessWidget {
  const Ring({
    super.key,
    required this.value,
    this.size = 120,
    this.stroke = 10,
    this.color = C.brand,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.isNaN ? 0 : value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(v, stroke, color),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color);

  final double value;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = C.sunken;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}

/// Small bar chart: one bar per value, the last bar (today) is emphasised.
class MiniBars extends StatelessWidget {
  const MiniBars(this.values, {super.key, this.height = 56, this.target});

  final List<int> values;
  final double height;

  /// Optional reference line (e.g. a daily target).
  final int? target;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _BarsPainter(values, target)),
      );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.target);

  static const color = C.marketing;

  final List<int> values;
  final int? target;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final peak = math.max(
        values.fold<int>(0, math.max), math.max(target ?? 0, 1));
    final slot = size.width / values.length;
    final barWidth = math.min(slot * 0.62, 18.0);
    final base = Paint()..color = C.hairline;
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 1, size.width, 1), base);
    for (var i = 0; i < values.length; i++) {
      final last = i == values.length - 1;
      final h = values[i] == 0
          ? 2.0
          : math.max(3.0, (size.height - 4) * values[i] / peak);
      final left = slot * i + (slot - barWidth) / 2;
      final paint = Paint()
        ..color = values[i] == 0
            ? C.hairlineStrong
            : (last ? color : color.withValues(alpha: 0.38));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - 1 - h, barWidth, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
    final t = target;
    if (t != null && t > 0) {
      final y = size.height - 1 - (size.height - 4) * t / peak;
      final dash = Paint()
        ..color = C.faint
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values.toString() != values.toString() || old.target != target;
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = C.text,
    this.hint,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(12.5, w: FontWeight.w600, color: C.muted)),
              ),
              Icon(icon, size: 18, color: color == C.text ? C.faint : color),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: kMotion,
            child: Text(value, key: ValueKey(value), style: dx(30, color: color)),
          ),
          const SizedBox(height: 4),
          Text(hint ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tx(12, color: C.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.sunken,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: C.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(v),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: kMotion,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: v == selected ? C.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color:
                            v == selected ? C.hairline : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconOf != null) ...[
                        Icon(iconOf!(v),
                            size: 16,
                            color: v == selected ? C.text : C.muted),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        labelOf(v),
                        style: tx(13,
                            w: FontWeight.w700,
                            color: v == selected ? C.text : C.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact "Label: value ▾" filter. A null value means "All".
class FilterMenu<T> extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.textOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) textOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final active = v != null;
    return PopupMenuButton<(T?,)>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      onSelected: (r) => onChanged(r.$1),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: (null,),
          height: 40,
          child: _menuRow('All', v == null),
        ),
        for (final o in options)
          PopupMenuItem(
            value: (o,),
            height: 40,
            child: _menuRow(textOf(o), o == v),
          ),
      ],
      child: AnimatedContainer(
        duration: kMotion,
        height: 36,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: active ? tint(C.brand, 0.08) : C.surface,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: active ? C.brand : C.hairlineStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v == null ? label : '$label: ',
                style: tx(13, w: FontWeight.w600, color: C.muted)),
            if (v != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(textOf(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(13, w: FontWeight.w700)),
              ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 18, color: C.muted),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(String text, bool selected) => Row(
        children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    tx(14, w: selected ? FontWeight.w700 : FontWeight.w500)),
          ),
          if (selected)
            const Icon(Icons.check_rounded, size: 16, color: C.brand),
        ],
      );
}

class ToggleChip extends StatelessWidget {
  const ToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!selected),
        child: AnimatedContainer(
          duration: kMotion,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? tint(C.brand, 0.08) : C.surface,
            borderRadius: BorderRadius.circular(kRadiusSm),
            border:
                Border.all(color: selected ? C.brand : C.hairlineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : (icon ?? Icons.circle_outlined),
                size: 16,
                color: selected ? C.brand : C.muted,
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: tx(13,
                      w: FontWeight.w700,
                      color: selected ? C.text : C.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  const SearchBox({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
    this.width = 220,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final double? width;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        style: tx(14),
        textInputAction: TextInputAction.search,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 36),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 34, minHeight: 36),
          suffixIcon: _controller.text.isEmpty
              ? null
              : InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
        ),
      ),
    );
  }
}

/// Horizontal strip of filters that scrolls on narrow screens.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final g = gutter(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(g, 0, g, 12),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form fields
// ---------------------------------------------------------------------------

class Labeled extends StatelessWidget {
  const Labeled(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: tx(12.5, w: FontWeight.w700, color: C.muted)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

/// Two fields side by side on wide dialogs, stacked on phones.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 440) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      );
    });
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: enabled ? C.surface : C.canvas,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: enabled ? C.hairlineStrong : C.hairline),
        ),
        child: child,
      );
}

/// Controlled select styled like a text field.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.value,
    required this.options,
    required this.textOf,
    required this.onChanged,
    this.leadingOf,
    this.noneLabel,
    this.enabled = true,
  });

  final T? value;
  final List<T> options;
  final String Function(T) textOf;
  final ValueChanged<T?> onChanged;
  final Widget Function(T?)? leadingOf;

  /// When set, a "none" entry with this label is offered (value null).
  final String? noneLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final v = value;
    Widget row(T? o, {bool menu = false}) => Row(
          children: [
            if (leadingOf != null) ...[
              leadingOf!(o),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                o == null ? (noneLabel ?? 'Select') : textOf(o),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(14,
                    w: menu && o == v ? FontWeight.w700 : FontWeight.w500,
                    color: o == null ? C.muted : C.text),
              ),
            ),
          ],
        );
    final field = _FieldBox(
      enabled: enabled,
      child: Row(children: [
        Expanded(child: row(v)),
        if (enabled)
          const Icon(Icons.unfold_more_rounded, size: 18, color: C.muted),
      ]),
    );
    if (!enabled) return field;
    return LayoutBuilder(builder: (context, c) {
      return PopupMenuButton<(T?,)>(
        tooltip: '',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        constraints: BoxConstraints(
          minWidth: c.maxWidth.isFinite ? c.maxWidth : 200,
          maxWidth: c.maxWidth.isFinite ? math.max(c.maxWidth, 200) : 320,
          maxHeight: 360,
        ),
        onSelected: (r) => onChanged(r.$1),
        itemBuilder: (_) => [
          if (noneLabel != null)
            PopupMenuItem(value: (null,), height: 42, child: row(null, menu: true)),
          for (final o in options)
            PopupMenuItem(value: (o,), height: 42, child: row(o, menu: true)),
        ],
        child: field,
      );
    });
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'No date',
    this.allowPast = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hint;
  final bool allowPast;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final now = DateTime.now();
          final first = allowPast ? DateTime(now.year - 3) : dayOf(now);
          final initial = v != null && !v.isBefore(first) ? v : now;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: first,
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) onChanged(picked);
        },
        child: _FieldBox(
          child: Row(
            children: [
              const Icon(Icons.event_rounded, size: 18, color: C.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  v == null ? hint : '${fmtDue(v)}${_suffix(v)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tx(14, color: v == null ? C.muted : C.text),
                ),
              ),
              if (v != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(null),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded, size: 16, color: C.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _suffix(DateTime v) {
    final d = daysBetween(DateTime.now(), v);
    return d >= -1 && d <= 1 ? ' · ${fmtDay(v)}' : '';
  }
}

/// Wrap of single-select chips with generous hit targets.
class ChipChoice<T> extends StatelessWidget {
  const ChipChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.colorOf,
    this.iconOf,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final Color Function(T)? colorOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Builder(builder: (context) {
            final on = v == selected;
            final color = colorOf?.call(v) ?? C.brand;
            final fg = on ? Color.lerp(color, C.ink, 0.3)! : C.text;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: kMotion,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: on ? tint(color, 0.12) : C.surface,
                    borderRadius: BorderRadius.circular(kRadiusSm),
                    border: Border.all(
                        color: on ? color : C.hairlineStrong,
                        width: on ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconOf != null) ...[
                        Icon(iconOf!(v), size: 16, color: on ? fg : C.muted),
                        const SizedBox(width: 6),
                      ],
                      Text(labelOf(v),
                          style: tx(13.5, w: FontWeight.w700, color: fg)),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

/// Centered card on desktop, full-screen on phones. Forms pass
/// [dismissible] false so a stray click outside doesn't discard typing.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 560,
  bool dismissible = true,
}) {
  final phone = isPhone(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: C.ink.withValues(alpha: 0.45),
    builder: (ctx) => phone
        ? Dialog.fullscreen(backgroundColor: C.surface, child: builder(ctx))
        : Dialog(
            insetPadding: const EdgeInsets.all(24),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 780),
              child: builder(ctx),
            ),
          ),
  );
}

class DialogFrame extends StatelessWidget {
  const DialogFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.leadingActions = const [],
    this.padding = const EdgeInsets.all(20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final List<Widget> leadingActions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final phone = isPhone(context);
    final body = SingleChildScrollView(padding: padding, child: child);
    return SafeArea(
      child: Column(
        mainAxisSize: phone ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dx(20)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tx(13, color: C.muted)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          if (phone) Expanded(child: body) else Flexible(child: body),
          if (actions.isNotEmpty || leadingActions.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  ...leadingActions,
                  const Spacer(),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: C.ink.withValues(alpha: 0.45),
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(message),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: C.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class Col<T> {
  const Col(this.label, this.cell, {this.width, this.flex = 1, this.end = false});

  final String label;
  final Widget Function(T row) cell;

  /// Fixed width; when null the column flexes.
  final double? width;
  final int flex;

  /// Right-align (numbers).
  final bool end;
}

/// Dense table with hover rows. Scrolls sideways below [minWidth]. With
/// [shrinkWrap] false it must be given a bounded height and virtualises rows.
class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onTap,
    this.minWidth = 720,
    this.shrinkWrap = true,
    this.rowHeight = 54,
    this.footer,
    this.empty,
  });

  final List<Col<T>> columns;
  final List<T> rows;
  final void Function(T row)? onTap;
  final double minWidth;
  final bool shrinkWrap;
  final double rowHeight;

  /// Extra cells rendered as a totals row, aligned with [columns].
  final List<Widget>? footer;
  final Widget? empty;

  Widget _cells(List<Widget> cells, {required double height, Color? color}) {
    return Container(
      height: height,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            if (columns[i].width != null)
              SizedBox(width: columns[i].width, child: _align(i, cells[i]))
            else
              Expanded(flex: columns[i].flex, child: _align(i, cells[i])),
        ],
      ),
    );
  }

  Widget _align(int i, Widget child) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
          alignment:
              columns[i].end ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final header = _cells(
      [
        for (final c in columns)
          Text(c.label.toUpperCase(),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: eyebrow()),
      ],
      height: 40,
      color: const Color(0xFFFBFAF7),
    );

    Widget row(int i) {
      final r = rows[i];
      return _TableRow(
        onTap: onTap == null ? null : () => onTap!(r),
        divider: i < rows.length - 1,
        child: _cells([for (final c in columns) c.cell(r)], height: rowHeight),
      );
    }

    final foot = footer == null
        ? null
        : _cells(footer!, height: 48, color: const Color(0xFFFBFAF7));

    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < minWidth;
      Widget body;
      if (rows.isEmpty && empty != null) {
        body = shrinkWrap ? empty! : Expanded(child: empty!);
      } else if (shrinkWrap) {
        body = Column(children: [for (var i = 0; i < rows.length; i++) row(i)]);
      } else {
        body = Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemExtent: rowHeight + 1,
            itemBuilder: (_, i) => row(i),
          ),
        );
      }
      Widget table = Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(),
          body,
          if (foot != null && rows.isNotEmpty) ...[const Divider(), foot],
        ],
      );
      if (narrow) {
        table = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      }
      return Panel(padding: EdgeInsets.zero, child: table);
    });
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({required this.child, this.onTap, required this.divider});

  final Widget child;
  final VoidCallback? onTap;
  final bool divider;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: _hover ? const Color(0xFFFAF8F3) : C.surface,
        border: Border(
          bottom: BorderSide(
              color: widget.divider ? C.hairline : Colors.transparent),
        ),
      ),
      child: widget.child,
    );
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.onTap == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: row,
            ),
    );
  }
}

/// Convenience text cell.
Widget cellText(String text, {bool strong = false, Color color = C.text}) =>
    Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tx(13.5, w: strong ? FontWeight.w700 : FontWeight.w500, color: color),
    );

/// Row used in simple lists inside panels (hover highlight, optional tap).
class ListRow extends StatefulWidget {
  const ListRow({
    super.key,
    required this.child,
    this.onTap,
    this.divider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool divider;
  final EdgeInsetsGeometry padding;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: tappable && _hover ? const Color(0xFFFAF8F3) : C.surface,
        border: Border(
          bottom: BorderSide(
              color: widget.divider ? C.hairline : Colors.transparent),
        ),
      ),
      child: widget.child,
    );
    if (!tappable) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: row,
      ),
    );
  }
}

/// Lays children out in equal-width columns that wrap responsively.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 180,
    this.gap = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final fit = math.max(
          1,
          math.min(children.length,
              ((c.maxWidth + gap) / (minItemWidth + gap)).floor()));
      // Balance the rows (7 items that fit 6 across become 4 + 3, not 6 + 1).
      final rows = (children.length / fit).ceil();
      final perRow = (children.length / rows).ceil();
      final width = (c.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(width: width.floorToDouble(), child: child),
        ],
      );
    });
  }
}
