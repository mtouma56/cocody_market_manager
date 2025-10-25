-- Location: supabase/migrations/20251020221236_fix_lease_status_enum_safe.sql
-- Schema Analysis: Existing schema with baux table and statut_bail enum ['Actif', 'Expire bientôt', 'Expiré']
-- Integration Type: MODIFICATIVE - Fix enum error + add automatic triggers safely
-- Dependencies: public.baux table with date_debut, date_fin, statut columns

-- ÉTAPE 1: Vérifier et ajouter 'Résilié' à l'enum de manière sécurisée
DO $$
BEGIN
  -- Vérifier si la valeur 'Résilié' existe déjà
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumtypid = 'public.statut_bail'::regtype 
    AND enumlabel = 'Résilié'
  ) THEN
    -- Ajouter la valeur seulement si elle n'existe pas
    ALTER TYPE public.statut_bail ADD VALUE 'Résilié';
    RAISE NOTICE 'Valeur "Résilié" ajoutée à l''enum statut_bail';
  ELSE
    RAISE NOTICE 'Valeur "Résilié" existe déjà dans l''enum statut_bail';
  END IF;
END $$;

-- ÉTAPE 2: Corriger tous les statuts existants selon les vraies dates
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

-- ÉTAPE 3: Créer une fonction automatique pour mettre à jour les statuts
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

-- ÉTAPE 4: Créer le trigger qui s'exécute à chaque INSERT ou UPDATE
DROP TRIGGER IF EXISTS trigger_update_bail_statut ON public.baux;

CREATE TRIGGER trigger_update_bail_statut
  BEFORE INSERT OR UPDATE ON public.baux
  FOR EACH ROW
  EXECUTE FUNCTION public.update_bail_statut();

-- ÉTAPE 5: Fonction optionnelle pour mise à jour quotidienne de tous les statuts
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
  
  RAISE NOTICE 'Statuts de baux mis à jour automatiquement';
END;
$refresh$;

-- ÉTAPE 6: Ajouter des commentaires pour expliquer la logique
COMMENT ON FUNCTION public.update_bail_statut() IS 'Met à jour automatiquement le statut des baux selon leur date de fin: Expiré (<aujourd''hui), Expire bientôt (0-60 jours), Actif (>60 jours). Préserve Résilié pour les résiliations manuelles.';
COMMENT ON FUNCTION public.refresh_all_baux_statuts() IS 'Fonction utilitaire pour mettre à jour tous les statuts de baux (pour cron job quotidien). Préserve les baux résiliés manuellement.';

-- ÉTAPE 7: Index pour optimiser les performances des requêtes de statut
CREATE INDEX IF NOT EXISTS idx_baux_statut_date_fin ON public.baux (statut, date_fin) WHERE actif = true;
CREATE INDEX IF NOT EXISTS idx_baux_date_fin ON public.baux (date_fin) WHERE actif = true AND statut != 'Résilié';

-- ÉTAPE 8: Commentaire d'explication pour la correction du bug
COMMENT ON TYPE public.statut_bail IS 'États possibles d''un bail: Actif (>60j), Expire bientôt (0-60j), Expiré (<0j), Résilié (résiliation manuelle)';

-- ÉTAPE 9: Vérifier les résultats finaux
DO $$
DECLARE
    total_baux INTEGER;
    baux_actifs INTEGER;
    baux_expires INTEGER;
    baux_expire_bientot INTEGER;
    baux_resilies INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_baux FROM public.baux WHERE actif = true;
    SELECT COUNT(*) INTO baux_actifs FROM public.baux WHERE actif = true AND statut = 'Actif';
    SELECT COUNT(*) INTO baux_expires FROM public.baux WHERE actif = true AND statut = 'Expiré';
    SELECT COUNT(*) INTO baux_expire_bientot FROM public.baux WHERE actif = true AND statut = 'Expire bientôt';
    SELECT COUNT(*) INTO baux_resilies FROM public.baux WHERE actif = true AND statut = 'Résilié';
    
    RAISE NOTICE '✅ RÉSULTATS DE LA CORRECTION:';
    RAISE NOTICE '📊 Total baux actifs: %', total_baux;
    RAISE NOTICE '🟢 Baux Actifs: %', baux_actifs;
    RAISE NOTICE '🟡 Baux Expire bientôt: %', baux_expire_bientot;
    RAISE NOTICE '🔴 Baux Expirés: %', baux_expires;
    RAISE NOTICE '⚫ Baux Résiliés: %', baux_resilies;
    RAISE NOTICE '✅ Statuts corrigés avec succès! Enum "Résilié" disponible.';
END $$;