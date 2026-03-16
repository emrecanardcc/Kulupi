-- VERİTABANI KONTROL TESTLERİ
-- Bu sorguları Supabase Dashboard > SQL Editor'de çalıştır

-- 1. Enum tiplerini kontrol et
SELECT typname, enumlabel 
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname IN ('club_role', 'membership_status', 'club_status')
ORDER BY t.typname, e.enumsortorder;

-- 2. Tablo yapılarını kontrol et
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name IN ('club_members', 'clubs', 'profiles')
AND table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- 3. Index'leri kontrol et
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename IN ('club_members', 'clubs', 'profiles')
AND schemaname = 'public'
ORDER BY tablename, indexname;

-- 4. Constraint'leri kontrol et
SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name IN ('club_members', 'clubs', 'profiles')
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;

-- 5. Full_name trigger'ını kontrol et
SELECT 
  trigger_name,
  event_object_table,
  action_statement,
  action_timing,
  event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'profiles'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 6. Mevcut verileri kontrol et - club_members
SELECT 
  role,
  status,
  COUNT(*) as count,
  STRING_AGG(DISTINCT role::text, ', ') as roles,
  STRING_AGG(DISTINCT status::text, ', ') as statuses
FROM public.club_members 
GROUP BY role, status
ORDER BY role, status;

-- 7. Mevcut verileri kontrol et - clubs
SELECT 
  status,
  COUNT(*) as count
FROM public.clubs 
GROUP BY status
ORDER BY status;

-- 8. Full_name senkronizasyonunu test et
SELECT 
  id,
  first_name,
  last_name,
  full_name,
  CASE 
    WHEN full_name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))) THEN 'SENKRON'
    ELSE 'FARKLI'
  END as sync_status
FROM public.profiles 
WHERE first_name IS NOT NULL OR last_name IS NOT NULL
LIMIT 10;

-- 9. Admin panel testi - Üye isimleri için
SELECT 
  cm.club_id,
  cm.user_id,
  p.full_name,
  p.first_name,
  p.last_name,
  p.email,
  cm.role,
  cm.status,
  cm.joined_at
FROM public.club_members cm
JOIN public.profiles p ON cm.user_id = p.id
WHERE cm.status = 'approved'
ORDER BY cm.club_id, cm.role, p.full_name
LIMIT 10;

-- 10. View'ü kontrol et (eğer oluşturduysan)
SELECT table_name, view_definition 
FROM information_schema.views 
WHERE table_name = 'club_members_with_names'
AND table_schema = 'public';