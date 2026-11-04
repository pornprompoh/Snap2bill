CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id uuid NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_name text NOT NULL,
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name text NOT NULL,
  shop_name text NOT NULL,
  amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
  title text NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS notifications_recipient_created_at_idx
  ON public.notifications (recipient_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_select_recipient
  ON public.notifications;
CREATE POLICY notifications_select_recipient
ON public.notifications
FOR SELECT
TO authenticated
USING (recipient_id::text = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS notifications_insert_bill_owner
  ON public.notifications;
CREATE POLICY notifications_insert_bill_owner
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
  sender_id::text = (SELECT auth.uid())::text
  AND private.owns_bill(bill_id)
  AND recipient_id::text <> (SELECT auth.uid())::text
  AND EXISTS (
    SELECT 1
    FROM public.bill_participants AS participant
    WHERE participant.bill_id = notifications.bill_id
      AND participant.profile_id::text = notifications.recipient_id::text
  )
);

DROP POLICY IF EXISTS notifications_update_recipient_read
  ON public.notifications;
CREATE POLICY notifications_update_recipient_read
ON public.notifications
FOR UPDATE
TO authenticated
USING (recipient_id::text = (SELECT auth.uid())::text)
WITH CHECK (recipient_id::text = (SELECT auth.uid())::text);

REVOKE ALL ON TABLE public.notifications FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.notifications TO authenticated;
GRANT UPDATE (is_read) ON TABLE public.notifications TO authenticated;

ALTER TABLE public.bills REPLICA IDENTITY FULL;
ALTER TABLE public.bill_participants REPLICA IDENTITY FULL;
ALTER TABLE public.bill_payments REPLICA IDENTITY FULL;
ALTER TABLE public.notifications REPLICA IDENTITY FULL;

DO $$
DECLARE
  table_name text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_publication
    WHERE pubname = 'supabase_realtime'
  ) THEN
    RAISE EXCEPTION 'Supabase Realtime publication supabase_realtime does not exist';
  END IF;

  FOREACH table_name IN ARRAY ARRAY[
    'bills',
    'bill_participants',
    'bill_payments',
    'notifications'
  ]
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = table_name
    ) THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        table_name
      );
    END IF;
  END LOOP;
END;
$$;
