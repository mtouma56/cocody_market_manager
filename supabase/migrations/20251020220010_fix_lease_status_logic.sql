-- Location: supabase/migrations/20251020220010_fix_lease_status_logic.sql
-- Schema Analysis: Existing schema with baux table and statut_bail enum ['Actif', 'Expire bientôt', 'Expiré']
-- Integration Type: MODIFICATIVE - Fix existing status logic + add automatic triggers
-- Dependencies: public.baux table with date_debut, date_fin, statut columns

-- PARTIE 1: Ajouter 'Résilié' à l'enum statut_bail (CRITIQUE pour résolution d'erreur)
-- Cette commande doit être exécutée séparément et validée avant utilisation
ALTER TYPE public.statut_bail ADD VALUE 'Résilié';

-- COMMIT automatique pour valider le nouvel enum value avant utilisation
-- PostgreSQL exige que les nouvelles valeurs d'enum soient validées avant usage

-- PARTIE 2: Corriger tous les statuts existants selon les vraies dates
UPDATE public.baux
SET statut = CASE
  -- Si date_fin est dans le passé → Expiré
  WHEN date_fin < CURRENT_DATE THEN 'Expiré'::public.statut_bail
  
  -- Si date_fin est dans les 60 prochains jours → Expire bientôt
  WHEN date_fin >= CURRENT_DATE 
   AND date_fin <= CURRENT_DATE + INTERVAL '60 days' THEN 'Expire bientôt'::public.statut_bail
  
  -- Sinon → Actif
  ELSE 'Actif'::public.statut_bail
END
WHERE statut IN ('Actif'::public.statut_bail, 'Expire bientôt'::public.statut_bail, 'Expiré'::public.statut_bail);

-- Vérifier les résultats
-- SELECT numero_contrat, date_debut, date_fin, statut FROM public.baux ORDER BY date_fin;

-- PARTIE 3: Créer une fonction automatique pour mettre à jour les statuts

-- Fonction qui met à jour le statut d'un bail selon sa date
CREATE OR REPLACE FUNCTION public.update_bail_statut()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
  -- Ne change pas si résilié manuellement
  IF NEW.statut = 'Résilié'::public.statut_bail THEN
    RETURN NEW;
  END IF;
  
  -- Calcule le statut selon la date_fin
  IF NEW.date_fin < CURRENT_DATE THEN
    NEW.statut = 'Expiré'::public.statut_bail;
  ELSIF NEW.date_fin >= CURRENT_DATE 
    AND NEW.date_fin <= CURRENT_DATE + INTERVAL '60 days' THEN
    NEW.statut = 'Expire bientôt'::public.statut_bail;
  ELSE
    NEW.statut = 'Actif'::public.statut_bail;
  END IF;
  
  RETURN NEW;
END;
$func$;

-- Trigger qui s'exécute à chaque INSERT ou UPDATE
DROP TRIGGER IF EXISTS trigger_update_bail_statut ON public.baux;

CREATE TRIGGER trigger_update_bail_statut
  BEFORE INSERT OR UPDATE ON public.baux
  FOR EACH ROW
  EXECUTE FUNCTION public.update_bail_statut();

-- PARTIE 4: Fonction optionnelle pour mise à jour quotidienne de tous les statuts

-- Cette fonction peut être appelée via une cron job
CREATE OR REPLACE FUNCTION public.refresh_all_baux_statuts()
RETURNS VOID 
LANGUAGE plpgsql
SECURITY DEFINER
AS $refresh$
BEGIN
  UPDATE public.baux
  SET statut = CASE
    WHEN date_fin < CURRENT_DATE THEN 'Expiré'::public.statut_bail
    WHEN date_fin >= CURRENT_DATE 
     AND date_fin <= CURRENT_DATE + INTERVAL '60 days' THEN 'Expire bientôt'::public.statut_bail
    ELSE 'Actif'::public.statut_bail
  END
  WHERE statut != 'Résilié'::public.statut_bail;
  
  -- Log du nombre de baux mis à jour
  RAISE NOTICE 'Statuts de baux mis à jour automatiquement';
END;
$refresh$;

-- Commentaire pour expliquer la logique
COMMENT ON FUNCTION public.update_bail_statut() IS 'Met à jour automatiquement le statut des baux selon leur date de fin: Expiré (<aujourd''hui), Expire bientôt (0-60 jours), Actif (>60 jours). Préserve Résilié pour les résiliations manuelles.';
COMMENT ON FUNCTION public.refresh_all_baux_statuts() IS 'Fonction utilitaire pour mettre à jour tous les statuts de baux (pour cron job quotidien). Préserve les baux résiliés manuellement.';

-- PARTIE 5: Index pour optimiser les performances des requêtes de statut
CREATE INDEX IF NOT EXISTS idx_baux_statut_date_fin ON public.baux (statut, date_fin) WHERE actif = true;
CREATE INDEX IF NOT EXISTS idx_baux_date_fin ON public.baux (date_fin) WHERE actif = true AND statut != 'Résilié';

-- Commentaire d'explication pour la correction du bug
COMMENT ON TYPE public.statut_bail IS 'États possibles d''un bail: Actif (>60j), Expire bientôt (0-60j), Expiré (<0j), Résilié (résiliation manuelle)';