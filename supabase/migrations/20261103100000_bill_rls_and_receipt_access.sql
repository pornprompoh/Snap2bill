CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE OR REPLACE FUNCTION private.can_access_bill(p_bill_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.bills AS b
    WHERE b.id = p_bill_id
      AND (
        b.owner_id = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM public.bill_participants AS bp
          WHERE bp.bill_id = b.id
            AND bp.profile_id = (SELECT auth.uid())
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION private.owns_bill(p_bill_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.bills AS b
    WHERE b.id = p_bill_id
      AND b.owner_id = (SELECT auth.uid())
  );
$$;

CREATE OR REPLACE FUNCTION private.can_view_bill_profile(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p_profile_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.bills AS b
      WHERE (
        b.owner_id = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM public.bill_participants AS viewer
          WHERE viewer.bill_id = b.id
            AND viewer.profile_id = (SELECT auth.uid())
        )
      )
        AND (
          b.owner_id = p_profile_id
          OR EXISTS (
            SELECT 1
            FROM public.bill_participants AS target
            WHERE target.bill_id = b.id
              AND target.profile_id = p_profile_id
          )
        )
    );
$$;

CREATE OR REPLACE FUNCTION private.can_read_receipt_object(p_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT split_part(p_name, '/', 1) = (SELECT auth.uid())::text
    OR EXISTS (
      SELECT 1
      FROM public.bills AS b
      WHERE b.image_url IS NOT NULL
        AND right(
          b.image_url,
          length('/storage/v1/object/public/receipts/' || p_name)
        ) = '/storage/v1/object/public/receipts/' || p_name
        AND private.can_access_bill(b.id)
    );
$$;

REVOKE ALL ON FUNCTION private.can_access_bill(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.owns_bill(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_view_bill_profile(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.can_read_receipt_object(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.can_access_bill(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.owns_bill(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_view_bill_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.can_read_receipt_object(text) TO authenticated;

DO $$
DECLARE
  existing_policy record;
BEGIN
  FOR existing_policy IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('bills', 'bill_participants', 'profiles')
  LOOP
    EXECUTE format(
      'DROP POLICY %I ON %I.%I',
      existing_policy.policyname,
      existing_policy.schemaname,
      existing_policy.tablename
    );
  END LOOP;
END;
$$;

ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY bills_select_accessible
ON public.bills
FOR SELECT
TO authenticated
USING (private.can_access_bill(id));

CREATE POLICY bills_insert_owner
ON public.bills
FOR INSERT
TO authenticated
WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY bills_update_owner
ON public.bills
FOR UPDATE
TO authenticated
USING (owner_id = (SELECT auth.uid()))
WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY bills_delete_owner
ON public.bills
FOR DELETE
TO authenticated
USING (owner_id = (SELECT auth.uid()));

CREATE POLICY bill_participants_select_accessible
ON public.bill_participants
FOR SELECT
TO authenticated
USING (private.can_access_bill(bill_id));

CREATE POLICY bill_participants_insert_owner
ON public.bill_participants
FOR INSERT
TO authenticated
WITH CHECK (private.owns_bill(bill_id));

CREATE POLICY bill_participants_update_owner
ON public.bill_participants
FOR UPDATE
TO authenticated
USING (private.owns_bill(bill_id))
WITH CHECK (private.owns_bill(bill_id));

CREATE POLICY bill_participants_delete_owner
ON public.bill_participants
FOR DELETE
TO authenticated
USING (private.owns_bill(bill_id));

CREATE POLICY profiles_select_self_or_bill_member
ON public.profiles
FOR SELECT
TO authenticated
USING (private.can_view_bill_profile(id));

CREATE POLICY profiles_insert_self
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (id = (SELECT auth.uid()));

CREATE POLICY profiles_update_self
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = (SELECT auth.uid()))
WITH CHECK (id = (SELECT auth.uid()));
