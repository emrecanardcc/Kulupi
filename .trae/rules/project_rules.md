# PROJECT CONSTITUTION

## 1. TECH STACK & ARCHITECTURE (Auto-Detected)
- **Language:** Dart
- **Framework:** Flutter
- **Styling/UI:** Material, Cupertino Icons, Custom Glass UI components, TableCalendar
- **State Management:** Native setState & StreamBuilder
- **Backend & Data:** Supabase (Auth, PostgREST Data API, Storage, Realtime)
- **Tooling & Libraries:** flutter_lints, flutter_launcher_icons, intl, image_picker, file_picker, curved_navigation_bar, flutter_localizations

- **Modules & Structure:**
  - `lib/models`: domain models (Club, Event, EventSpeaker, Profile, enums)
  - `lib/services`: integration services (AuthService, DatabaseService, NotificationService)
  - `lib/tabs`: screen widgets (Discover, MyClubs, ClubDetail, Admin tabs, Events)
  - `lib/web_admin`: administrative dashboard views
  - `lib/utils`: helpers (hex color, glass components)
  - `lib/widget`: reusable UI elements (notification bell, sponsor banner)

## 2. CRITICAL BEHAVIOR RULES (NON-NEGOTIABLE)
- **NO LAZY CODING:** Never use placeholders like `// ...` or truncated implementations. Always write the full implementation when editing a file.
- **Type Safety:** Follow Dart typing strictly. Avoid dynamic misuse; prefer explicit types in models and services.
- **Error Handling:** Implement robust error handling (try/catch in async calls, meaningful user feedback). Guard context usage after async work.
- **Comments:** Only comment on complex logic or decisions. Avoid obvious comments.

## 3. WORKFLOW & PROCESS
- **Planning:** For complex changes, briefly outline the plan before implementation.
- **File Integrity:** Do not remove existing code unless explicitly requested or necessary for a refactor. Preserve structure and conventions.
- **Verification:** Double-check imports, null-safety, and Supabase query syntax. Run `flutter analyze` after changes and address blocking issues.

## 4. CUSTOM RULES
- **Events & Speakers:**
  - An event can have multiple speakers (one-to-many).
  - Preferred fetch: `.from('events').select('*, event_speakers(*)')` when FK relationships exist.
  - Fallback: client-side merge (query speakers per event) when relationships or schema cache are missing.
  - Past-dated events must not be published; validate in UI and on the server.
- **Club Management (Mobile):**
  - Editable fields: `name`, `description`, `category`, `short_name`, `main_color (hex)`, `logo_path`, `banner_path`.
  - Member roles can be updated (baskan, baskan_yardimcisi, koordinator, uye). Ensure role mapping is consistent across UI and DB.
- **Top Bar & Navigation:**
  - App bar: left “Kulüpi”, center active page title. Notification bell on the right.
- **Sponsor Card Readability:**
  - Use a dark gradient overlay with white text to ensure readability over banners.
- **Profile UX:**
  - Remove redundant back button from profile header. Present identity-card style profile with all user data visible and a change-password modal.
- **Storage Conventions:**
  - Use Supabase Storage bucket `clubs` with folders `logos/` and `banners/`. Access via public URLs or signed URLs depending on policy.
- **Data Retrieval & Joins:**
  - Prefer Supabase joins for efficiency; when RLS or schema constraints block joins, switch to safe client-side composition and keep UI resilient.

## 5. SÜREÇ DİSİPLİNİ VE KALİTE STANDARTLARI
- Tembellik yok: kısmi/placeholder kod yasak. Her görev uçtan uca tamamlanır.
- Kontrollü değişiklik: yalnızca gerekli dosyalar düzenlenir, mevcut stil/pattern korunur.
- Komut detaylandırma: verilen talimatlar alt adımlara bölünür, plan oluşturulur, uygulanır.
- Doğrulama: değişiklik sonrası `flutter analyze` çalıştırılır, uyarılar incelenir, engelleyici hatalar düzeltilir.
- Hata dayanıklılığı: async işlerde try/catch, kullanıcıya anlamlı geri bildirim, context guard.
- Tutarlılık: Light/Dark mod paritesi, okunabilirlik ve kontrast ilkeleri zorunludur.
- Güvenlik: gizli anahtarlar/loglar yok; Supabase RLS ve yetkilendirme kurallarına uyum.

## 6. TASARIM SİSTEMİNE UYUM
- Bileşen önceliği: AuraGlassCard, AuraSearchField, ModernTheme kullan.
- Renkler: brand cyan ve gri ton skalası; light modda düşük parlaklık, belirgin ayrım.
- Tipografi: başlıklar kalın ve siyah (light), koyu modda beyaz; metinler okunur ağırlıkta.
- Cam efekt: light modda hafif koyu tint; navbar/kart zemininden net ayrışma.
- Spacing ve radius: mevcut dosyalardaki kavis ve padding değerleri referans alınır.

## 7. İŞLEYİŞ KURALLARI
- Görev takibi: karmaşık işlerde yapılacaklar oluşturulur ve tamamlandıkça işaretlenir.
- Araştırma: kod tabanında arama yapılarak kapsam belirlenir, ilgili dosyalar güncellenir.
- Assumption politikası: belirsizlikte makul varsayımla ilerlenir, uygulama içinde belgelenir.
- Sonuçların sunumu: yapılan değişiklikler açık, kısa maddelerle raporlanır; kaynak dosya linkleri verilir.
