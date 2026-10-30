-- Лабораторная работа №2. Запросы к данным ветеринарной клиники

-- 1. Какие питомцы принадлежат каждому владельцу?
SELECT
    p.id AS pet_id,
    p.name AS pet_name,
    p.species,
    o.full_name AS owner_name,
    o.phone AS owner_phone
FROM pets p
JOIN owners o ON o.id = p.owner_id
ORDER BY o.full_name, p.name;

-- 2. Какие питомцы посещали клинику и какие врачи их принимали?
SELECT
    v.id AS visit_id,
    p.name AS pet_name,
    o.full_name AS owner_name,
    d.full_name AS doctor_name,
    d.specialization,
    v.visit_date,
    v.reason,
    v.status
FROM visits v
JOIN pets p ON p.id = v.pet_id
JOIN owners o ON o.id = p.owner_id
JOIN doctors d ON d.id = v.doctor_id
ORDER BY v.visit_date DESC
LIMIT 20;

-- 3. Какие процедуры проводились во время визитов питомцев?
SELECT
    v.id AS visit_id,
    p.name AS pet_name,
    pr.name AS procedure_name,
    vp.quantity,
    vp.actual_price,
    vp.notes
FROM visits v
JOIN pets p ON p.id = v.pet_id
JOIN visit_procedures vp ON vp.visit_id = v.id
JOIN procedures pr ON pr.id = vp.procedure_id
ORDER BY v.visit_date DESC;

-- 4. Сколько визитов провёл каждый врач?
SELECT
    d.id AS doctor_id,
    d.full_name AS doctor_name,
    COUNT(v.id) AS visit_count
FROM doctors d
JOIN visits v ON v.doctor_id = d.id
GROUP BY d.id, d.full_name
ORDER BY visit_count DESC, d.full_name;

-- 5. У каких врачей средняя стоимость процедур выше 500 рублей?
SELECT
    d.id AS doctor_id,
    d.full_name AS doctor_name,
    ROUND(AVG(vp.actual_price), 2) AS average_procedure_price
FROM doctors d
JOIN visits v ON v.doctor_id = d.id
JOIN visit_procedures vp ON vp.visit_id = v.id
GROUP BY d.id, d.full_name
HAVING AVG(vp.actual_price) > 500
ORDER BY average_procedure_price DESC;

-- 6. Какие процедуры ещё ни разу не назначались на визиты?
SELECT
    pr.id AS procedure_id,
    pr.name AS procedure_name,
    pr.price
FROM procedures pr
LEFT JOIN visit_procedures vp ON vp.procedure_id = pr.id
WHERE vp.procedure_id IS NULL
ORDER BY pr.name;

-- 7. Какие питомцы посещали врача-дерматолога?
SELECT p.id, p.name, p.species
FROM pets p
WHERE p.id IN (
    SELECT v.pet_id
    FROM visits v
    JOIN doctors d ON d.id = v.doctor_id
    WHERE d.specialization = 'Дерматолог'
)
ORDER BY p.name;

-- 8. Какие владельцы приводили питомцев на вакцинацию?
SELECT o.id, o.full_name
FROM owners o
WHERE EXISTS (
    SELECT 1
    FROM pets p
    JOIN visits v ON v.pet_id = p.id
    JOIN visit_procedures vp ON vp.visit_id = v.id
    JOIN procedures pr ON pr.id = vp.procedure_id
    WHERE p.owner_id = o.id
      AND pr.is_vaccination
)
ORDER BY o.full_name;

-- 9. Какие процедуры стоят дороже средней цены по каталогу?
SELECT id, name, price
FROM procedures
WHERE price > (
    SELECT AVG(price)
    FROM procedures
)
ORDER BY price DESC, name;

-- 10. Добавить временного владельца и показать добавленную запись.
BEGIN;
INSERT INTO owners (full_name, phone, email, address)
VALUES ('Тестовый владелец Lab 2', '+79990000001', 'lab2-test@example.com', 'Тестовый адрес')
RETURNING id, full_name, phone, email, address;
ROLLBACK;

