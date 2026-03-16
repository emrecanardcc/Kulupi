import 'package:flutter/material.dart';
import 'package:kulupi/utils/glass_components.dart';

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İstatistikler & Raporlar",
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          AuraGlassCard(
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Yakında Gelecek",
                  style: TextStyle(fontSize: 24, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  "Bu bölümde detaylı istatistikler ve raporlar yer alacak:",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
                Text(
                  "• Kullanıcı kayıt istatistikleri\n"
                  "• Kulüp aktivite raporları\n"
                  "• Etkinlik katılım analizleri\n"
                  "• Sponsor etkileşim metrikleri\n"
                  "• Aylık/dönemsel karşılaştırmalar\n"
                  "• Veri ihracatı (Excel/PDF)",
                  style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}