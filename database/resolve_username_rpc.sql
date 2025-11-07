-- RPC para resolver email a partir de un nombre de usuario (case-insensitive)
-- Busca en public.user_profiles por name o email

CREATE OR REPLACE FUNCTION public.resolve_email_for_username(p_username text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
BEGIN
  SELECT up.email
    INTO v_email
  FROM public.user_profiles up
  WHERE lower(coalesce(up.name, '')) = lower(p_username)
     OR lower(coalesce(up.email, '')) = lower(p_username)
  LIMIT 1;

  RETURN v_email;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_email_for_username(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_email_for_username(text) TO anon;
GRANT EXECUTE ON FUNCTION public.resolve_email_for_username(text) TO authenticated;


