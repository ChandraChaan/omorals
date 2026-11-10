import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';

/// Colour tokens.
abstract final class C {
  static const ink = Color(0xFF0B1020);
  static const inkRaised = Color(0xFF161C31);
  static const inkLine = Color(0xFF242B43);
  static const onInk = Color(0xFFF5F3EE);
  static const onInkMuted = Color(0xFF9AA1B9);

  static const canvas = Color(0xFFF5F3EE);
  static const sunken = Color(0xFFEFECE4);
  static const surface = Colors.white;
  static const hairline = Color(0xFFE6E2D8);
  static const hairlineStrong = Color(0xFFD3CEC1);

  static const text = Color(0xFF141826);
  static const muted = Color(0xFF6A7085);
  static const faint = Color(0xFF9DA2B3);

  static const brand = Color(0xFFFF5A1F);
  static const brandDeep = Color(0xFFE2480F);

  static const youtube = Color(0xFFE5383B);
  static const marketing = Color(0xFF0E9F7A);
  static const development = Color(0xFF4F6BED);

  static const warn = Color(0xFFE9A100);
  static const danger = Color(0xFFD92D20);
  static const success = Color(0xFF12A150);

  /// Project / avatar palette. `projects.color` is an index into this list.
  static const palette = <Color>[
    Color(0xFF4F6BED),
    Color(0xFFE5383B),
    Color(0xFF0E9F7A),
    Color(0xFFFF5A1F),
    Color(0xFF8B5CF6),
    Color(0xFFE9A100),
    Color(0xFF0EA5C6),
    Color(0xFFD6409F),
    Color(0xFF5B6478),
    Color(0xFF7A9B0F),
  ];
}

const kRadius = 14.0;
const kRadiusSm = 10.0;
const kMotion = Duration(milliseconds: 180);

const _tabular = [FontFeature.tabularFigures()];

