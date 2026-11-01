CREATE OR REPLACE FUNCTION can_vaccinate(
    p_pet_id integer,
    p_visit_date timestamptz,
    p_exclude_visit_id integer DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
    SELECT p_visit_date IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM visit_procedures vp
            JOIN visits existing_visit ON existing_visit.id = vp.visit_id
            JOIN procedures pr ON pr.id = vp.procedure_id
            WHERE existing_visit.pet_id = p_pet_id
              AND pr.is_vaccination
              AND existing_visit.id IS DISTINCT FROM p_exclude_visit_id
              AND existing_visit.visit_date > p_visit_date - INTERVAL '1 year'
              AND existing_visit.visit_date < p_visit_date + INTERVAL '1 year'
       );
$$;

CREATE OR REPLACE FUNCTION add_visit_procedure(
    p_visit_id integer,
    p_procedure_id integer,
    p_quantity integer DEFAULT 1,
    p_actual_price numeric(10, 2) DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS TABLE (
    visit_id integer,
    procedure_id integer,
    quantity integer,
    actual_price numeric(10, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_catalog_price numeric(10, 2);
BEGIN
    SELECT pr.price
    INTO v_catalog_price
    FROM procedures pr
    WHERE pr.id = p_procedure_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Процедура с id % не найдена', p_procedure_id;
    END IF;

    RETURN QUERY
    INSERT INTO visit_procedures AS inserted (
        visit_id,
        procedure_id,
        quantity,
        actual_price,
        notes
    )
    VALUES (
        p_visit_id,
        p_procedure_id,
        p_quantity,
        COALESCE(p_actual_price, v_catalog_price),
        p_notes
    )
    RETURNING
        inserted.visit_id,
        inserted.procedure_id,
        inserted.quantity,
        inserted.actual_price;
END;
$$;

CREATE OR REPLACE FUNCTION search_visits(
    p_pet_id integer DEFAULT NULL,
    p_doctor_id integer DEFAULT NULL,
    p_status text DEFAULT NULL,
    p_from timestamptz DEFAULT NULL,
    p_to timestamptz DEFAULT NULL
)
RETURNS TABLE (
    visit_id integer,
    pet_id integer,
    pet_name text,
    owner_name text,
    doctor_id integer,
    doctor_name text,
    visit_date timestamptz,
    status text,
    reason text
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        v.id,
        p.id,
        p.name,
        o.full_name,
        d.id,
        d.full_name,
        v.visit_date,
        v.status,
        v.reason
    FROM visits v
    JOIN pets p ON p.id = v.pet_id
    JOIN owners o ON o.id = p.owner_id
    JOIN doctors d ON d.id = v.doctor_id
    WHERE (p_pet_id IS NULL OR v.pet_id = p_pet_id)
      AND (p_doctor_id IS NULL OR v.doctor_id = p_doctor_id)
      AND (p_status IS NULL OR v.status = p_status)
      AND (p_from IS NULL OR v.visit_date >= p_from)
      AND (p_to IS NULL OR v.visit_date < p_to)
    ORDER BY v.visit_date DESC, v.id DESC;
$$;
