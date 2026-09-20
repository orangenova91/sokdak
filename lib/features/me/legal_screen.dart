import 'package:flutter/material.dart';

import 'legal_texts.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final section in document.sections) ...[
              Text(section.heading, style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(section.body, style: textTheme.bodyMedium),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
