import 'package:flutter/material.dart';
import 'package:kulupi/utils/glass_components.dart';

class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);

    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      body: Center(
        child: AuraGlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upcoming_rounded, color: AuraTheme.kAccentCyan, size: 48),
              const SizedBox(height: 12),
              Text(
                "Yakında",
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Bu bölüm üzerinde çalışıyoruz.",
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
