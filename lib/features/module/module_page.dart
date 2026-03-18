import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fh_sdui_v2/core/sdui/sdui_page.dart';

class ModulePage extends StatelessWidget {
  const ModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final moduleId = Get.parameters['id'] ?? 'pharmacy';
    return SduiPage(screenId: moduleId);
  }
}
