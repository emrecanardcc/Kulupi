-- GÜVENLİ MİGRASYON SCRIPT'İ
-- Mevcut verileri koruyarak enum dönüşümü

-- ADIM 0: Mevcut verileri kontrol et
SELECT 
  'club_members' as table_name,
  role,
  status,
  COUNT(*) as count
FROM public.club_members 
GROUP BY role, status;

-- ADIM 1: Enum tiplerini oluştur
CREATE TYPE public.club_role AS ENUM ('baskan', 'baskan_yardimcisi', 'koordinator', 'uye');
CREATE TYPE public.membership_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.club_status AS ENUM ('active', 'inactive', 'pending');

-- ADIM 2: Yeni sütunlar ekle (eski sütunları koru)
ALTER TABLE public.club_members 
ADD COLUMN IF NOT EXISTS role_new public.club_role,
ADD COLUMN IF NOT EXISTS status_new public.membership_status;

-- ADIM 3: Mevcut verileri yeni sütunlara kopyala ve dönüştür
UPDATE public.club_members 
SET role_new = CASE 
  WHEN role = 'baskan' THEN 'baskan'::public.club_role
  WHEN role = 'baskan_yardimcisi' THEN 'baskan_yardimcisi'::public.club_role
  WHEN role = 'koordinator' THEN 'koordinator'::public.club_role
  WHEN role = 'uye' THEN 'uye'::public.club_role
  WHEN role = 'president' THEN 'baskan'::public.club_role
  WHEN role = 'admin' THEN 'baskan_yardimcisi'::public.club_role
  WHEN role = 'member' THEN 'uye'::public.club_role
  ELSE 'uye'::public.club_role
END,
status_new = CASE 
  WHEN status = 'pending' THEN 'pending'::public.membership_status
  WHEN status = 'approved' THEN 'approved'::public.membership_status
  WHEN status = 'rejected' THEN 'rejected'::public.membership_status
  ELSE 'pending'::public.membership_status
END;

-- ADIM 4: Eski sütunları kaldır
ALTER TABLE public.club_members 
DROP COLUMN IF EXISTS role,
DROP COLUMN IF EXISTS status;

-- ADIM 5: Yeni sütunları rename et
ALTER TABLE public.club_members 
RENAME COLUMN role_new TO role,
RENAME COLUMN status_new TO status;

-- ADIM 6: Default değerleri ayarla
ALTER TABLE public.club_members 
ALTER COLUMN role SET DEFAULT 'uye'::public.club_role,
ALTER COLUMN role SET NOT NULL,
ALTER COLUMN status SET DEFAULT 'pending'::public.membership_status,
ALTER COLUMN status SET NOT NULL;

-- ADIM 7: Clubs tablosu için aynı işlem
-- Önce mevcut durumu kontrol et
SELECT status, COUNT(*) FROM public.clubs GROUP BY status;

-- Yeni sütun ekle
ALTER TABLE public.clubs 
ADD COLUMN IF NOT EXISTS status_new public.club_status;

-- Verileri dönüştür
UPDATE public.clubs 
SET status_new = CASE 
  WHEN status = 'active' THEN 'active'::public.club_status
  WHEN status = 'inactive' THEN 'inactive'::public.club_status
  WHEN status = 'pending' THEN 'pending'::public.club_status
  ELSE 'active'::public.club_status
END;

-- Eski sütunu kaldır ve yeniyi rename et
ALTER TABLE public.clubs 
DROP COLUMN IF EXISTS status;

ALTER TABLE public.clubs 
RENAME COLUMN status_new TO status;

ALTER TABLE public.clubs 
ALTER COLUMN status SET DEFAULT 'active'::public.club_status,
ALTER COLUMN status SET NOT NULL;

-- ADIM 8: Index'ler ekle
CREATE INDEX IF NOT EXISTS idx_club_members_club_id ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user_id ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_members_status ON public.club_members(status);
CREATE INDEX IF NOT EXISTS idx_club_members_role ON public.club_members(role);
CREATE INDEX IF NOT EXISTS idx_profiles_full_name ON public.profiles(full_name);

-- ADIM 9: Unique constraint ekle
ALTER TABLE public.club_members 
ADD CONSTRAINT IF NOT EXISTS unique_club_user UNIQUE (club_id, user_id);

-- ADIM 10: Full_name senkronizasyon trigger'ı
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

-- ADIM 11: Mevcut verileri güncelle
UPDATE public.profiles 
SET full_name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, '')))
WHERE full_name IS NULL OR full_name = '';

-- ADIM 12: Sonuçları kontrol et
SELECT 
  'club_members' as table_name,
  role,
  status,
  COUNT(*) as count
FROM public.club_members 
GROUP BY role, status
ORDER BY role, status;

SELECT 
  'clubs' as table_name,
  status,
  COUNT(*) as count
FROM public.clubs 
GROUP BY status
ORDER BY status;