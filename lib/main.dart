import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'navigation/app_routes.dart';
import 'navigation/seller_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  runApp(const AleeSellerApp());
}

class AleeSellerApp extends StatelessWidget {
  const AleeSellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alee Seller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6B35),
        fontFamily: 'Poppins',
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: SellerNavigator.generateRoute,
    );
  }
}
