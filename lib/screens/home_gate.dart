import 'package:flutter/material.dart';
import 'package:my_flutter_app/screens/homePageForAdmin.dart';

import '../services/token_storage.dart';
import 'home_screen.dart';

/// Opens the admin home for "Administrator", the normal home for everyone else.
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TokenStorage.isAdmin(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == true ? const HomeAdminScreen() : const HomeScreen();
      },
    );
  }
}