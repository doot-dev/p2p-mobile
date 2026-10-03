// TODO(build): placeholder until this feature is written.
import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen(this.kind, {super.key});
  final String kind;

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('LegalScreen')));
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('ContactScreen')));
}

class ShowScreen extends StatelessWidget {
  const ShowScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('ShowScreen')));
}
