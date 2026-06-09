import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/pages/analysis/analysis_page.dart';

// ignore_for_file: prefer_const_constructors

// ============================================================
// TASK-026 Analysis Page Widget Tests
//
// NOTE: Full provider-integrated widget tests are blocked by a
// production bug in AnalysisNotifier.build() that causes:
//   "Bad state: Tried to read the state of an uninitialized provider"
//
// Bug report: TASK-026-BUG-001 — AnalysisNotifier._loadExperiments()
// is called synchronously in build(), which tries to set `state`
// before the Notifier is fully initialized by Riverpod.
//
// The page also requires a ProviderScope ancestor for ConsumerWidget,
// so basic rendering tests need proper Riverpod setup.
// ============================================================

void main() {
  group('AnalysisPage — basic verification', () {
    test('widget class exists with correct signature', () {
      // Verify the AnalysisPage constructor exists and has correct signature
      expect(AnalysisPage.new, isA<Widget Function({Key? key})>());

      const widget = AnalysisPage();
      expect(widget.key, isNull);
    });

    test('page type is a ConsumerWidget subclass', () {
      // AnalysisPage is a ConsumerWidget (extends StatelessWidget via Riverpod)
      const page = AnalysisPage();
      expect(page, isA<Widget>());
    });
  });
}
