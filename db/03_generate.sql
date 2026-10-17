DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pets) THEN
        RAISE EXCEPTION 'Таблица pets пуста. Сначала заполните её данными.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM doctors) THEN
        RAISE EXCEPTION 'Таблица doctors пуста. Сначала заполните её данными.';
    END IF;
END
$$;

WITH pet_list AS (
    SELECT
        id,
        row_number() OVER (ORDER BY id) AS rn,
        count(*) OVER () AS total
    FROM pets
),
doctor_list AS (
    SELECT
        id,
        row_number() OVER (ORDER BY id) AS rn,
        count(*) OVER () AS total
    FROM doctors
),
generated AS (
    SELECT
        gs AS n,
        ((gs - 1) % (SELECT count(*) FROM pets)) + 1 AS pet_rn,
        ((gs - 1) % (SELECT count(*) FROM doctors)) + 1 AS doctor_rn
    FROM generate_series(1, 1000) AS gs
)
INSERT INTO visits (
    pet_id,
    doctor_id,
    visit_date,
    reason,
    diagnosis,
    notes
)
SELECT
    p.id,
    d.id,
    CURRENT_TIMESTAMP - g.n * INTERVAL '1 day',
    'Тестовый приём #' || g.n,
    'Сгенерированная запись',
    'Создано скриптом db/03_generate.sql'
FROM generated AS g
JOIN pet_list AS p ON p.rn = g.pet_rn
JOIN doctor_list AS d ON d.rn = g.doctor_rn;