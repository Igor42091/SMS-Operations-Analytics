# SMS Operations Analytics

Тестовый проект по Data Engineer / Analytics Engineer: проектирование витрины SMS-сообщений в ClickHouse, генерация синтетических данных за 1 год в объеме 1 млн строк и сборка дашборда `SMS Operations` в Apache Superset.

Проект демонстрирует полный цикл работы с аналитической витриной: от DDL и до визуализации ключевых метрик и фильтров в Superset.

## Содержание

- [Описание задачи](#описание-задачи)
- [Реализовано](#реализовано)
- [Структура репозитория](#структура-репозитория)
- [Модель данных](#модель-данных)
- [Архитектурные решения](#архитектурные-решения)
- [Генерация данных](#генерация-данных)
- [Дашборд в Superset](#дашборд-в-superset)
- [Скриншоты](#скриншоты)
- [Итог](#итог)

## Описание задачи

Организация занимается международной SMS-рассылкой.  
Нужно было спроектировать витрину `messages_mart` в ClickHouse, поднять ClickHouse и Apache Superset в Docker, сгенерировать данные, и собрать дашборд `SMS Operations`.

Отдельный акцент сделан на технической реализации: выборе движка, сортировке, партиционирования, фильтров и подхода к хранению данных для аналитики.

## Реализовано

- Спроектирована витрина `messages_mart` в ClickHouse.
- Подготовлен DDL таблицы.
- Сгенерированы синтетические данные на 1 млн строк за период 1 год.
- Собран дашборд `SMS Operations` в Apache Superset.
- Подготовлены скриншоты дашборда и чартов.
- Описаны решения по сортировке, партиционированию и движку таблицы.

## Структура репозитория

```text
.
├── ddl/
│   └── messages_mart.sql
├── generator/
│   └── create_messages_mart.sql
├── screenshots/
│   ├── dashboard_revenue.jpg
|   ├── dashboard_delivery_statuses.jpg
│   ├── dashboard_number_of_messages.jpg
│   ├── sms_by_day_edit.jpg
│   ├── delivery_rate_edit.jpg
│   ├── top_countries_edit.jpg
│   ├── top_operators_edit.jpg
│   └── revenue_edit.jpg
└── README.md
```

## Модель данных

Витрина построена по принципу `одна строка = одно SMS`.  
Это удобно и для аналитики, и для интеграции через API, потому что каждая запись описывает одно сообщение целиком.

### Поля витрины

#### Идентификаторы

- `customer_id` — идентификатор клиента.
- `application_uuid` — UUID приложения клиента, привязанного к `customer_id`.
- `message_id` — UUID SMS-сообщения.

#### Время и адресация

- `sent_date` — дата и время отправки SMS.
- `sender` — имя отправителя.
- `receiver` — MSISDN получателя.
- `country` — страна назначения.
- `segment_count` — количество сегментов.

#### Статусы доставки

- `delivery_status` — итоговый статус доставки.
- `attempt_number` — количество попыток отправки.
- `delivery_time` — время доставки в миллисекундах.

#### Тарификация и направление

- `price` — цена SMS.
- `currency` — валюта.
- `receiver_operator` — оператор получателя.
- `direction` — направление трафика: inbound / outbound.

#### Метаданные

- `created_at` — время создания записи.
- `updated_at` — время последнего обновления.
- `deleted_at` — время soft-delete.

## Архитектурные решения

Для хранения данных выбран движок семейства MergeTree, так как он рассчитан на большие объемы данных и высокую скорость аналитических запросов, а данные внутри партиций физически сортируются по ключу.

### Выбор ключа сортировки

Ключ сортировки выбран исходя из типовых сценариев использования витрины:
- фильтрация по `customer_id`;
- запросы по периоду `sent_date`;
- агрегации по `delivery_status`, `country`, `receiver_operator`;
- исключение soft-delete через `deleted_at IS NULL`.

Практически это означает, что сначала максимально быстро отсекаются нужные данные по клиенту и времени, а уже затем выполняются группировки и построение графиков.  
Такой порядок особенно полезен для time series, top-N и big number чартов в Superset.

### Выбор партиционирования

Партиционирование по времени удобно для данных с выраженной временной природой, потому что:
- ускоряет запросы по датам;
- упрощает удаление старых данных;
- делает хранение предсказуемым и управляемым.

Для годового объема данных обычно уместно партиционирование по месяцу, если не требуется слишком мелкая гранулярность.  
Это дает баланс между количеством партиций и удобством обслуживания таблицы.

### Индексы и движок

MergeTree использует сортировку данных по ключу и разреженный индекс (Sparse Index), что помогает уменьшать объем читаемых данных на аналитических запросах.  
Поэтому в проекте важны не только сами колонки, но и их порядок в `ORDER BY` и `PARTITION BY`.

## DDL таблицы

Ниже приведен пример целевой структуры витрины.

DDL-скрипт для создания витрины `messages_mart` доступен по [ссылке](https://github.com/Igor42091/SMS-Operations-Analytics/blob/main/ddl/messages_mart.sql).

[![DDL Schema](https://img.shields.io/badge/DDL-messages_mart.sql-blue)](https://github.com/Igor42091/SMS-Operations-Analytics/blob/main/ddl/messages_mart.sql)

Этот вариант можно адаптировать под конкретный сценарий использования, если в проекте предполагаются другие доминирующие фильтры или частые выборки по отдельным атрибутам.

## Генерация данных

Генератор создает синтетические данные за 1 год в объеме 1 000 000 строк.  

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

### Особенности генерации

- 5–10 клиентов.
- 1–4 приложения на клиента.
- Распределение по странам и операторам.
- Несколько типов валют — USD, EUR, RUB


## Дашборд в Superset

В Apache Superset собран дашборд `SMS Operations` на данных `messages_mart`.  
Основные фильтры дашборда — `customer_id` и диапазон `sent_date`, а также дополнительные фильтры по `country`, `delivery_status`.

### Основные чарты

- **SMS по дням** — time series по `count(message_id)`.
- **Доля доставленных сообщений** — big number по доле `delivery_status = 'DELIVRD'`.
- **Кол-во доставленных сообщений** - big number по количеству сообщений в статусе `delivery_status = 'DELIVRD'`.
- **Топ-10 стран по количеству SMS** — bar chart по `count(message_id)` с top 10.
- **Топ-10 операторов по количеству SMS** — bar chart по `receiver_operator`.
- **Выручка** — time series и big number по `sum(price)` по валютам.

### Дополнительные чарты

- failed statuses;
- delivery_time;
- segment_count;
- inbound / outbound по `direction`.

### Логика фильтрации

Во всех запросах исключаются soft-delete записи через `WHERE deleted_at IS NULL`.  
Это делает метрики консистентными и приближенными к рабочей аналитике.


### Порядок выполнения

1. Поднимаются сервисы ClickHouse и Superset.
2. Создается таблица `messages_mart` в ClickHouse.
3. Генерируются данные в ClickHouse и встявляются в таблицу.
4. Создаются датасет, чарты и дашборд в Superset.
6. Проверяется корректность фильтров.

## Скриншоты

Скриншоты дашборда и чартов лежат в директории `screenshots/`.

### Что должно быть в папке

- полный скриншот дашборда `SMS Operations` с видимыми фильтрами;
- отдельные скриншоты каждого чарта в режиме edit;

Наименование файлов:

```text
screenshots/
├── dashboard_revenue.jpg
├── dashboard_delivery_statuses.jpg
├── dashboard_number_of_messages.jpg
├── sms_by_day_edit.jpg
├── delivery_rate_edit.jpg
├── top_countries_edit.jpg
├── top_operators_edit.jpg
└── revenue_edit.jpg
```


## Итог

Проект показывает практический подход к построению аналитической витрины в ClickHouse и визуализации данных в Apache Superset.  
В нем собраны ключевые элементы инженерного решения: DDL, генерация данных, фильтры, метрики, дашборд.



