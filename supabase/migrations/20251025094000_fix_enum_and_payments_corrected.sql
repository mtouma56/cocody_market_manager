-- Migration: Fix statut_paiement enum and add pending payments - CORRECTED
-- Date: 2025-10-25 09:40:00
-- Issue: PostgreSQL requires enum values to be committed before use in same transaction

-- Step 1: Add 'Partiel' to the statut_paiement enum (this must be done first)
ALTER TYPE public.statut_paiement ADD VALUE IF NOT EXISTS 'Partiel';

-- Step 2: Commit the enum change (implicit at end of statement)

-- Step 3: Now we can safely insert data using the new enum value
-- Use DO block to handle the insertion in a separate execution context
DO $$
DECLARE
    existing_bail_1 UUID := '80f32170-b6b1-4812-a528-e65bec2e4ea7';
    existing_bail_2 UUID := 'd3f26078-bbb0-4c7d-8bca-41390a757556';
    temp_id UUID;
BEGIN
    -- Verify the baux exist before inserting
    IF EXISTS (SELECT 1 FROM public.baux WHERE id = existing_bail_1) 
    AND EXISTS (SELECT 1 FROM public.baux WHERE id = existing_bail_2) THEN
    
        -- Insert paiements with corrected enum values
        INSERT INTO public.paiements (
            id,
            bail_id,
            montant,
            date_paiement,
            date_echeance,
            mois_concerne,
            statut,
            mode_paiement,
            notes,
            created_at,
            updated_at
        ) VALUES
        -- Paiements en attente
        (
            gen_random_uuid(),
            existing_bail_1,
            180568,
            NULL,
            '2024-12-01',
            'dec-2024',
            'En attente'::public.statut_paiement,
            NULL,
            'Paiement décembre en attente',
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            existing_bail_1,
            180568,
            NULL,
            '2025-01-01',
            'jan-2025',
            'En attente'::public.statut_paiement,
            NULL,
            'Paiement janvier en attente',
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            existing_bail_2,
            86606,
            NULL,
            '2024-12-01',
            'dec-2024',
            'En attente'::public.statut_paiement,
            NULL,
            'Paiement décembre en attente',
            NOW(),
            NOW()
        ),
        -- Paiements en retard
        (
            gen_random_uuid(),
            existing_bail_1,
            180568,
            NULL,
            '2024-09-01',
            'sep-2024',
            'En retard'::public.statut_paiement,
            NULL,
            'Paiement septembre en retard',
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            existing_bail_2,
            86606,
            NULL,
            '2024-08-01',
            'aug-2024',
            'En retard'::public.statut_paiement,
            NULL,
            'Paiement août en retard',
            NOW(),
            NOW()
        ),
        -- Paiements partiels - Now using the committed enum value
        (
            gen_random_uuid(),
            existing_bail_1,
            90000, -- Montant partiel
            '2024-11-15',
            '2024-11-01',
            'nov-2024',
            'Partiel'::public.statut_paiement, -- Now safe to use
            'Espèces'::public.mode_paiement,
            'Paiement partiel novembre',
            NOW(),
            NOW()
        ),
        (
            gen_random_uuid(),
            existing_bail_2,
            50000, -- Montant partiel
            '2024-11-20',
            '2024-11-01',
            'nov-2024',
            'Partiel'::public.statut_paiement, -- Now safe to use
            'Mobile Money'::public.mode_paiement,
            'Paiement partiel novembre',
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Successfully inserted % pending/overdue payments', 7;
    ELSE
        RAISE NOTICE 'Required baux not found. Skipping payment insertion.';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting payments: %', SQLERRM;
END $$;