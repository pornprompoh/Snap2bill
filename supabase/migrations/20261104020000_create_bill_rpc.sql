CREATE OR REPLACE FUNCTION public.create_bill_with_participants(
  p_bill jsonb,
  p_participants jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  caller_id uuid := auth.uid();
  created_bill_id uuid;
  participant jsonb;
BEGIN
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF p_bill IS NULL OR jsonb_typeof(p_bill) <> 'object' THEN
    RAISE EXCEPTION 'Bill data must be a JSON object';
  END IF;
  IF p_participants IS NULL OR jsonb_typeof(p_participants) <> 'array' THEN
    RAISE EXCEPTION 'Participants must be a JSON array';
  END IF;

  INSERT INTO public.bills (
    owner_id,
    shop_name,
    sub_total,
    total_amount,
    status,
    receipt_json,
    sharers_json,
    image_url
  )
  VALUES (
    caller_id,
    COALESCE(NULLIF(p_bill ->> 'shop_name', ''), 'ไม่ระบุชื่อร้าน'),
    NULLIF(p_bill ->> 'sub_total', '')::numeric,
    NULLIF(p_bill ->> 'total_amount', '')::numeric,
    'pending',
    COALESCE(p_bill -> 'receipt_json', '{}'::jsonb),
    COALESCE(p_bill -> 'sharers_json', '{}'::jsonb),
    NULLIF(p_bill ->> 'image_url', '')
  )
  RETURNING id INTO created_bill_id;

  FOR participant IN SELECT value FROM jsonb_array_elements(p_participants)
  LOOP
    IF jsonb_typeof(participant) <> 'object'
        OR COALESCE(participant ->> 'profile_id', '') !~
          '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN
      RAISE EXCEPTION 'Invalid participant profile id';
    END IF;

    INSERT INTO public.bill_participants (
      bill_id,
      profile_id,
      amount_owed,
      status
    )
    VALUES (
      created_bill_id,
      (participant ->> 'profile_id')::uuid,
      COALESCE(NULLIF(participant ->> 'amount_owed', '')::numeric, 0),
      'pending'
    );
  END LOOP;

  RETURN created_bill_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_bill_with_participants(jsonb, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_bill_with_participants(jsonb, jsonb) TO authenticated;
