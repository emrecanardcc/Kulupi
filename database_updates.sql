-- Kulüpi Sistem Ayarları Tablosu Oluşturma
-- Bu script, sistem ayarlarını yönetmek için gerekli tabloyu oluşturur

-- app_config tablosu oluştur
CREATE TABLE IF NOT EXISTS public.app_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    max_login_attempts INTEGER DEFAULT 5,
    session_timeout_minutes INTEGER DEFAULT 60,
    email_confirmation_expiry_hours INTEGER DEFAULT 24,
    max_file_size_mb INTEGER DEFAULT 10,
    allowed_file_types TEXT DEFAULT 'jpg,jpeg,png,pdf,doc,docx',
    app_name TEXT DEFAULT 'Kulüpi',
    app_description TEXT DEFAULT 'Üniversite öğrencileri için sosyal platform',
    maintenance_mode BOOLEAN DEFAULT false,
    email_verification_required BOOLEAN DEFAULT true,
    allow_registration BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Varsayılan ayarları ekle
INSERT INTO public.app_config (
    max_login_attempts,
    session_timeout_minutes,
    email_confirmation_expiry_hours,
    max_file_size_mb,
    allowed_file_types,
    app_name,
    app_description,
    maintenance_mode,
    email_verification_required,
    allow_registration
) VALUES (
    5,
    60,
    24,
    10,
    'jpg,jpeg,png,pdf,doc,docx',
    'Kulüpi',
    'Üniversite öğrencileri için sosyal platform',
    false,
    true,
    true
) ON CONFLICT DO NOTHING;

-- RLS (Row Level Security) politikasını etkinleştir
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Tüm kullanıcılar için okuma izni
CREATE POLICY "Allow all users to read app config" ON public.app_config
    FOR SELECT USING (true);

-- Tüm authenticated kullanıcılar için yazma izni (geliştirme ortamı için)
-- Üretim ortamında bu politikayı daha kısıtlayıcı hale getirin
CREATE POLICY "Allow authenticated users to update app config" ON public.app_config
    FOR ALL USING (auth.role() = 'authenticated');

-- updated_at sütununu otomatik güncelle
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_app_config_updated_at 
    BEFORE UPDATE ON public.app_config 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Basit bakım prosedürleri (örnek - gerçek implementasyon için Supabase dokümantasyonuna bakın)
CREATE OR REPLACE FUNCTION clear_cache()
RETURNS TEXT AS $$
BEGIN
    -- Bu fonksiyon örnek olarak oluşturulmuştur
    RETURN 'Cache cleared successfully';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_backup()
RETURNS TEXT AS $$
BEGIN
    -- Bu fonksiyon örnek olarak oluşturulmuştur
    RETURN 'Backup initiated successfully';
END;
$$ LANGUAGE plpgsql;

-- Diğer gerekli SQL güncellemeleri
-- clubs tablosuna status sütunu ekle (daha önce eksikti)
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- clubs tablosuna category sütunu ekle (daha önce eksikti)  
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general';

-- membership_requests tablosunu kontrol et ve gerekirse güncelle
-- (Eğer bu tablo yoksa ve club_members tablosunu kullanıyorsanız, bu kısmı atlayabilirsiniz)

-- club_members tablosunu güncelle (eğer varsa)
ALTER TABLE public.club_members 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Profil tablosunu güncelle (daha önce eklenen alanlar)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS faculty_id TEXT,
ADD COLUMN IF NOT EXISTS department_id TEXT,
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT,
ADD COLUMN IF NOT EXISTS birth_date DATE,
ADD COLUMN IF NOT EXISTS personal_email TEXT;

CREATE TABLE IF NOT EXISTS public.events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  club_id INTEGER NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.event_speakers (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  linkedin_url TEXT,
  bio TEXT
);

CREATE INDEX IF NOT EXISTS events_club_idx ON public.events (club_id);
CREATE INDEX IF NOT EXISTS events_start_time_idx ON public.events (start_time);
CREATE INDEX IF NOT EXISTS event_speakers_event_idx ON public.event_speakers (event_id);
