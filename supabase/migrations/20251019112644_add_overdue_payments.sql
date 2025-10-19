-- Location: supabase/migrations/20251019112644_add_overdue_payments.sql
-- Schema Analysis: Existing rental management schema with paiements, baux, commercants, locaux, etages, types_locaux tables
-- Integration Type: modificative - updating existing payment data to include overdue payments
-- Dependencies: paiements, baux tables

-- Update 15 existing "Payé" payments to "En retard" status to show overdue amounts in dashboard
UPDATE paiements
SET 
  statut = 'En retard',
  date_paiement = NULL
WHERE id IN (
  SELECT id 
  FROM paiements 
  WHERE statut = 'Payé' 
  ORDER BY RANDOM() 
  LIMIT 15
);

-- Add 5 new overdue payments using existing active leases
INSERT INTO paiements (bail_id, montant, date_echeance, mois_concerne, statut)
SELECT 
  id as bail_id,
  montant_loyer as montant,
  '2024-11-10' as date_echeance,
  '2024-11' as mois_concerne,
  'En retard' as statut
FROM baux
WHERE statut = 'Actif'
ORDER BY RANDOM()
LIMIT 5;

-- Add 10 payments with "En attente" status for realistic variety
UPDATE paiements
SET 
  statut = 'En attente',
  date_paiement = NULL,
  date_echeance = CURRENT_DATE + INTERVAL '5 days'
WHERE id IN (
  SELECT id 
  FROM paiements 
  WHERE statut = 'Payé' 
  ORDER BY RANDOM() 
  LIMIT 10
);