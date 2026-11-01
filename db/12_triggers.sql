ALTER TABLE pets
    ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT clock_timestamp();

CREATE OR REPLACE FUNCTION set_pets_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pets_updated_at ON pets;
CREATE TRIGGER trg_pets_updated_at
BEFORE UPDATE ON pets
FOR EACH ROW
EXECUTE FUNCTION set_pets_updated_at();

CREATE OR REPLACE FUNCTION enforce_annual_vaccination()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_pet_id integer;
    v_visit_date timestamptz;
    v_is_vaccination boolean;
BEGIN
    SELECT v.pet_id, v.visit_date
    INTO v_pet_id, v_visit_date
    FROM visits v
    WHERE v.id = NEW.visit_id;

    -- Let the foreign-key constraint report a missing visit.
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    SELECT pr.is_vaccination
    INTO v_is_vaccination
    FROM procedures pr
    WHERE pr.id = NEW.procedure_id;

    -- Let the foreign-key constraint report a missing procedure.
    IF NOT FOUND OR v_is_vaccination IS NOT TRUE THEN
        RETURN NEW;
    END IF;

    IF NOT can_vaccinate(v_pet_id, v_visit_date, NEW.visit_id) THEN
        RAISE EXCEPTION
            'Вакцинация питомца % запрещена: между прививками должен пройти минимум один год',
            v_pet_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_annual_vaccination ON visit_procedures;
CREATE TRIGGER trg_enforce_annual_vaccination
BEFORE INSERT OR UPDATE OF visit_id, procedure_id ON visit_procedures
FOR EACH ROW
EXECUTE FUNCTION enforce_annual_vaccination();
