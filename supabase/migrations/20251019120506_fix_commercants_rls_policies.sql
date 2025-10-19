-- Location: supabase/migrations/20251019120506_fix_commercants_rls_policies.sql
-- Schema Analysis: Existing commercants table without user_id relationship
-- Integration Type: RLS policy modification to fix merchant creation
-- Dependencies: public.commercants table (existing)

-- Fix RLS policies for commercants table to allow proper access
-- The commercants table doesn't have user_id, so it should be managed differently

-- Drop existing problematic policies
DROP POLICY IF EXISTS "authenticated_can_manage_commercants" ON public.commercants;
DROP POLICY IF EXISTS "public_can_read_commercants" ON public.commercants;

-- Create new policies using Pattern 4: Public Read, Open Write for authenticated users
-- Since commercants are shared resources in a market management system

-- Allow public read access to commercants (merchants can be viewed by anyone)
CREATE POLICY "public_can_read_commercants"
ON public.commercants
FOR SELECT
TO public
USING (true);

-- Allow authenticated users to create new merchants
CREATE POLICY "authenticated_can_create_commercants"
ON public.commercants
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update merchants
CREATE POLICY "authenticated_can_update_commercants"
ON public.commercants
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to delete merchants (if needed)
CREATE POLICY "authenticated_can_delete_commercants"
ON public.commercants
FOR DELETE
TO authenticated
USING (true);