/// Body text (Manrope).
TextStyle tx(
  double size, {
  FontWeight w = FontWeight.w500,
  Color color = C.text,
  double? h,
  double? ls,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
      fontFeatures: _tabular,
    );

/// Display text (Bricolage Grotesque) for page titles and big numbers.
TextStyle dx(
  double size, {
  FontWeight w = FontWeight.w700,
  Color color = C.text,
}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: 1.1,
      letterSpacing: -0.02 * size,
      fontFeatures: _tabular,
    );

/// Small all-caps label used for table headers and section eyebrows.
TextStyle eyebrow({Color color = C.muted}) =>
    tx(11, w: FontWeight.w700, color: color, ls: 0.6);

Color tint(Color c, [double alpha = 0.1]) => c.withValues(alpha: alpha);

Color deptColor(Dept d) => switch (d) {
      Dept.youtube => C.youtube,
      Dept.marketing => C.marketing,
      Dept.development => C.development,
    };

IconData deptIcon(Dept d) => switch (d) {
      Dept.youtube => Icons.play_circle_outline_rounded,
      Dept.marketing => Icons.headset_mic_outlined,
      Dept.development => Icons.code_rounded,
    };

Color roleColor(Role r) => switch (r) {
      Role.owner => C.brand,
      Role.admin => const Color(0xFF8B5CF6),
      Role.manager => C.development,
      Role.member => C.muted,
    };

Color taskStatusColor(TaskStatus s) => switch (s) {
      TaskStatus.todo => C.faint,
      TaskStatus.inProgress => C.development,
      TaskStatus.review => C.warn,
      TaskStatus.done => C.success,
    };

Color priorityColor(TaskPriority p) => switch (p) {
      TaskPriority.low => C.faint,
      TaskPriority.medium => C.development,
      TaskPriority.high => C.warn,
      TaskPriority.urgent => C.danger,
    };

Color stageColor(VideoStage s) => switch (s) {
      VideoStage.idea => const Color(0xFF8A90A6),
      VideoStage.script => const Color(0xFF4F6BED),
      VideoStage.voiceover => const Color(0xFF0EA5C6),
      VideoStage.editing => const Color(0xFFFF5A1F),
      VideoStage.thumbnail => const Color(0xFFD6409F),
      VideoStage.review => const Color(0xFFE9A100),
      VideoStage.scheduled => const Color(0xFF8B5CF6),
      VideoStage.published => const Color(0xFF12A150),
    };

Color leadStatusColor(LeadStatus s) => switch (s) {
      LeadStatus.fresh => C.development,
      LeadStatus.contacted => const Color(0xFF5B6478),
      LeadStatus.interested => C.marketing,
      LeadStatus.followUp => C.warn,
      LeadStatus.won => C.success,
      LeadStatus.lost => C.danger,
    };

Color outcomeColor(CallOutcome o) => switch (o) {
      CallOutcome.connected => C.development,
      CallOutcome.noAnswer => C.faint,
      CallOutcome.busy => const Color(0xFF5B6478),
      CallOutcome.callback => C.warn,
      CallOutcome.interested => C.marketing,
      CallOutcome.notInterested => C.danger,
      CallOutcome.converted => C.success,
      CallOutcome.wrongNumber => const Color(0xFF8A90A6),
    };

IconData outcomeIcon(CallOutcome o) => switch (o) {
      CallOutcome.connected => Icons.call_rounded,
      CallOutcome.noAnswer => Icons.phone_missed_rounded,
      CallOutcome.busy => Icons.phone_locked_rounded,
      CallOutcome.callback => Icons.phone_callback_rounded,
      CallOutcome.interested => Icons.thumb_up_alt_outlined,
      CallOutcome.notInterested => Icons.thumb_down_alt_outlined,
      CallOutcome.converted => Icons.emoji_events_outlined,
      CallOutcome.wrongNumber => Icons.phonelink_erase_rounded,
    };

IconData activityIcon(ActivityKind k) => switch (k) {
      ActivityKind.task => Icons.check_circle_outline_rounded,
      ActivityKind.video => Icons.movie_outlined,
      ActivityKind.call => Icons.call_outlined,
      ActivityKind.lead => Icons.person_add_alt_1_outlined,
      ActivityKind.team => Icons.groups_2_outlined,
    };

Color activityColor(ActivityKind k) => switch (k) {
      ActivityKind.task => C.development,
      ActivityKind.video => C.youtube,
      ActivityKind.call => C.marketing,
      ActivityKind.lead => C.warn,
      ActivityKind.team => C.brand,
    };

Color paletteColor(int index) => C.palette[index.abs() % C.palette.length];

/// Stable colour for a person, derived from their id.
Color seedColor(String seed) {
  var sum = 0;
  for (final u in seed.codeUnits) {
    sum = (sum * 31 + u) & 0x7fffffff;
  }
  return paletteColor(sum);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: C.brand,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFE6DB),
    onPrimaryContainer: C.brandDeep,
    secondary: C.ink,
    onSecondary: Colors.white,
    secondaryContainer: C.sunken,
    onSecondaryContainer: C.text,
    surface: C.surface,
    onSurface: C.text,
    onSurfaceVariant: C.muted,
    surfaceContainerLowest: C.surface,
    surfaceContainerLow: C.surface,
    surfaceContainer: C.surface,
    surfaceContainerHigh: C.surface,
    surfaceContainerHighest: C.sunken,
    surfaceTint: Colors.transparent,
    outline: C.hairlineStrong,
    outlineVariant: C.hairline,
    error: C.danger,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.canvas,
    splashFactory: NoSplash.splashFactory,
    hoverColor: C.ink.withValues(alpha: 0.04),
    highlightColor: C.ink.withValues(alpha: 0.05),
    focusColor: C.ink.withValues(alpha: 0.06),
  );

  final manrope = GoogleFonts.manropeTextTheme(base.textTheme)
      .apply(bodyColor: C.text, displayColor: C.text);
  // bodyLarge is what text fields use: 21px line + 27px padding = 48px tall,
  // matching SelectField and DateField.
  final textTheme = manrope.copyWith(bodyLarge: tx(14.5, h: 1.45));

  OutlineInputBorder border(Color c, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide: BorderSide(color: c, width: width),
      );

  final buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm));
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  final buttonText = tx(14, w: FontWeight.w700);

  return base.copyWith(
    textTheme: textTheme,
    dividerTheme:
        const DividerThemeData(color: C.hairline, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: C.muted, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: C.canvas,
      foregroundColor: C.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: dx(20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 13.5),
      hintStyle: tx(14, color: C.faint),
      labelStyle: tx(14, color: C.muted),
      floatingLabelStyle: tx(14, color: C.text, w: FontWeight.w600),
      errorStyle: tx(12, color: C.danger),
      border: border(C.hairlineStrong),
      enabledBorder: border(C.hairlineStrong),
      disabledBorder: border(C.hairline),
      focusedBorder: border(C.ink, 1.5),
      errorBorder: border(C.danger),
      focusedErrorBorder: border(C.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.sunken,
        disabledForegroundColor: C.faint,
        shape: buttonShape,
        padding: buttonPadding,
        minimumSize: const Size(0, 44),
        textStyle: buttonText,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        backgroundColor: C.surface,
        side: const BorderSide(color: C.hairlineStrong),
        shape: buttonShape,
        padding: buttonPadding,
        minimumSize: const Size(0, 44),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.text,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        minimumSize: const Size(0, 40),
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: C.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: C.hairline),
      ),
      titleTextStyle: dx(20),
      contentTextStyle: tx(14, color: C.muted, h: 1.5),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: C.ink.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: C.hairline),
      ),
      textStyle: tx(14),
      labelTextStyle: WidgetStatePropertyAll(tx(14)),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(C.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: C.hairline),
        )),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: C.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: tx(12, color: Colors.white),
      waitDuration: const Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.ink,
      contentTextStyle: tx(14, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: C.text,
      unselectedLabelColor: C.muted,
      labelStyle: tx(14, w: FontWeight.w700),
      unselectedLabelStyle: tx(14, w: FontWeight.w600),
      indicatorColor: C.brand,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: C.hairline,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: C.ink,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: C.brand,
      linearTrackColor: C.sunken,
      circularTrackColor: Colors.transparent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(6),
      thumbColor: WidgetStatePropertyAll(C.ink.withValues(alpha: 0.18)),
    ),
  );
}
