import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/result_analyzer_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/analyzer',
        builder: (context, state) => const ResultAnalyzerScreen(),
      ),
    ],
  );
}