-- 11. Как меняется адрес временного владельца после UPDATE?
BEGIN;
INSERT INTO owners (full_name, phone, email, address)
VALUES ('Тестовый владелец Lab 2', '+79990000001', 'lab2-test@example.com', 'Старый тестовый адрес');
SELECT id, full_name, address FROM owners WHERE phone = '+79990000001';
UPDATE owners
SET address = 'Новый тестовый адрес'
WHERE phone = '+79990000001';
SELECT id, full_name, address FROM owners WHERE phone = '+79990000001';
ROLLBACK;

-- 12. Удалить временного владельца и показать результат удаления.
BEGIN;
INSERT INTO owners (full_name, phone, email, address)
VALUES ('Тестовый владелец Lab 2', '+79990000001', 'lab2-test@example.com', 'Тестовый адрес');
SELECT id, full_name, phone FROM owners WHERE phone = '+79990000001';
DELETE FROM owners
WHERE phone = '+79990000001';
SELECT COUNT(*) AS remaining_test_owners
FROM owners
WHERE phone = '+79990000001';
ROLLBACK;

-- 13. Какие три самые дорогие процедуры есть в каждой категории: вакцинация и остальные?
WITH ranked_procedures AS (
    SELECT
        id,
        name,
        price,
        is_vaccination,
        ROW_NUMBER() OVER (
            PARTITION BY is_vaccination
            ORDER BY price DESC, name
        ) AS position_in_category
    FROM procedures
)
SELECT
    CASE WHEN is_vaccination THEN 'Вакцинация' ELSE 'Другие процедуры' END AS category,
    name,
    price,
    position_in_category
FROM ranked_procedures
WHERE position_in_category <= 3
ORDER BY is_vaccination DESC, position_in_category;

-- 14. Как накапливается выручка от процедур по мере проведения визитов?
SELECT
    v.visit_date,
    p.name AS pet_name,
    pr.name AS procedure_name,
    vp.actual_price * vp.quantity AS visit_amount,
    SUM(vp.actual_price * vp.quantity) OVER (
        ORDER BY v.visit_date, v.id, pr.id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM visit_procedures vp
JOIN visits v ON v.id = vp.visit_id
JOIN pets p ON p.id = v.pet_id
JOIN procedures pr ON pr.id = vp.procedure_id
ORDER BY v.visit_date, v.id, pr.id;

-- 15. Как менялось число визитов по месяцам и на сколько процентов оно изменилось?
WITH monthly_visits AS (
    SELECT
        date_trunc('month', visit_date) AS month,
        COUNT(*) AS visit_count
    FROM visits
    GROUP BY date_trunc('month', visit_date)
), visits_with_previous_month AS (
    SELECT
        month,
        visit_count,
        LAG(visit_count) OVER (ORDER BY month) AS previous_month_count
    FROM monthly_visits
)
SELECT
    month,
    visit_count,
    previous_month_count,
    ROUND(
        100.0 * (visit_count - previous_month_count)
        / NULLIF(previous_month_count, 0),
        2
    ) AS change_percent
FROM visits_with_previous_month
ORDER BY month;

-- 16. Сколько визитов было каждый календарный день, включая дни без визитов?
WITH RECURSIVE date_bounds AS (
    SELECT MIN(visit_date::date) AS first_day, MAX(visit_date::date) AS last_day
    FROM visits
), calendar(day) AS (
    SELECT first_day
    FROM date_bounds
    WHERE first_day IS NOT NULL

    UNION ALL

    SELECT calendar.day + 1
    FROM calendar
    CROSS JOIN date_bounds
    WHERE calendar.day < date_bounds.last_day
), daily_visits AS (
    SELECT visit_date::date AS day, COUNT(*) AS visit_count
    FROM visits
    GROUP BY visit_date::date
)
SELECT
    calendar.day,
    COALESCE(daily_visits.visit_count, 0) AS visit_count
FROM calendar
LEFT JOIN daily_visits ON daily_visits.day = calendar.day
ORDER BY calendar.day;
