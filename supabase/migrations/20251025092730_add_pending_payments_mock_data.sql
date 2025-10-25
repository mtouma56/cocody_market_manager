-- Migration: Ajouter des paiements en attente et en retard pour les tests
-- Date: 2025-10-25 09:27:30

-- Insérer des paiements en attente avec des noms contenant 'awa' pour les tests
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
  'En attente',
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
  'En attente',
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
  'En attente',
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
  'En retard',
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
  'En retard',
  NULL,
  'Paiement août en retard',
  NOW(),
  NOW()
),
-- Paiement partiel 1
(
  gen_random_uuid(),
  '80f32170-b6b1-4812-a528-e65bec2e4ea7',
  90000, -- Montant partiel
  '2024-11-15',
  '2024-11-01',
  'nov-2024',
  'Partiel',
  'Espèces',
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
  'Partiel',
  'Mobile Money',
  'Paiement partiel novembre',
  NOW(),
  NOW()
);