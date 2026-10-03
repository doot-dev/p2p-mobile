// TODO(build): placeholder until this feature is written.
import 'package:flutter/material.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('PublicProfileScreen')));
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('MeScreen')));
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('EditProfileScreen')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('SettingsScreen')));
}
