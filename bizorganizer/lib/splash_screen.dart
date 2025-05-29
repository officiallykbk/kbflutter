import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:bizorganizer/main.dart'; // To access supabase instance
import 'package:bizorganizer/dashboard.dart'; // Import Dashboard
import 'package:bizorganizer/signin.dart'; // Or your primary home screen
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart'; // animated_splash_screen often uses this for transitions
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthState
import 'package:provider/provider.dart'; // For Consumer
import 'package:bizorganizer/providers/loading_provider.dart'; // For LoadingProvider & GlobalLoadingIndicator

class BizSplashScreen extends StatelessWidget {
  const BizSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder animation: A simple fading and sliding truck icon
    Widget truckAnimation = TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, double opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: EdgeInsets.only(left: opacity * 50.0), // Simple slide effect
            child: const Icon(Icons.local_shipping, size: 100, color: Colors.white),
          ),
        );
      },
    );

    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          truckAnimation,
          const SizedBox(height: 20),
          const Text(
            'BizOrganizer',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color from theme
      nextScreen: const AuthHandlerScreen(), // A new widget to handle auth check after splash
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.fade,
      duration: 2500, // Total duration of the splash screen
    );
  }
}

// Create a new simple stateless widget to handle the auth logic after splash.
// This was previously in MyApp's home.
class AuthHandlerScreen extends StatelessWidget {
  const AuthHandlerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming 'supabase' instance is globally available as in main.dart
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold( // Added Scaffold for proper display
            backgroundColor: Theme.of(context).colorScheme.primary,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          // Navigate to Dashboard via Navigator to ensure proper context and routing
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Stack(
                    children: [
                      Dashboard(), // The actual screen
                      Consumer<LoadingProvider>(
                        builder: (context, loadingProvider, child) {
                          return loadingProvider.isLoading
                              ? GlobalLoadingIndicator(loadState: true)
                              : SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          });
          // Return a placeholder while navigation is pending
          return Scaffold(backgroundColor: Theme.of(context).colorScheme.primary, body: const Center(child: CircularProgressIndicator(color: Colors.white)));
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Stack(
                    children: [
                      SignInScreen(), // The actual screen
                      Consumer<LoadingProvider>(
                        builder: (context, loadingProvider, child) {
                          return loadingProvider.isLoading
                              ? GlobalLoadingIndicator(loadState: true)
                              : SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          });
          // Return a placeholder while navigation is pending
          return Scaffold(backgroundColor: Theme.of(context).colorScheme.primary, body: const Center(child: CircularProgressIndicator(color: Colors.white)));
        }
      },
    );
  }
}
