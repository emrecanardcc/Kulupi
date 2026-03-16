-- Kulüp Veritabanı İyileştirmeleri
-- Bu script mevcut veritabanınızı optimize eder ve eksik constraint'leri tamamlar

-- 1. Rol ve Status için Enum Tipleri Oluştur
CREATE TYPE public.club_role AS ENUM ('baskan', 'baskan_yardimcisi', 'koordinator', 'uye');
CREATE TYPE public.membership_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.club_status AS ENUM ('active', 'inactive', 'pending');

-- 2. Club_members tablosunu güncelle - constraint'ler ve index'ler
ALTER TABLE public.club_members 
DROP COLUMN IF EXISTS role,
DROP COLUMN IF EXISTS status;

ALTER TABLE public.club_members 
ADD COLUMN role public.club_role NOT NULL DEFAULT 'uye',
ADD COLUMN status public.membership_status NOT NULL DEFAULT 'pending';

-- 3. Clubs tablosunu güncelle
ALTER TABLE public.clubs 
DROP COLUMN IF EXISTS status;

ALTER TABLE public.clubs 
ADD COLUMN status public.club_status NOT NULL DEFAULT 'active';

-- 4. Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_club_members_club_id ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user_id ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_members_status ON public.club_members(status);
CREATE INDEX IF NOT EXISTS idx_club_members_role ON public.club_members(role);
CREATE INDEX IF NOT EXISTS idx_profiles_full_name ON public.profiles(full_name);
CREATE INDEX IF NOT EXISTS idx_clubs_university_id ON public.clubs(university_id);
CREATE INDEX IF NOT EXISTS idx_clubs_status ON public.clubs(status);

-- 5. Unique constraint'ler ekle
ALTER TABLE public.club_members 
ADD CONSTRAINT unique_club_user UNIQUE (club_id, user_id);

-- 6. Full_name senkronizasyon trigger'ı
CREATE OR REPLACE FUNCTION sync_full_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
    NEW.full_name := CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, ''));
    NEW.full_name := TRIM(NEW.full_name);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_full_name
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_full_name();

-- 7. Mevcut verileri güncelle (full_name boş olanlar)
UPDATE public.profiles 
SET full_name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, '')))
WHERE full_name IS NULL OR full_name = '';

-- 8. Club_members view oluştur (join ile isimleri göstermek için)
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
  p.display_name,
  p.university_id,
  p.faculty_id,
  p.department_id
FROM public.club_members cm
JOIN public.profiles p ON cm.user_id = p.id;

-- 9. RLS (Row Level Security) politikaları - Temel güvenlik
ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Club members için RLS policy
CREATE POLICY "Users can view club members" ON public.club_members
  FOR SELECT USING (status = 'approved');

CREATE POLICY "Club presidents can manage members" ON public.club_members
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.club_members cm2 
      WHERE cm2.club_id = club_members.club_id 
      AND cm2.user_id = auth.uid() 
      AND cm2.role = 'baskan'
    )
  );

-- 10. Foreign key constraint'leri güncelle (cascade delete)
ALTER TABLE public.club_members
DROP CONSTRAINT IF EXISTS club_members_club_id_fkey,
DROP CONSTRAINT IF EXISTS club_members_user_id_fkey;

ALTER TABLE public.club_members
ADD CONSTRAINT club_members_club_id_fkey 
  FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE,
ADD CONSTRAINT club_members_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 11. Trigger: Sadece bir başkan olabilir
CREATE OR REPLACE FUNCTION ensure_single_president()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'baskan' THEN
    -- Mevcut başkan var mı kontrol et
    IF EXISTS (
      SELECT 1 FROM public.club_members 
      WHERE club_id = NEW.club_id 
      AND role = 'baskan' 
      AND user_id != NEW.user_id
      AND status = 'approved'
    ) THEN
      RAISE EXCEPTION 'Bu kulüpte zaten bir başkan var. Yeni başkan atamadan önce mevcut başkanın rolünü değiştirmelisiniz.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_single_president
  BEFORE INSERT OR UPDATE OF role ON public.club_members
  FOR EACH ROW
  EXECUTE FUNCTION ensure_single_president();