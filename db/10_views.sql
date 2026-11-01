CREATE OR REPLACE VIEW v_pet_owner_card AS
SELECT
    p.id AS pet_id,
    p.name AS pet_name,
    p.species,
    p.breed,
    p.birth_date,
    o.id AS owner_id,
    o.full_name AS owner_name,
    o.phone AS owner_phone,
    o.email AS owner_email
FROM pets p
JOIN owners o ON o.id = p.owner_id;

CREATE OR REPLACE VIEW v_visit_details AS
SELECT
    v.id AS visit_id,
    v.visit_date,
    v.reason,
    v.diagnosis,
    v.status,
    p.id AS pet_id,
    p.name AS pet_name,
    o.full_name AS owner_name,
    d.id AS doctor_id,
    d.full_name AS doctor_name,
    d.specialization
FROM visits v
JOIN pets p ON p.id = v.pet_id
JOIN owners o ON o.id = p.owner_id
JOIN doctors d ON d.id = v.doctor_id;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_procedure_report AS
SELECT
    date_trunc('month', v.visit_date) AS month,
    COUNT(DISTINCT v.id) AS visit_count,
    COUNT(vp.procedure_id) AS procedure_count,
    COALESCE(SUM(vp.actual_price * vp.quantity), 0)::numeric(12, 2) AS revenue
FROM visits v
LEFT JOIN visit_procedures vp ON vp.visit_id = v.id
GROUP BY date_trunc('month', v.visit_date);
