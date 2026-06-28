```messages_mart.sql
CREATE TABLE IF NOT EXISTS default.messages_mart (
    customer_id UInt32,
    application_uuid UUID,
    message_id UUID,
    sent_date DateTime64(6),
    sender LowCardinality(Nullable(String)),
    receiver UInt64,
    country LowCardinality(Nullable(String)),
    segment_count UInt32,
    delivery_status LowCardinality(Nullable(String)),
    attempt_number UInt8,
    delivery_time UInt16,
    price Float32,
    currency LowCardinality(Nullable(String)),
    receiver_operator LowCardinality(Nullable(String)),
    direction UInt8,
    created_at DateTime64(6),
    updated_at DateTime64(6),
    deleted_at Nullable(DateTime64(6))
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(sent_date)
ORDER BY (customer_id, sent_date, message_id)
SETTINGS index_granularity = 8192;
```
