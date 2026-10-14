-- Лаба 1. Модель данных и схема ветеринарной клиники.
-- Запуск: dbcheck run demo/lab1.sql

-- 1. Проверяем, что в базе созданы все 6 таблиц
-- expect: value 6
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- 2. Проверяем, что добавлено 10 владельцев
-- expect: value 10
SELECT count(*) FROM owners;

-- 3. Проверяем, что добавлено 10 животных
-- expect: value 10
SELECT count(*) FROM pets;

-- 4. Проверяем, что добавлено 10 ветеринарных врачей
-- expect: value 10
SELECT count(*) FROM doctors;

-- 5. Проверяем, что добавлено 10 приёмов
-- expect: value 10
SELECT count(*) FROM visits;

-- 6. Проверяем, что добавлено 10 видов процедур
-- expect: value 10
SELECT count(*) FROM procedures;

-- 7. Проверяем, что добавлено 10 записей о процедурах на приёмах
-- expect: value 10
SELECT count(*) FROM visit_procedures;

-- 8. Повторный номер телефона владельца: ошибка UNIQUE
-- expect: error unique
INSERT INTO owners (full_name, phone, email, address)
VALUES (
'Тестовый владелец',
'+79000000001',
'test-owner@example.com',
'Тестовый адрес'
);

-- 9. Отрицательная стоимость процедуры: ошибка CHECK
-- expect: error check
INSERT INTO procedures (name, description, price, duration_minutes)
VALUES (
'Тестовая процедура',
'Проверка ограничения стоимости',
-100,
15
);

-- 10. Приём для несуществующего животного: ошибка FK
-- expect: error fk
INSERT INTO visits (pet_id, doctor_id, reason)
VALUES (999999, 1, 'Проверка внешнего ключа');
