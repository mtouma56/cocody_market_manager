-- Migration: Fix statut_paiement enum to include 'Partiel' value
-- Date: 2025-10-25 09:32:37

-- Add 'Partiel' to the statut_paiement enum
ALTER TYPE public.statut_paiement ADD VALUE 'Partiel';

-- Now insert the corrected mock data with proper enum values
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
-- Paiement en attente 1 (pour Aminata Traoré qui contient 'awa')
(
  gen_random_uuid(),
  '80f32170-b6b1-4812-a528-e65bec2e4ea7', -- Bail existant
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
-- Paiement en attente 2  
(
  gen_random_uuid(),
  '80f32170-b6b1-4812-a528-e65bec2e4ea7',
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
-- Paiement en attente 3
(
  gen_random_uuid(),
  'd3f26078-bbb0-4c7d-8bca-41390a757556', -- Autre bail existant
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
-- Paiement en retard 1
(
  gen_random_uuid(),
  '80f32170-b6b1-4812-a528-e65bec2e4ea7',
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
-- Paiement en retard 2
(
  gen_random_uuid(),
  'd3f26078-bbb0-4c7d-8bca-41390a757556',
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
-- Paiement partiel 1 - NOW USING CORRECT ENUM VALUE
(
  gen_random_uuid(),
  '80f32170-b6b1-4812-a528-e65bec2e4ea7',
  90000, -- Montant partiel
  '2024-11-15',
  '2024-11-01',
  'nov-2024',
  'Partiel'::public.statut_paiement, -- Now valid after adding to enum
  'Espèces'::public.mode_paiement,
  'Paiement partiel novembre',
  NOW(),
  NOW()
),
-- Paiement partiel 2
(
  gen_random_uuid(),
  'd3f26078-bbb0-4c7d-8bca-41390a757556',
  50000, -- Montant partiel
  '2024-11-20',
  '2024-11-01',
  'nov-2024',
  'Partiel'::public.statut_paiement, -- Now valid after adding to enum
  'Mobile Money'::public.mode_paiement,
  'Paiement partiel novembre',
  NOW(),
  NOW()
);