-- KULÜP VERİTABANI MİGRASYON ADIMLARI
-- Bu script'i Supabase Dashboard > SQL Editor'den parça parça çalıştırın

-- ADIM 1: Enum tiplerini oluştur
CREATE TYPE public.club_role AS ENUM ('baskan', 'baskan_yardimcisi', 'koordinator', 'uye');
CREATE TYPE public.membership_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.club_status AS ENUM ('active', 'inactive', 'pending');

-- ADIM 2: Mevcut verileri yedekle (isteğe bağlı)
-- CREATE TABLE club_members_backup AS SELECT * FROM public.club_members;
-- CREATE TABLE clubs_backup AS SELECT * FROM public.clubs;

-- ADIM 3: Club_members tablosunu güncelle
-- Önce mevcut constraint'leri kaldır
ALTER TABLE public.club_members DROP CONSTRAINT IF EXISTS club_members_role_check;
ALTER TABLE public.club_members DROP CONSTRAINT IF EXISTS club_members_status_check;

-- Sütun tiplerini güncelle
ALTER TABLE public.club_members 
ALTER COLUMN role TYPE public.club_role USING role::public.club_role,
ALTER COLUMN status TYPE public.membership_status USING status::public.membership_status;

-- ADIM 4: Clubs tablosunu güncelle
ALTER TABLE public.clubs DROP CONSTRAINT IF EXISTS clubs_status_check;
ALTER TABLE public.clubs 
ALTER COLUMN status TYPE public.club_status USING status::public.club_status;

-- ADIM 5: Index'ler ekle
CREATE INDEX IF NOT EXISTS idx_club_members_club_id ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user_id ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_members_status ON public.club_members(status);
CREATE INDEX IF NOT EXISTS idx_club_members_role ON public.club_members(role);
CREATE INDEX IF NOT EXISTS idx_profiles_full_name ON public.profiles(full_name);

-- ADIM 6: Unique constraint ekle
ALTER TABLE public.club_members 
ADD CONSTRAINT IF NOT EXISTS unique_club_user UNIQUE (club_id, user_id);

-- ADIM 7: Full_name senkronizasyon trigger'ı
CREATE OR REPLACE FUNCTION sync_full_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
    NEW.full_name := TRIM(CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, '')));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_full_name ON public.profiles;
CREATE TRIGGER trigger_sync_full_name
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_full_name();

-- ADIM 8: Mevcut verileri güncelle
UPDATE public.profiles 
SET full_name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, '')))
WHERE full_name IS NULL OR full_name = '';

-- ADIM 9: View oluştur (isteğe bağlı - performans için)
CREATE OR REPLACE VIEW public.club_members_with_names AS
SELECT 
  cm.id,
  cm.club_id,
  cm.user_id,
  cm.role,
  cm.status,
  cm.joined_at,
  p.full_name,
  p.first_name,
  p.last_name,
  p.email,
  p.display_name
FROM public.club_members cm
JOIN public.profiles p ON cm.user_id = p.id;

-- ADIM 10: RLS (Row Level Security) - İsteğe bağlı
-- ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;

-- ADIM 11: Test sorgusu - Çalıştırarak kontrol et
SELECT 
  cm.user_id,
  p.full_name,
  p.email,
  cm.role,
  cm.status
FROM public.club_members cm
JOIN public.profiles p ON cm.user_id = p.id
LIMIT 5;