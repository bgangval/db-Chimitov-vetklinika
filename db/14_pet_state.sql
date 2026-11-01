CREATE OR REPLACE FUNCTION pet_state_at(
    p_pet_id integer,
    p_at timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_change pet_change_log%ROWTYPE;
    v_state jsonb;
BEGIN
    IF p_at IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT *
    INTO v_change
    FROM pet_change_log
    WHERE pet_id = p_pet_id
      AND changed_at <= p_at
    ORDER BY changed_at DESC, id DESC
    LIMIT 1;

    IF FOUND THEN
        IF v_change.operation = 'DELETE' THEN
            RETURN NULL;
        END IF;
        RETURN v_change.new_values;
    END IF;

    -- Before the first audited update, OLD contains the baseline row.
    SELECT *
    INTO v_change
    FROM pet_change_log
    WHERE pet_id = p_pet_id
    ORDER BY changed_at, id
    LIMIT 1;

    IF FOUND THEN
        IF v_change.operation = 'INSERT' THEN
            RETURN NULL;
        END IF;
        RETURN v_change.old_values;
    END IF;

    SELECT to_jsonb(p)
    INTO v_state
    FROM pets p
    WHERE p.id = p_pet_id;

    RETURN v_state;
END;
$$;
