CREATE TABLE public.bill_payments (
  bill_id uuid NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  profile_id text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewing', 'paid')),
  slip_data text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (bill_id, profile_id)
);

ALTER TABLE public.bill_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY bill_payments_select_owner_or_self
ON public.bill_payments
FOR SELECT
TO authenticated
USING (
  profile_id = (SELECT auth.uid())::text
  OR private.owns_bill(bill_id)
);

REVOKE ALL ON TABLE public.bill_payments FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.bill_payments TO authenticated;

INSERT INTO public.bill_payments (bill_id, profile_id, status, slip_data)
SELECT
  b.id,
  member.profile_id,
  CASE
    WHEN lower(COALESCE(statuses.value, '')) IN ('paid', 'cleared', 'settled')
      THEN 'paid'
    WHEN lower(COALESCE(statuses.value, '')) IN ('reviewing', 'pending_verification')
      OR slips.value IS NOT NULL
      THEN 'reviewing'
    ELSE 'pending'
  END,
  slips.value
FROM public.bills AS b
CROSS JOIN LATERAL (
  SELECT key AS profile_id
  FROM jsonb_each(COALESCE(b.receipt_json::jsonb -> 'paid_statuses', '{}'::jsonb))
  UNION
  SELECT key AS profile_id
  FROM jsonb_each(COALESCE(b.receipt_json::jsonb -> 'payment_slips', '{}'::jsonb))
) AS member
LEFT JOIN LATERAL jsonb_each_text(
  COALESCE(b.receipt_json::jsonb -> 'paid_statuses', '{}'::jsonb)
) AS statuses ON statuses.key = member.profile_id
LEFT JOIN LATERAL jsonb_each_text(
  COALESCE(b.receipt_json::jsonb -> 'payment_slips', '{}'::jsonb)
) AS slips ON slips.key = member.profile_id
WHERE member.profile_id <> ''
ON CONFLICT (bill_id, profile_id) DO NOTHING;

UPDATE public.bill_participants AS participant
SET status = payment.status
FROM public.bill_payments AS payment
WHERE payment.bill_id = participant.bill_id
  AND payment.profile_id = participant.profile_id::text
  AND payment.status IN ('pending', 'paid');

UPDATE public.bills
SET receipt_json = receipt_json::jsonb - 'payment_slips' - 'paid_statuses'
WHERE receipt_json IS NOT NULL
  AND (
    receipt_json::jsonb ? 'payment_slips'
    OR receipt_json::jsonb ? 'paid_statuses'
  );

CREATE OR REPLACE FUNCTION private.refresh_bill_payment_status(p_bill_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  UPDATE public.bills AS b
  SET status = CASE
    WHEN (
      EXISTS (
        SELECT 1
        FROM public.bill_participants AS bp
        WHERE bp.bill_id = b.id
          AND bp.profile_id::text <> b.owner_id::text
      )
      OR EXISTS (
        SELECT 1
        FROM public.bill_payments AS payment
        WHERE payment.bill_id = b.id
          AND payment.profile_id <> b.owner_id::text
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.bill_participants AS bp
      WHERE bp.bill_id = b.id
        AND bp.profile_id::text <> b.owner_id::text
        AND NOT EXISTS (
          SELECT 1
          FROM public.bill_payments AS payment
          WHERE payment.bill_id = bp.bill_id
            AND payment.profile_id = bp.profile_id::text
        )
        AND lower(COALESCE(bp.status, 'pending')) NOT IN ('paid', 'cleared', 'settled')
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.bill_payments AS payment
      WHERE payment.bill_id = b.id
        AND payment.profile_id <> b.owner_id::text
        AND payment.status <> 'paid'
    )
    THEN 'completed'
    ELSE 'pending'
  END
  WHERE b.id = p_bill_id;
$$;

CREATE OR REPLACE FUNCTION public.submit_bill_payment(
  p_bill_id uuid,
  p_profile_id text,
  p_slip_data text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  caller_id uuid := auth.uid();
  affected_rows integer;
BEGIN
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_bill_id IS NULL OR p_profile_id IS NULL OR p_profile_id = ''
      OR p_slip_data IS NULL OR p_slip_data = '' THEN
    RAISE EXCEPTION 'Bill, participant, and payment slip are required';
  END IF;
  IF length(p_slip_data) > 10485760 THEN
    RAISE EXCEPTION 'Payment slip is too large';
  END IF;
  IF NOT private.can_access_bill(p_bill_id) THEN
    RAISE EXCEPTION 'You cannot access this bill';
  END IF;
  IF caller_id::text <> p_profile_id
      AND NOT private.owns_bill(p_bill_id) THEN
    RAISE EXCEPTION 'Only the participant or bill owner can submit this payment';
  END IF;

  INSERT INTO public.bill_payments (bill_id, profile_id, status, slip_data, updated_at)
  VALUES (p_bill_id, p_profile_id, 'reviewing', p_slip_data, now())
  ON CONFLICT (bill_id, profile_id) DO UPDATE
  SET status = 'reviewing',
      slip_data = EXCLUDED.slip_data,
      updated_at = now()
  WHERE private.owns_bill(p_bill_id)
     OR public.bill_payments.status <> 'paid';

  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  IF affected_rows = 0 THEN
    RAISE EXCEPTION 'This payment has already been confirmed';
  END IF;

  PERFORM private.refresh_bill_payment_status(p_bill_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_bill_payment_status(
  p_bill_id uuid,
  p_profile_id text,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT private.owns_bill(p_bill_id) THEN
    RAISE EXCEPTION 'Only the bill owner can change payment status';
  END IF;
  IF p_profile_id IS NULL OR p_profile_id = ''
      OR p_status IS NULL
      OR p_status NOT IN ('pending', 'paid') THEN
    RAISE EXCEPTION 'Invalid participant or payment status';
  END IF;

  INSERT INTO public.bill_payments (bill_id, profile_id, status, slip_data, updated_at)
  VALUES (p_bill_id, p_profile_id, p_status, NULL, now())
  ON CONFLICT (bill_id, profile_id) DO UPDATE
  SET status = EXCLUDED.status,
      slip_data = CASE
        WHEN EXCLUDED.status = 'pending' THEN NULL
        ELSE public.bill_payments.slip_data
      END,
      updated_at = now();

  UPDATE public.bill_participants
  SET status = p_status
  WHERE bill_id = p_bill_id
    AND profile_id::text = p_profile_id;

  PERFORM private.refresh_bill_payment_status(p_bill_id);
END;
$$;

REVOKE ALL ON FUNCTION private.refresh_bill_payment_status(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.submit_bill_payment(uuid, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.set_bill_payment_status(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.submit_bill_payment(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_bill_payment_status(uuid, text, text) TO authenticated;
