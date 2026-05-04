import 'package:flutter_test/flutter_test.dart';
import 'package:skillsbuild_recommender/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillsBuildApp());
    expect(find.byType(SkillsBuildApp), findsOneWidget);
  });
}
