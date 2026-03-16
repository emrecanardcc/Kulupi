# 🏗️ Kulüpi Proje Mimarisi ve Raporu

Bu doküman, **Kulüpi** (eski adıyla UniHub) platformunun teknik mimarisini, tasarım sistemini, işleyişini ve kullanılan teknolojileri detaylı bir şekilde açıklamaktadır.

---

## 1. Proje Özeti
**Kulüpi**, üniversite öğrencilerinin kampüs hayatını dijitalleştiren, kulüpleri keşfetmelerine, etkinliklere katılmalarına ve kendi topluluklarını yönetmelerine olanak sağlayan modern bir mobil platformdur. Proje hem bir mobil uygulama hem de üniversite ve kulüp yetkilileri için bir web yönetim paneli içerir.

---

## 2. Teknoloji Yığını (Tech Stack)

### **Frontend (Mobil & Web)**
- **Dil:** Dart
- **Framework:** Flutter (Cross-platform)
- **Durum Yönetimi (State Management):** Native `setState` ve `ChangeNotifierProvider` (Provider paketi).
- **Veri Akışı:** `StreamBuilder` ve `FutureBuilder` ile gerçek zamanlı veri senkronizasyonu.
- **Tasarım:** Custom **Aura Glass UI** (Cam efekti bazlı modern tasarım).

