import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shopgenie_flutter/api_service.dart';
import 'package:shopgenie_flutter/models.dart';
import 'package:shopgenie_flutter/screens/login_screen.dart';
import 'package:shopgenie_flutter/theme/app_theme.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }
}

http.StreamedResponse _jsonRes(Object body, int code) {
  final bytes = utf8.encode(jsonEncode(body));
  return http.StreamedResponse(
    Stream.fromIterable([bytes]),
    code,
    headers: {'content-type': 'application/json'},
    contentLength: bytes.length,
  );
}

void _setTestViewport(WidgetTester tester) {
  tester.binding.window.physicalSizeTestValue = const Size(440, 900);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
}

void _clearTestViewport(WidgetTester tester) {
  tester.binding.window.clearPhysicalSizeTestValue();
  tester.binding.window.clearDevicePixelRatioTestValue();
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: child,
  );
}

void main() {
  group('LoginScreen Widget & Interaction Tests', () {
    testWidgets('Renders all required login UI components', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          onLoginSuccess: (_) {},
        ),
      ));

      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to manage your Kirana store'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text('Register Store'), findsOneWidget);
      expect(find.text('Worker Login'), findsOneWidget);
      
      _clearTestViewport(tester);
    });

    testWidgets('Shows validation errors on empty submission', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          onLoginSuccess: (_) {},
        ),
      ));

      // Tap the Sign In button to trigger validation
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Form validation messages should appear
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      
      _clearTestViewport(tester);
    });

    testWidgets('Toggles password visibility on suffix icon tap', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          onLoginSuccess: (_) {},
        ),
      ));

      // Find password visibility toggle icon button
      final toggleFinder = find.byType(IconButton);
      expect(toggleFinder, findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Scroll to the toggle and tap
      await tester.ensureVisible(toggleFinder);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      
      _clearTestViewport(tester);
    });

    testWidgets('Displays inline error banner when API returns 401', (tester) async {
      _setTestViewport(tester);
      final client = MockHttpClient((req) async {
        return _jsonRes({'detail': 'No active account found with the given credentials'}, 401);
      });
      final api = ApiService(client: client);

      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          apiService: api,
          onLoginSuccess: (_) {},
        ),
      ));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'bad_user');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong_pass');
      
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Invalid username or password. Please try again.'), findsOneWidget);
      
      _clearTestViewport(tester);
    });

    testWidgets('Invokes onLoginSuccess on successful 200 response', (tester) async {
      _setTestViewport(tester);
      User? loggedInUser;
      final client = MockHttpClient((req) async {
        if (req.url.path == '/api/auth/login/') {
          return _jsonRes({
            'access': 'mock_access_jwt',
            'refresh': 'mock_refresh_jwt',
            'user_id': 5,
            'role': 'OWNER',
          }, 200);
        } else if (req.url.path == '/api/shops/my_shop/') {
          return _jsonRes({
            'id': 1,
            'name': 'Ganesh Kirana Store',
            'category': 'Grocery',
          }, 200);
        }
        return _jsonRes({}, 404);
      });
      final api = ApiService(client: client);

      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          apiService: api,
          onLoginSuccess: (user) => loggedInUser = user,
        ),
      ));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'ganesh_owner');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(loggedInUser, isNotNull);
      expect(loggedInUser?.username, 'ganesh_owner');
      expect(loggedInUser?.shop?.name, 'Ganesh Kirana Store');
      
      _clearTestViewport(tester);
    });

    testWidgets('Toggles worker mode changes subtitle text', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          onLoginSuccess: (_) {},
        ),
      ));

      // Initially shows owner subtitle
      expect(find.text('Sign in to manage your Kirana store'), findsOneWidget);
      expect(find.text('Worker Login'), findsOneWidget);

      // Tap Worker Login toggle
      await tester.ensureVisible(find.text('Worker Login'));
      await tester.tap(find.text('Worker Login'));
      await tester.pumpAndSettle();

      // Should show worker subtitle
      expect(find.text('Sign in to access your staff dashboard'), findsOneWidget);
      expect(find.text('Owner Login'), findsOneWidget);
      
      _clearTestViewport(tester);
    });

    testWidgets('Shows register store dialog when Register Store is tapped', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_buildTestApp(
        child: LoginScreen(
          onLoginSuccess: (_) {},
        ),
      ));

      await tester.ensureVisible(find.text('Register Store'));
      await tester.tap(find.text('Register Store'));
      await tester.pumpAndSettle();

      // Dialog should appear with title
      expect(find.text('Register New Store'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Username*'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email Address*'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password*'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Kirana / Store Name*'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Category'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Phone Number'), findsOneWidget);
      
      _clearTestViewport(tester);
    });
  });
}