import 'package:flutter/material.dart';
import 'package:gearup/web_admin/admin_scaffold.dart';
import 'package:gearup/web_service/service_scaffold.dart';

class NavigationService {
  static void navigateToService(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ServiceScaffold()),
    );
  }

  static void navigateToAdmin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminScaffold()),
    );
  }

  static void openInNewTab(BuildContext context, Widget target) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => target),
    );
  }
}
