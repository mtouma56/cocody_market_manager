-- ═══════════════════════════════════════════════════════════
-- PARTIE 1 - SUPABASE : DÉTECTION ET NETTOYAGE DES CONFLITS
-- ═══════════════════════════════════════════════════════════

-- Étape 1 : Créer fonction de détection des conflits
CREATE OR REPLACE FUNCTION get_locaux_conflits()
RETURNS TABLE (
  local_id UUID,
  local_numero TEXT,
  nb_baux_actifs BIGINT,
  details TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.id,
    l.numero,
    COUNT(*)::BIGINT,
    STRING_AGG(
      b.numero_contrat || ' (' || c.nom || ' - créé le ' || 
      TO_CHAR(b.created_at, 'DD/MM/YYYY') || ')', 
      ' | '
    )
  FROM locaux l
  JOIN baux b ON b.local_id = l.id
  JOIN commercants c ON b.commercant_id = c.id
  WHERE b.statut = 'Actif'
  GROUP BY l.id, l.numero
  HAVING COUNT(*) > 1
  ORDER BY l.numero;
END;
$$ LANGUAGE plpgsql;

-- Étape 2 : Fonction de résolution automatique des conflits
CREATE OR REPLACE FUNCTION resoudre_conflits_baux()
RETURNS TABLE (
  local_numero TEXT,
  bail_garde TEXT,
  baux_resilies TEXT[]
) AS $$
DECLARE
  conflit RECORD;
  bail_a_garder RECORD;
  bail_a_resilier RECORD;
  baux_resilies_list TEXT[];
BEGIN
  -- Pour chaque local en conflit
  FOR conflit IN 
    SELECT l.id as local_id, l.numero as local_numero
    FROM locaux l
    JOIN baux b ON b.local_id = l.id
    WHERE b.statut = 'Actif'
    GROUP BY l.id, l.numero
    HAVING COUNT(*) > 1
  LOOP
    baux_resilies_list := ARRAY[]::TEXT[];
    
    -- Trouver le bail le plus récent à garder
    SELECT b.id, b.numero_contrat INTO bail_a_garder
    FROM baux b
    WHERE b.local_id = conflit.local_id
    AND b.statut = 'Actif'
    ORDER BY b.created_at DESC
    LIMIT 1;
    
    -- Résilier tous les autres baux actifs pour ce local
    FOR bail_a_resilier IN
      SELECT b.id, b.numero_contrat
      FROM baux b
      WHERE b.local_id = conflit.local_id
      AND b.statut = 'Actif'
      AND b.id != bail_a_garder.id
    LOOP
      -- Résilier le bail
      UPDATE baux
      SET 
        statut = 'Résilié',
        date_fin = NOW()
      WHERE id = bail_a_resilier.id;
      
      baux_resilies_list := array_append(baux_resilies_list, bail_a_resilier.numero_contrat);
      
      RAISE NOTICE 'Résiliation bail % pour local %', bail_a_resilier.numero_contrat, conflit.local_numero;
    END LOOP;
    
    -- Retourner résultat
    RETURN QUERY SELECT 
      conflit.local_numero,
      bail_a_garder.numero_contrat,
      baux_resilies_list;
  END LOOP;
  
  RETURN;
END;
$$ LANGUAGE plpgsql;

-- Étape 3 : Ajouter contrainte d'unicité pour empêcher futurs conflits
-- Index unique : UN SEUL bail actif par local
CREATE UNIQUE INDEX IF NOT EXISTS idx_baux_unique_actif_par_local 
ON baux (local_id) 
WHERE statut = 'Actif';

-- Étape 4 : Fonction de validation avant insertion/modification
CREATE OR REPLACE FUNCTION verifier_bail_unique_actif()
RETURNS TRIGGER AS $$
BEGIN
  -- Si on essaie de créer/modifier un bail actif
  IF NEW.statut = 'Actif' THEN
    -- Vérifier qu'il n'existe pas déjà un bail actif pour ce local
    IF EXISTS (
      SELECT 1 FROM baux 
      WHERE local_id = NEW.local_id 
      AND statut = 'Actif'
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
    ) THEN
      RAISE EXCEPTION 'Ce local a déjà un bail actif. Un local ne peut avoir qu''un seul bail actif à la fois.';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer trigger de validation unique
DROP TRIGGER IF EXISTS trigger_bail_unique_actif ON baux;
CREATE TRIGGER trigger_bail_unique_actif
BEFORE INSERT OR UPDATE ON baux
FOR EACH ROW
EXECUTE FUNCTION verifier_bail_unique_actif();

-- Étape 5 : Résoudre automatiquement les conflits existants
-- Cette fonction sera appelée une seule fois lors de la migration
DO $$
DECLARE
    conflict_count INTEGER;
BEGIN
    -- Compter les conflits existants
    SELECT COUNT(*) INTO conflict_count FROM get_locaux_conflits();
    
    IF conflict_count > 0 THEN
        RAISE NOTICE 'Résolution de % conflits détectés...', conflict_count;
        PERFORM resoudre_conflits_baux();
        RAISE NOTICE 'Conflits résolus automatiquement';
    ELSE
        RAISE NOTICE 'Aucun conflit détecté - système conforme';
    END IF;
END $$;

-- Ajouter commentaires pour documentation
COMMENT ON FUNCTION get_locaux_conflits() IS 'Détecte les locaux ayant plusieurs baux actifs simultanément';
COMMENT ON FUNCTION resoudre_conflits_baux() IS 'Résout automatiquement les conflits en gardant le bail le plus récent';
COMMENT ON FUNCTION verifier_bail_unique_actif() IS 'Empêche la création de baux multiples actifs pour un même local';