import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_vision/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('Gemini Vision Smoke Test', (WidgetTester tester) async {
    // 1. Load the GeminiVisionApp instead of MyApp
    await tester.pumpWidget(const GeminiVisionApp());

    // 2. Look for your "Scan Page" button instead of the '+' icon
    expect(find.text('Scan Page'), findsOneWidget);
    
    // 3. Verify the initial instruction text is there
    expect(find.text('Tap the camera to simplify a textbook page.'), findsOneWidget);
  });
}