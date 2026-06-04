import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/widgets/progress_dots.dart';

void main() {
  testWidgets('ProgressDots renders one dot per page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProgressDots(count: 4, activeIndex: 1)),
      ),
    );
    // 4 animated containers (one per dot).
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
