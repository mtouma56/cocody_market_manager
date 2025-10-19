-- Location: supabase/migrations/20251019142311_add_baux_deposit_fields.sql
-- Schema Analysis: Existing baux table with montant_loyer field
-- Integration Type: MODIFICATIVE - Adding deposit columns to existing baux table
-- Dependencies: public.baux (existing table)

-- Add deposit columns to existing baux table
ALTER TABLE public.baux
ADD COLUMN montant_caution NUMERIC,
ADD COLUMN montant_pas_de_porte NUMERIC;

-- Add comment for documentation
COMMENT ON COLUMN public.baux.montant_caution IS 'Montant de la caution en FCFA (optionnel)';
COMMENT ON COLUMN public.baux.montant_pas_de_porte IS 'Montant du pas de porte en FCFA (optionnel)';

-- Add indexes for the new columns to improve query performance
CREATE INDEX idx_baux_montant_caution ON public.baux(montant_caution) WHERE montant_caution IS NOT NULL;
CREATE INDEX idx_baux_montant_pas_de_porte ON public.baux(montant_pas_de_porte) WHERE montant_pas_de_porte IS NOT NULL;

-- Add check constraints to ensure positive amounts
ALTER TABLE public.baux
ADD CONSTRAINT chk_montant_caution_positive CHECK (montant_caution IS NULL OR montant_caution >= 0);

ALTER TABLE public.baux
ADD CONSTRAINT chk_montant_pas_de_porte_positive CHECK (montant_pas_de_porte IS NULL OR montant_pas_de_porte >= 0);

-- Add validation constraint to ensure at least one deposit type is specified or both are null
ALTER TABLE public.baux
ADD CONSTRAINT chk_deposit_logic CHECK (
    (montant_caution IS NOT NULL AND montant_pas_de_porte IS NULL) OR
    (montant_caution IS NULL AND montant_pas_de_porte IS NOT NULL) OR
    (montant_caution IS NULL AND montant_pas_de_porte IS NULL)
);