# PUB/SUB example with using PostgreSQL notification
Система запускает опрос всех IoT устройств, опросы регистрируются в БД.
Пример реализации PUB/SUB используя PostgreSQL события.

## PostgreSQL 
Создаем статус IoT устройств и таблицу с описанием IoT устройств:
```sql
CREATE TYPE iot_status AS ENUM('unknow','work','fail');
CREATE TABLE iot_devices (
	id SERIAL PRIMARY KEY NOT NULL,
	name varchar(256),
	status iot_status,
	status_timeupdate TIMESTAMP
)
```
Создаем статус запроса:
```sql
CREATE TYPE req_status AS ENUM ('new', 'processing', 'succes', 'error');
```
Создаем таблицу для хранения всех устройств:
```sql
CREATE TABLE req_jobs(
	id SERIAL PRIMARY KEY,
	request_time TIMESTAMP,
	request_data VARCHAR(256),
	status req_status,
	status_update_time TIMESTAMP
);
```
Создаем триггер на изменение статуса запроса, в триггерной функции *req_jobs_status_notify* вызываем оповещение канала *req_jobs_status_channel*:
```sql
CREATE OR REPLACE FUNCTION req_jobs_status_notify() 
RETURNS TRIGGER AS
$BODY$
BEGIN
PERFORM pg_notify('req_jobs_status_channel', NEW.id::text);
RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER req_jobs_status
	AFTER INSERT OR UPDATE OF status
	ON req_jobs
	FOR EACH ROW
EXECUTE PROCEDURE req_jobs_status_notify();
```

Подписчик (Subscriber) - [type Subscriber struct](subscriber.go#L13).
Для того, что слушать канал *req_jobs_status_channel* от PostgreSQL используется метод Listen, который возвращает канал с id-данными
запроса. Пример кода:
```go
    connPq := "host=172.17.0.2 port=5432 user=user password=123qwe dbname=iot_jobs sslmode=disable"
	subscriber := NewSubscriber(ctxSubscriber, connPq)
	chGetRequest, err := subscriber.Listen("req_jobs_status_channel")
	
```
Далее запускаем цикл обработки id-данных запросов:
```go
    for req := range chGetRequest {
		fmt.Printf("[%s] Receive request id:%v", time.Now().String(), req.(string))
        .....
    }
```