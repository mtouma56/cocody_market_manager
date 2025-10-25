-- Location: supabase/migrations/20251020180806_fix_deposit_constraint.sql
-- Schema Analysis: Existing cocody market rental management schema with baux table constraint issue
-- Integration Type: MODIFICATIVE - Fix existing constraint that prevents 0 values for caution
-- Dependencies: public.baux table

-- The constraint 'chk_deposit_logic' is preventing updates with 0 caution values
-- Based on business logic, caution can be 0 (no deposit required)

-- Step 1: Drop the existing problematic constraint
ALTER TABLE public.baux DROP CONSTRAINT IF EXISTS chk_deposit_logic;
ALTER TABLE public.baux DROP CONSTRAINT IF EXISTS baux_bail_caution_check;

-- Step 2: Create a more flexible constraint that allows 0 or positive values
-- This allows caution to be 0 (no deposit) or any positive amount
ALTER TABLE public.baux 
ADD CONSTRAINT chk_baux_amounts_positive 
CHECK (
    montant_loyer > 0 AND
    (montant_caution IS NULL OR montant_caution >= 0) AND
    (montant_pas_de_porte IS NULL OR montant_pas_de_porte >= 0)
);

-- Add a comment explaining the business logic
COMMENT ON CONSTRAINT chk_baux_amounts_positive ON public.baux IS 
'Ensures monthly rent is positive, while caution and pas de porte can be 0 or positive (0 means no deposit required)';