import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/state/sdui_state_controller.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/login/login_page.dart';
import 'features/module/module_page.dart';
import 'features/otp/otp_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SduiStateController());
    return GetMaterialApp(
      title: 'Flip Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8734A)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/otp', page: () => const OtpPage()),
        GetPage(name: '/dashboard', page: () => const DashboardPage()),
        GetPage(name: '/module/:id', page: () => const ModulePage()),
      ],
    );
  }
}
