-- Location: supabase/migrations/20251025084347_add_quittances_historique.sql
-- Schema Analysis: Existing schema with paiements, baux, commercants, locaux tables
-- Integration Type: Addition - New receipt history tracking table
-- Dependencies: References existing paiements table

-- Create receipt history table for complete traceability
CREATE TABLE public.quittances_historique (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    paiement_id UUID REFERENCES public.paiements(id) ON DELETE CASCADE,
    numero_quittance TEXT NOT NULL,
    type_document TEXT NOT NULL CHECK (type_document IN ('Quittance', 'Reçu partiel')),
    montant_documente DECIMAL NOT NULL,
    reste_du DECIMAL,
    statut_paiement TEXT NOT NULL,
    date_generation TIMESTAMPTZ DEFAULT NOW(),
    genere_par TEXT DEFAULT 'MICHAEL TOUMA',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for efficient queries by payment
CREATE INDEX idx_quittances_historique_paiement ON public.quittances_historique(paiement_id);

-- Create additional indexes for common queries
CREATE INDEX idx_quittances_historique_date_generation ON public.quittances_historique(date_generation);
CREATE INDEX idx_quittances_historique_type_document ON public.quittances_historique(type_document);

-- Enable RLS
ALTER TABLE public.quittances_historique ENABLE ROW LEVEL SECURITY;

-- Pattern 4: Public Read, Private Write - Following existing schema patterns
CREATE POLICY "public_can_read_quittances_historique"
ON public.quittances_historique
FOR SELECT
TO public
USING (true);

CREATE POLICY "authenticated_can_manage_quittances_historique"
ON public.quittances_historique
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Add sample data for testing
DO $$
DECLARE
    existing_paiement_id UUID;
BEGIN
    -- Get an existing payment ID for sample data
    SELECT id INTO existing_paiement_id FROM public.paiements WHERE statut = 'Payé' LIMIT 1;
    
    -- Only insert sample data if we have an existing payment
    IF existing_paiement_id IS NOT NULL THEN
        INSERT INTO public.quittances_historique (
            paiement_id, 
            numero_quittance, 
            type_document, 
            montant_documente, 
            reste_du, 
            statut_paiement
        ) VALUES (
            existing_paiement_id,
            'QUIT-' || substring(existing_paiement_id::text from 1 for 8),
            'Quittance',
            (SELECT montant FROM public.paiements WHERE id = existing_paiement_id),
            null,
            'Payé'
        );
        
        RAISE NOTICE 'Sample receipt history record created for paiement %', existing_paiement_id;
    ELSE
        RAISE NOTICE 'No paid payments found - skipping sample data creation';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating sample data: %', SQLERRM;
END $$;