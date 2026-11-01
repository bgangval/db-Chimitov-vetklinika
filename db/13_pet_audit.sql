CREATE TABLE IF NOT EXISTS pet_change_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_id integer NOT NULL,
    operation text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values jsonb,
    new_values jsonb,
    changed_by name NOT NULL,
    changed_at timestamptz NOT NULL
);

CREATE INDEX IF NOT EXISTS pet_change_log_pet_time_idx
    ON pet_change_log (pet_id, changed_at, id);

CREATE OR REPLACE FUNCTION audit_pet_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO pet_change_log (pet_id, operation, old_values, new_values, changed_by, changed_at)
        VALUES (NEW.id, TG_OP, NULL, to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO pet_change_log (pet_id, operation, old_values, new_values, changed_by, changed_at)
        VALUES (NEW.id, TG_OP, to_jsonb(OLD), to_jsonb(NEW), session_user, clock_timestamp());
        RETURN NEW;
    ELSE
        INSERT INTO pet_change_log (pet_id, operation, old_values, new_values, changed_by, changed_at)
        VALUES (OLD.id, TG_OP, to_jsonb(OLD), NULL, session_user, clock_timestamp());
        RETURN OLD;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_pets_audit ON pets;
CREATE TRIGGER trg_pets_audit
AFTER INSERT OR UPDATE OR DELETE ON pets
FOR EACH ROW
EXECUTE FUNCTION audit_pet_changes();
