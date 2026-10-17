SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

SELECT count(*) FROM owners;

SELECT count(*) FROM pets;

SELECT count(*) FROM doctors;

SELECT count(*) FROM visits;

SELECT count(*) FROM procedures;

SELECT count(*) FROM visit_procedures;


-- 7. Проверка ограничения UNIQUE
-- expect: error unique
INSERT INTO owners (full_name, phone, email, address)
VALUES (
    'Тестовый владелец',
    '+79000000001',
    'test-owner@example.com',
    'Тестовый адрес'
);


-- 8. Проверка ограничения CHECK
-- expect: error check
INSERT INTO procedures (name, description, price, duration_minutes)
VALUES (
    'Тестовая процедура',
    'Проверка ограничения стоимости',
    -100,
    15
);


-- 9. Проверка внешнего ключа
-- expect: error fk
INSERT INTO visits (pet_id, doctor_id, reason)
VALUES (999999, 1, 'Проверка внешнего ключа');