```create_messages_mart.sql
INSERT INTO default.messages_mart (
    customer_id, application_uuid, message_id, sent_date,
    sender, receiver, country, segment_count,
    delivery_status, attempt_number, delivery_time,
    price, currency, receiver_operator, direction,
    created_at, updated_at, deleted_at
)
SELECT
    -- customer_id: 8 клиентов (1-8)
    customer_id,
    -- application_uuid: 1-4 UUID для каждого customer_id
    CASE (customer_id * 4 + (rand() % 4))
        WHEN 1  THEN 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1'
        WHEN 2  THEN 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2'
        WHEN 3  THEN 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3'
        WHEN 4  THEN 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4'
        WHEN 5  THEN 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1'
        WHEN 6  THEN 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2'
        WHEN 7  THEN 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb3'
        WHEN 8  THEN 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb4'
        WHEN 9  THEN 'cccccccc-cccc-cccc-cccc-ccccccccccc1'
        WHEN 10 THEN 'cccccccc-cccc-cccc-cccc-ccccccccccc2'
        WHEN 11 THEN 'cccccccc-cccc-cccc-cccc-ccccccccccc3'
        WHEN 12 THEN 'cccccccc-cccc-cccc-cccc-ccccccccccc4'
        WHEN 13 THEN 'dddddddd-dddd-dddd-dddd-ddddddddddd1'
        WHEN 14 THEN 'dddddddd-dddd-dddd-dddd-ddddddddddd2'
        WHEN 15 THEN 'dddddddd-dddd-dddd-dddd-ddddddddddd3'
        WHEN 16 THEN 'dddddddd-dddd-dddd-dddd-ddddddddddd4'
        WHEN 17 THEN 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee1'
        WHEN 18 THEN 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee2'
        WHEN 19 THEN 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee3'
        WHEN 20 THEN 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeee4'
        WHEN 21 THEN 'ffffffff-ffff-ffff-ffff-fffffffffff1'
        WHEN 22 THEN 'ffffffff-ffff-ffff-ffff-fffffffffff2'
        WHEN 23 THEN 'ffffffff-ffff-ffff-ffff-fffffffffff3'
        WHEN 24 THEN 'ffffffff-ffff-ffff-ffff-fffffffffff4'
        WHEN 25 THEN 'gggggggg-gggg-gggg-gggg-ggggggggggg1'
        WHEN 26 THEN 'gggggggg-gggg-gggg-gggg-ggggggggggg2'
        WHEN 27 THEN 'gggggggg-gggg-gggg-gggg-ggggggggggg3'
        WHEN 28 THEN 'gggggggg-gggg-gggg-gggg-ggggggggggg4'
        WHEN 29 THEN 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhh1'
        WHEN 30 THEN 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhh2'
        WHEN 31 THEN 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhh3'
        WHEN 32 THEN 'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhh4'
    END AS application_uuid,
    -- message_id: уникальный UUID для каждой записи
    generateUUIDv4() AS message_id,
    -- sent_date: равномерно за 2025 год
    toDateTime64(
        '2025-01-01 00:00:01' + 
        toIntervalSecond(rand() % 31536000), 
        6
    ) AS sent_date,
    -- sender: из списка 19 значений
    arrayElement(
        ['Google','Steam','Amazon','PayPal','Uber','WhatsApp','Meta',
         'Grab','Airbnb','Netflix','LinkedIn','Outlook','Twilio','DHL',
         'Vodafone','monitoring','Spotify','Bolt','not_defined'],
        (rand() % 19) + 1
    ) AS sender,
    -- receiver: случайный номер телефона (11 цифр)
    79000000000 + rand() % 1000000000 AS receiver,
    -- country: из списка 13 значений
    arrayElement(
        ['Russian Federation','Kazakhstan','Azerbaijan','Kyrgyzstan','Tajikistan',
         'Belarus','Uzbekistan','Armenia','Georgia','Israel','Moldova','Abkhazia',
         'not_defined'],
        (rand() % 13) + 1
    ) AS country,
    -- segment_count: 1-14
    (rand() % 14) + 1 AS segment_count,
    -- delivery_status: 65% DELIVRD, остальные из 9 статусов
    CASE 
        WHEN rand() % 100 < 65 THEN 'DELIVRD'
        ELSE arrayElement(
            ['UNDELIV','EXPIRED','NO ROUTES','SENT','ROUTE FAILED',
             'REJECTD','VND CHN NOT BND','SUBMIT_RESP_TIMEOUT','UNKNOWN'],
            (rand() % 9) + 1
        )
    END AS delivery_status,
    -- attempt_number: 1-3
    (rand() % 3) + 1 AS attempt_number,
    -- delivery_time: 100-3000
    (rand() % 2901) + 100 AS delivery_time,
    -- price: 0.000-1.000
    round(rand() / 2147483647.0, 3) AS price,
    -- currency: из списка 3 значений
    arrayElement(['USD','RUB','EUR'], (rand() % 3) + 1) AS currency,
    -- receiver_operator: из списка 17 значений
    arrayElement(
        ['MTS','Beeline','MegaFon','Azercell','MKS','Tele2','All networks',
         'MEGACOM(Alfa Telecom)','Indigo Tajikistan','Beeline (Sky Mobile)','K-Cell',
         'O!(Nurtelecom)','Scartel','MobiUZ (MTS)','velcom','Altel','not_defined'],
        (rand() % 17) + 1
    ) AS receiver_operator,
    -- direction: 0 или 1
    rand() % 2 AS direction,
    -- created_at: случайная дата в 2025 году
    toDateTime64(
        '2025-01-01 00:00:01' + 
        toIntervalSecond(rand() % 31536000), 
        6
    ) AS created_at,
    -- updated_at: >= created_at (добавляем от 0 до 30 дней к created_at)
    toDateTime64(
        toUnixTimestamp(created_at) + (rand() % 2592000),
        6
    ) AS updated_at,
    -- deleted_at: 80% NULL, 20% >= updated_at (добавляем от 0 до 30 дней к updated_at)
    CASE 
        WHEN rand() % 100 < 80 THEN NULL
        ELSE toDateTime64(
            toUnixTimestamp(updated_at) + (rand() % 2592000),
            6
        )
    END AS deleted_at
FROM (
    SELECT (number % 8) + 1 AS customer_id
    FROM numbers(1000000)
);

-- =============================================
-- |   Очистка таблицы                         |
-- =============================================
--DROP TABLE IF EXISTS default.messages_mart;
```
