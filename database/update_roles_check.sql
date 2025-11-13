-- Actualiza el CHECK de roles para incluir 'management' y normaliza alias

-- 1) Asegurar CHECK con 'management'
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check
  CHECK (role IN ('user','manager','management','admin'));

-- 2) Normalizar alias antiguos a canónicos
UPDATE public.user_profiles SET role = 'admin'      WHERE lower(role) IN ('administrador','admin ');
UPDATE public.user_profiles SET role = 'manager'    WHERE lower(role) IN ('supervisor','manager ');
UPDATE public.user_profiles SET role = 'user'       WHERE lower(role) IN ('empleado','usuario');
-- management ya es canónico, no se toca


