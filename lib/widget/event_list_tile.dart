import 'package:flutter/material.dart';
import '../utils/glass_components.dart';

class EventListTile extends StatelessWidget {
  final String title;
  final String description;
  final Color themeColor;

  const EventListTile({
    super.key,
    required this.title,
    required this.description,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.7);

    return AuraGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      accentColor: themeColor,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_month_rounded, color: themeColor),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: muted, fontSize: 14),
        ),
      ),
    );
  }
}
