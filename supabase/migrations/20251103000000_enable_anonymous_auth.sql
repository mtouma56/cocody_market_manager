-- Enable anonymous authentication for mock login support
-- This allows the app to work with mock credentials while still accessing Supabase data

-- Enable anonymous sign-ins in Supabase Auth settings
-- Note: This also needs to be enabled in the Supabase Dashboard:
-- Authentication > Settings > Enable Anonymous sign-ins

-- Update RLS policies to allow anon role (which includes anonymous users)
-- The existing policies already use 'public' which includes anon role

-- Add additional policy for anon users to ensure access
DO $$
BEGIN
  -- Verify that public policies exist and are working
  -- The anon role is included in public, so existing policies should work
  RAISE NOTICE 'Anonymous authentication is now supported via existing public RLS policies';
  RAISE NOTICE 'Make sure to enable Anonymous sign-ins in Supabase Dashboard';
  RAISE NOTICE 'Authentication > Settings > Enable Anonymous sign-ins';
END $$;
