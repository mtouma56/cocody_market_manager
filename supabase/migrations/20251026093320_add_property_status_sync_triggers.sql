-- Location: supabase/migrations/20251026093320_add_property_status_sync_triggers.sql
-- Schema Analysis: Existing locaux and baux tables with proper relationships
-- Integration Type: Enhancement - Adding status synchronization logic
-- Dependencies: public.locaux, public.baux, public.statut_local, public.statut_bail

-- Function to synchronize property status with lease status
CREATE OR REPLACE FUNCTION public.sync_local_statut()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if there's an active lease for this property
  IF EXISTS (
    SELECT 1 FROM public.baux 
    WHERE local_id = COALESCE(NEW.local_id, OLD.local_id)
    AND statut = 'Actif'::public.statut_bail
  ) THEN
    -- Active lease exists → Property must be Occupé
    UPDATE public.locaux 
    SET statut = 'Occupé'::public.statut_local,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.local_id, OLD.local_id)
    AND statut != 'Occupé'::public.statut_local;
  ELSE
    -- No active lease → Property must be Disponible
    UPDATE public.locaux 
    SET statut = 'Disponible'::public.statut_local,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.local_id, OLD.local_id)
    AND statut != 'Disponible'::public.statut_local;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Function to validate property status changes
CREATE OR REPLACE FUNCTION public.validate_local_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_active_lease BOOLEAN := FALSE;
BEGIN
  -- Check if property has an active lease
  SELECT EXISTS (
    SELECT 1 FROM public.baux 
    WHERE local_id = NEW.id
    AND statut = 'Actif'::public.statut_bail
  ) INTO has_active_lease;
  
  -- Validate status change rules
  IF has_active_lease AND NEW.statut = 'Disponible'::public.statut_local THEN
    RAISE EXCEPTION 'Property with active lease cannot be set to Disponible. Terminate lease first.';
  END IF;
  
  IF NOT has_active_lease AND NEW.statut = 'Occupé'::public.statut_local THEN
    RAISE EXCEPTION 'Property without active lease cannot be set to Occupé. Create lease first.';
  END IF;
  
  RETURN NEW;
END;
$$;

-- Triggers on baux table for INSERT/UPDATE/DELETE
DROP TRIGGER IF EXISTS trigger_sync_local_statut_insert ON public.baux;
CREATE TRIGGER trigger_sync_local_statut_insert
AFTER INSERT ON public.baux
FOR EACH ROW
EXECUTE FUNCTION public.sync_local_statut();

DROP TRIGGER IF EXISTS trigger_sync_local_statut_update ON public.baux;
CREATE TRIGGER trigger_sync_local_statut_update
AFTER UPDATE ON public.baux
FOR EACH ROW
EXECUTE FUNCTION public.sync_local_statut();

DROP TRIGGER IF EXISTS trigger_sync_local_statut_delete ON public.baux;
CREATE TRIGGER trigger_sync_local_statut_delete
AFTER DELETE ON public.baux
FOR EACH ROW
EXECUTE FUNCTION public.sync_local_statut();

-- Trigger on locaux table for status validation
DROP TRIGGER IF EXISTS trigger_validate_local_status ON public.locaux;
CREATE TRIGGER trigger_validate_local_status
BEFORE UPDATE ON public.locaux
FOR EACH ROW
WHEN (OLD.statut IS DISTINCT FROM NEW.statut)
EXECUTE FUNCTION public.validate_local_status_change();

-- Initial sync: Update all properties to match their lease status
DO $$
DECLARE
  local_record RECORD;
  has_active_lease BOOLEAN;
  correct_status public.statut_local;
BEGIN
  FOR local_record IN SELECT id, statut FROM public.locaux
  LOOP
    -- Check if this property has an active lease
    SELECT EXISTS (
      SELECT 1 FROM public.baux 
      WHERE local_id = local_record.id
      AND statut = 'Actif'::public.statut_bail
    ) INTO has_active_lease;
    
    -- Determine correct status
    correct_status := CASE 
      WHEN has_active_lease THEN 'Occupé'::public.statut_local
      ELSE 'Disponible'::public.statut_local
    END;
    
    -- Update if status is incorrect
    IF local_record.statut != correct_status THEN
      UPDATE public.locaux 
      SET statut = correct_status,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = local_record.id;
      
      RAISE NOTICE 'Property % status corrected from % to %', 
        local_record.id, local_record.statut, correct_status;
    END IF;
  END LOOP;
END $$;

-- Test the synchronization
SELECT 'Property status synchronization triggers installed successfully' as status;