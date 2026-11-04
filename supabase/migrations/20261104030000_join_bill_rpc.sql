CREATE OR REPLACE FUNCTION public.join_bill(p_bill_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  caller_id uuid := auth.uid();
BEGIN
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_bill_id IS NULL THEN
    RAISE EXCEPTION 'Bill id is required';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM public.bills AS bill
    WHERE bill.id = p_bill_id
  ) THEN
    RAISE EXCEPTION 'Bill not found';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(p_bill_id::text),
    pg_catalog.hashtext(caller_id::text)
  );

  IF NOT EXISTS (
    SELECT 1
    FROM public.bill_participants AS participant
    WHERE participant.bill_id = p_bill_id
      AND participant.profile_id = caller_id
  ) THEN
    INSERT INTO public.bill_participants (
      bill_id,
      profile_id,
      amount_owed,
      status
    )
    VALUES (p_bill_id, caller_id, 0, 'pending');
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.join_bill(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.join_bill(uuid) TO authenticated;
