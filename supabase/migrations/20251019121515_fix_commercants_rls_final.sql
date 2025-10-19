-- Fix RLS policies for commercants table to allow authenticated users to create merchants
-- This addresses the PostgreSQL RLS violation error (code: 42501)

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "authenticated_can_create_commercants" ON public.commercants;
DROP POLICY IF EXISTS "authenticated_can_update_commercants" ON public.commercants;
DROP POLICY IF EXISTS "authenticated_can_delete_commercants" ON public.commercants;
DROP POLICY IF EXISTS "public_can_read_commercants" ON public.commercants;

-- Create permissive policies for merchant management
-- Since this is a market management system, authenticated users should be able to manage merchants

-- Allow public to read merchants (for display purposes)
CREATE POLICY "allow_public_read_commercants"
ON public.commercants
FOR SELECT
TO public
USING (true);

-- Allow authenticated users to create merchants without restrictions
CREATE POLICY "allow_authenticated_create_commercants"
ON public.commercants
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update merchants
CREATE POLICY "allow_authenticated_update_commercants"
ON public.commercants
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to delete merchants
CREATE POLICY "allow_authenticated_delete_commercants"
ON public.commercants
FOR DELETE
TO authenticated
USING (true);

-- Ensure RLS is enabled
ALTER TABLE public.commercants ENABLE ROW LEVEL SECURITY;