### **Backend (BaaS)**
- **Servis Sağlayıcı:** [Supabase](https://supabase.com/)
- **Veritabanı:** PostgreSQL (PostgREST API üzerinden erişim).
- **Kimlik Doğrulama (Auth):** Supabase Auth (E-posta/Şifre).
- **Dosya Depolama (Storage):** Supabase Storage (Logolar, bannerlar ve görseller için).
- **Gerçek Zamanlı Veri:** Supabase Realtime (Bildirimler ve güncellemeler).

---

## 3. Mimari Yapı (Klasör Yapısı)

Proje, temiz ve modüler bir yapı üzerine inşa edilmiştir:

- **`lib/models`**: Veri modelleri (Club, Event, Profile, University vb.).
- **`lib/services`**: Dış servis entegrasyonları (AuthService, DatabaseService, NotificationService).
- **`lib/tabs`**: Uygulamanın ana ekranları (Keşfet, Etkinlikler, Kulüplerim, Profil).
- **`lib/utils`**: Yardımcı sınıflar, tema tanımları ve görsel bileşenler (Glass UI).
- **`lib/widget` & `lib/widgets`**: Tekrar kullanılabilir UI elementleri.
- **`lib/web_admin`**: Web tabanlı yönetim paneli sayfaları.

---

## 4. Tasarım Sistemi ve Renk Paleti

Kulüpi, **"Aura Glass"** adı verilen, derinlik hissi veren, şeffaf ve neon renklerle desteklenmiş modern bir tasarım dilini benimser.

### **Ana Renkler**
- **Neon Cyan:** `#00FBFF` (Birincil aksan rengi)
- **Electric Purple:** `#8E2DE2` (İkincil aksan rengi)
- **Midnight Black:** `#050505` (Ana arka plan)
- **Deep Space:** `#0A0A12` (Yüzey rengi)

### **Tasarım Elementleri**
- **Glassmorphism:** `AuraGlassCard` bileşeni ile yüksek bulanıklık (blur: 25.0) ve ince beyaz kenarlıklar (border: 0.8).
- **Gradients:** Dinamik gradyan geçişleri (`primaryGradient`, `cyberMesh`).
- **Tipografi:** 'Inter' font ailesi, kalın başlıklar (`FontWeight.w900`) ve geniş harf aralıkları.

---

## 5. Uygulama İşleyişi (Flow)

### **A. Kullanıcı Deneyimi (Mobil)**
1. **Giriş/Kayıt:** Kullanıcılar üniversite, fakülte ve bölüm seçerek kayıt olurlar.
2. **Main Hub:** Uygulama açıldığında 4 ana sekmeli bir yapı karşılar:
   - **Keşfet:** Üniversitedeki tüm kulüplerin listelendiği alan.
   - **Etkinlikler:** Yaklaşan kampüs etkinliklerinin takvimi ve detayları.
   - **Kulüplerim:** Kullanıcının üye olduğu veya yönettiği kulüpler.
   - **Profil:** Kullanıcı bilgileri ve ayarlar.
3. **Kulüp Detay:** Kulüp hakkında bilgi, üyelik başvurusu ve etkinlik takvimi.

### **B. Yönetim Paneli (Web & Admin)**
- **Sistem Yönetimi:** Üniversitelerin, fakültelerin ve bölümlerin tanımlanması.
- **Kulüp Onayları:** Yeni kulüp başvurularının değerlendirilmesi.
- **İstatistikler:** Kullanıcı sayıları, aktif kulüpler ve etkinlik yoğunluğu takibi.

---

## 6. Kritik Özellikler
- **Çoklu Konuşmacı Desteği:** Etkinliklere birden fazla konuşmacı atanabilir.
- **Dinamik Bildirim Sistemi:** Bildirim çanı üzerinden anlık güncellemeler.
- **Rol Bazlı Erişim:** Üye, Koordinatör, Başkan Yardımcısı ve Başkan rolleri ile yetkilendirme.
- **Sponsorluk Alanları:** Kulüpler için özelleştirilmiş sponsor banner alanları.

---

## 7. Gelecek Planları
- AI tabanlı kulüp ve etkinlik öneri sistemi.
- Kulüp içi anlık mesajlaşma odaları.
- Dijital etkinlik biletleme ve QR kod ile katılım takibi.

---
*Bu rapor **Kulüpi** projesinin mevcut mimarisini temsil etmektedir.*
 veri tabanı 
 -- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.app_config (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  max_login_attempts integer DEFAULT 5,
  session_timeout_minutes integer DEFAULT 60,
  email_confirmation_expiry_hours integer DEFAULT 24,
  max_file_size_mb integer DEFAULT 10,
  allowed_file_types text DEFAULT 'jpg,jpeg,png,pdf,doc,docx'::text,
  app_name text DEFAULT 'UniHub'::text,
  app_description text DEFAULT 'Üniversite öğrencileri için sosyal platform'::text,
  maintenance_mode boolean DEFAULT false,
  email_verification_required boolean DEFAULT true,
  allow_registration boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT app_config_pkey PRIMARY KEY (id)
);
CREATE TABLE public.app_sponsors (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  description text,
  logo_path text,
  banner_path text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT app_sponsors_pkey PRIMARY KEY (id)
);
CREATE TABLE public.club_members (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  club_id bigint,
  user_id uuid,
  role text NOT NULL DEFAULT 'member'::text,
  status text NOT NULL DEFAULT 'pending'::text,
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT club_members_pkey PRIMARY KEY (id),
  CONSTRAINT club_members_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id),
  CONSTRAINT club_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.clubs (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  university_id bigint,
  name text NOT NULL,
  short_name text NOT NULL,
  description text,
  logo_path text,
  banner_path text,
  created_at timestamp with time zone DEFAULT now(),
  category text DEFAULT 'Genel'::text,
  main_color text DEFAULT '#00FFFF'::text,
  tags ARRAY DEFAULT '{}'::text[],
  status text DEFAULT 'active'::text,
  CONSTRAINT clubs_pkey PRIMARY KEY (id),
  CONSTRAINT clubs_university_id_fkey FOREIGN KEY (university_id) REFERENCES public.universities(id)
);
CREATE TABLE public.departments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  faculty_id bigint,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT departments_pkey PRIMARY KEY (id),
  CONSTRAINT departments_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id)
);
CREATE TABLE public.event_speakers (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  event_id bigint NOT NULL,
  full_name text NOT NULL,
  linkedin_url text,
  bio text,
  CONSTRAINT event_speakers_pkey PRIMARY KEY (id),
  CONSTRAINT event_speakers_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.events (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  club_id bigint,
  title text NOT NULL,
  description text,
  location text,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  image_path text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id)
);
CREATE TABLE public.faculties (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  university_id bigint,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT faculties_pkey PRIMARY KEY (id),
  CONSTRAINT faculties_university_id_fkey FOREIGN KEY (university_id) REFERENCES public.universities(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  full_name text NOT NULL,
  university_id bigint,
  created_at timestamp with time zone DEFAULT now(),
  first_name text,
  last_name text,
  birth_date date,
  personal_email text,
  faculty_id bigint,
  department_id bigint,
  is_verified boolean DEFAULT false,
  student_email text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_university_id_fkey FOREIGN KEY (university_id) REFERENCES public.universities(id),
  CONSTRAINT profiles_faculty_id_fkey FOREIGN KEY (faculty_id) REFERENCES public.faculties(id),
  CONSTRAINT profiles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id)
);
CREATE TABLE public.universities (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  short_name text NOT NULL,
  domain text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT universities_pkey PRIMARY KEY (id)
);