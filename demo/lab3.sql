-- Лабораторная работа №3. Представления, функции и триггеры ветклиники

-- 1. Как выглядит карточка питомца вместе с контактами владельца?
SELECT pet_id, pet_name, species, owner_name, owner_phone
FROM v_pet_owner_card
ORDER BY pet_id
LIMIT 10;

-- 2. Какие последние визиты и врачи отображаются в представлении?
SELECT visit_id, pet_name, owner_name, doctor_name, visit_date, status
FROM v_visit_details
ORDER BY visit_date DESC
LIMIT 10;

-- 3. Можно ли вакцинировать питомца № 2 сегодня, если его уже прививали в течение года?
-- expect: false
SELECT can_vaccinate(2, CURRENT_TIMESTAMP);

-- 4. Найти визиты к врачу № 1 через функцию с необязательными фильтрами.
SELECT visit_id, pet_name, doctor_name, visit_date, status
FROM search_visits(p_doctor_id => 1)
LIMIT 5;

-- 5. Добавить процедуру к временному визиту одной функцией и откатить тест.
BEGIN;
INSERT INTO visits (pet_id, doctor_id, visit_date, reason)
VALUES (1, 1, CURRENT_TIMESTAMP, 'Тест бизнес-функции Lab 3');
SELECT *
FROM add_visit_procedure(
    currval(pg_get_serial_sequence('visits', 'id')::regclass)::integer,
    6
);
ROLLBACK;

-- 6. Попытка повторно вакцинировать питомца № 2 в течение года запрещается триггером.
-- expect: error "минимум один год"
DO $$
DECLARE
    v_visit_id integer;
BEGIN
    INSERT INTO visits (pet_id, doctor_id, visit_date, reason)
    VALUES (2, 1, CURRENT_TIMESTAMP, 'Тест проверки годового интервала')
    RETURNING id INTO v_visit_id;

    PERFORM add_visit_procedure(v_visit_id, 3);
END;
$$;

-- 7. Как служебный триггер обновляет updated_at?
BEGIN;
SELECT id, updated_at FROM pets WHERE id = 1;
UPDATE pets
SET notes = 'Временная проверка триггера Lab 3'
WHERE id = 1;
SELECT id, updated_at FROM pets WHERE id = 1;
ROLLBACK;

-- 8. Какие изменения питомца записал аудитирующий триггер?
BEGIN;
UPDATE pets
SET notes = 'Временная проверка журнала Lab 3'
WHERE id = 1;
SELECT
    pet_id,
    operation,
    old_values ->> 'notes' AS old_notes,
    new_values ->> 'notes' AS new_notes,
    changed_by,
    changed_at
FROM pet_change_log
WHERE pet_id = 1
ORDER BY id DESC
LIMIT 1;
ROLLBACK;

-- 9. Как выглядел питомец № 1 непосредственно после временного изменения?
BEGIN;
UPDATE pets
SET notes = 'Состояние для проверки функции Lab 3'
WHERE id = 1;
SELECT pet_state_at(1, clock_timestamp()) AS pet_state;
ROLLBACK;

-- 10. Обновить материализованный отчёт и показать месячные итоги клиники.
REFRESH MATERIALIZED VIEW mv_monthly_procedure_report;
SELECT month, visit_count, procedure_count, revenue
FROM mv_monthly_procedure_report
ORDER BY month DESC
LIMIT 12;
