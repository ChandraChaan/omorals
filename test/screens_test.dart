import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omorals/models.dart';
import 'package:omorals/screens/auth.dart';
import 'package:omorals/screens/shell.dart';
import 'package:omorals/store.dart';
import 'package:omorals/theme.dart';

import 'fixtures.dart';

// Smoke tests: every screen and dialog builds from seeded data (no Firebase)
// at desktop and phone sizes, and navigation mirrors the security rules.
//
// The test font is roughly twice as wide as Manrope, so RenderFlex overflow
// reports are not meaningful here and are ignored; any other framework error
// fails the test.

const _desktop = Size(1440, 900);
const _phone = Size(390, 844);

void _screenTest(
  String name,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(name, (tester) async {
    final onError = FlutterError.onError;
    final print = debugPrint;
    // google_fonts reports that it cannot download fonts inside tests.
    debugPrint = (String? message, {int? wrapWidth}) {};
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      onError?.call(details);
    };
    try {
      await body(tester);
    } finally {
      FlutterError.onError = onError;
      debugPrint = print;
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget home, {
  String as = 'owner',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(StoreScope(
    store: seededStore(as: as),
    child: MaterialApp(
      theme: buildTheme(),
      scaffoldMessengerKey: messengerKey,
      home: home,
    ),
  ));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await _settle(tester);
}

Future<void> _closeDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Close').last, warnIfMissed: false);
  await _settle(tester);
}

Finder _callTabs() => find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_TabButton');

void main() {
  for (final (label, size) in [('desktop', _desktop), ('phone', _phone)]) {
    group(label, () {
      _screenTest('auth and status screens build', (tester) async {
        await _pump(tester, size, const SignInScreen());
        expect(find.text('Welcome back'), findsOneWidget);
        await _tap(tester, find.text('New here? Create an account'));
        expect(find.text('Create your account'), findsOneWidget);
        expect(find.text('Your name'), findsOneWidget);

        await _pump(tester, size, const PendingScreen(), as: 'newbie');
        expect(find.text('Waiting for approval'), findsOneWidget);
        // The pending screen pulses forever; replace it so the test can end.
        await _pump(tester, size, const DisabledScreen(), as: 'gone');
        expect(find.text('Access removed'), findsOneWidget);
      });

      _screenTest('owner can open every destination', (tester) async {
        for (final dest in Dest.values) {
          await _pump(tester, size, AppShell(initial: dest));
          expect(tester.takeException(), isNull, reason: dest.name);
        }
      });

      _screenTest('task views and dialogs', (tester) async {
        await _pump(tester, size, const AppShell(initial: Dest.tasks));
        expect(find.text('Design appointment booking flow'), findsOneWidget);
        await _tap(tester, find.text('List'));
        expect(find.text('Write Diwali offer call script'), findsOneWidget);
        await _tap(tester, find.text('Assignee'));
        await _tap(tester, find.text('Arjun Rao').last);
        expect(find.text('Write Diwali offer call script'), findsNothing);
        expect(find.text('Set up push notifications'), findsOneWidget);
        await _tap(tester, find.text('New task'));
        expect(find.text('Create task'), findsOneWidget);
        await _tap(tester, find.text('Medium'));
        await _tap(tester, find.text('Urgent').last);
        await _closeDialog(tester);
        await _tap(tester, find.text('Projects'));
        expect(find.text('Clinic booking app'), findsWidgets);
        await _tap(tester, find.text('New project'));
        expect(find.text('Create project'), findsOneWidget);
      });

      _screenTest('video pipeline, table and dialog', (tester) async {
        await _pump(tester, size, const AppShell(initial: Dest.videos));
        expect(find.text('The honest woodcutter'), findsOneWidget);
        await _tap(tester, find.text('Table'));
        await _tap(tester, find.text('Tenali Rama and the thieves'));
        expect(find.text('History'), findsWidgets);
        expect(find.text('Save changes'), findsOneWidget);
        await _tap(tester, find.text('Published').last);
        // Pressed directly: the wide test font pushes the footer off a phone.
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Save changes'))
            .onPressed!();
        await _settle(tester);
        expect(find.text('Add the link before marking it published'),
            findsOneWidget);
      });

      _screenTest('calls tabs and dialogs for a manager', (tester) async {
        await _pump(tester, size, const AppShell(initial: Dest.calls));
        expect(_callTabs(), findsNWidgets(5));
        for (var i = 0; i < 5; i++) {
          await _tap(tester, _callTabs().at(i));
          expect(tester.takeException(), isNull, reason: 'tab $i');
        }
        await _tap(tester, find.text('Convert to lead'));
        expect(find.text('Who should follow up?'), findsOneWidget);
        await _closeDialog(tester);
        await _tap(tester, _callTabs().at(1));
        await _tap(tester, find.text('Paste leads'));
        await tester.enterText(find.byType(TextField).last,
            'Ravi Kumar, 98480 12345, Sri Sai Traders\nNo phone');
        await _settle(tester);
        expect(find.text('Import 1 lead'), findsOneWidget);
        await _closeDialog(tester);
        await _tap(tester, find.text('Suresh Babu'));
        expect(find.text('Call timeline'), findsOneWidget);
      });

      _screenTest('a caller logs calls but sees no scoreboard',
          (tester) async {
        await _pump(tester, size, const AppShell(initial: Dest.calls),
            as: 'caller');
        expect(_callTabs(), findsNWidgets(3));
        expect(find.text('Scoreboard'), findsNothing);
        expect(find.text('Padma Latha'), findsWidgets);
        await _tap(tester, find.text('Log'));
        expect(find.text('How did it go?'), findsOneWidget);
        await _tap(tester, find.text(CallOutcome.callback.label).last);
        expect(find.text('Next follow-up'), findsOneWidget);
        await _tap(tester, find.text(CallOutcome.notInterested.label).last);
        expect(find.text('Next follow-up'), findsNothing);
      });

      _screenTest('team page, approvals and member profile', (tester) async {
        await _pump(tester, size, const AppShell(initial: Dest.team));
        expect(find.text('Waiting for approval'), findsOneWidget);
        await _tap(tester, find.text('Approve'));
        expect(find.text('Which team are they in?'), findsOneWidget);
        await _closeDialog(tester);
        await _tap(tester, find.text('Ravi Teja'));
        expect(find.text('Calls · last 7 days'), findsOneWidget);
        await _tap(tester, find.text('Edit'));
        expect(find.text('Daily call target'), findsOneWidget);
        expect(find.text('Remove access'), findsOneWidget);
      });

      _screenTest('members only see what the rules allow', (tester) async {
        await _pump(tester, size, const AppShell(), as: 'dev');
        expect(find.textContaining('Arjun'), findsWidgets);
        expect(find.text('Overview'), findsNothing);
        expect(find.text('Videos'), findsNothing);
        expect(find.text('Calls & leads'), findsNothing);
        expect(find.text('Calls'), findsNothing);
        expect(find.text('Tasks'), findsOneWidget);

        await _pump(tester, size, const AppShell(initial: Dest.overview),
            as: 'dev');
        expect(find.text('Team pulse'), findsNothing);

        await _pump(tester, size, const AppShell(initial: Dest.team),
            as: 'dev');
        expect(find.text('Approve'), findsNothing);
        expect(find.byTooltip('Edit Ravi'), findsNothing);
      });
    });
  }

  _screenTest('dragging a task card to another column is accepted',
      (tester) async {
    await _pump(tester, _desktop, const AppShell(initial: Dest.tasks));
    final card = find.text('Set up push notifications');
    final target = find.text('In review');
    final from = tester.getCenter(card);
    final to = tester.getCenter(target) + const Offset(0, 200);
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Drop here'), findsNothing);
    await gesture.up();
    await _settle(tester);
    // The seeded store has no backend, so the write is reported as failed.
    expect(find.text('Something went wrong. Please try again.'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
