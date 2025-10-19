-- Location: supabase/migrations/20251019115621_fix_merchant_optional_fields.sql
-- Schema Analysis: Commercants table exists with nullable email field but UNIQUE constraint may cause issues
-- Integration Type: Modificative - Fix constraint handling for optional fields
-- Dependencies: Existing commercants table

-- Fix email constraint to allow multiple NULL values but prevent duplicate non-null emails
-- Drop the UNIQUE constraint first (which will automatically drop the associated index)
ALTER TABLE public.commercants 
DROP CONSTRAINT IF EXISTS commercants_email_key;

-- Create partial unique index that only applies to non-null, non-empty emails
CREATE UNIQUE INDEX commercants_email_unique_when_present 
ON public.commercants (email) 
WHERE email IS NOT NULL AND email != '';

-- Add address column if it doesn't exist (making it optional)
ALTER TABLE public.commercants 
ADD COLUMN IF NOT EXISTS adresse TEXT;

-- Update existing RLS policies to handle new optional fields properly
-- (No changes needed as existing policies are already correct)

-- Add comment to clarify optional fields
COMMENT ON COLUMN public.commercants.email IS 'Email optionnel du commerçant - peut être null ou vide';
COMMENT ON COLUMN public.commercants.adresse IS 'Adresse optionnelle du commerçant - peut être null ou vide';