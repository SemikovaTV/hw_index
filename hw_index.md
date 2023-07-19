# Домашнее задание к занятию «Индексы» - Семикова Т.В. FOPS-9
### Задание 1

Напишите запрос к учебной базе данных, который вернёт процентное отношение общего размера всех индексов к общему размеру всех таблиц.

![alt text](https://github.com/SemikovaTV/hw_index/blob/main/1.jpg)

```sql
SELECT SUM(index_length)/SUM(data_length)*100 AS 'INDEX/DATA,%'
FROM INFORMATION_SCHEMA.TABLES
```

### Задание 2

Выполните explain analyze следующего запроса:
```sql
select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id
```
- перечислите узкие места;
- оптимизируйте запрос: внесите корректировки по использованию операторов, при необходимости добавьте индексы.

### Ответ
При выполнении запроса получаем:
```
EXPLAIN|-> Limit: 200 row(s)  (cost=0..0 rows=0) (actual time=6026..6026 rows=200 loops=1)¶
-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=6026..6026 rows=200 loops=1)¶
-> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=6026..6026 rows=391 loops=1)¶
-> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=2766..5815 rows=642000 loops=1)¶
-> Sort: c.customer_id, f.title  (actual time=2766..2830 rows=642000 loops=1)¶
-> Stream results  (cost=22e+6 rows=16.1e+6) (actual time=0.369..1918 rows=642000 loops=1)¶
-> Nested loop inner join  (cost=22e+6 rows=16.1e+6) (actual time=0.364..1578 rows=642000 loops=1)¶
-> Nested loop inner join  (cost=20.4e+6 rows=16.1e+6) (actual time=0.36..1390 rows=642000 loops=1)¶
-> Nested loop inner join  (cost=18.8e+6 rows=16.1e+6) (actual time=0.354..1202 rows=642000 loops=1)¶
-> Inner hash join (no condition)  (cost=1.61e+6 rows=16.1e+6) (actual time=0.342..70.6 rows=634000 loops=1)¶
-> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.68 rows=16086) (actual time=0.0325..6.12 rows=634 loops=1)¶
-> Table scan on p  (cost=1.68 rows=16086) (actual time=0.0223..4.17 rows=16044 loops=1)¶
-> Hash¶
-> Covering index scan on f using idx_title  (cost=111 rows=1000) (actual time=0.0322..0.225 rows=1000 loops=1)¶
-> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00116..0.00163 rows=1.01 loops=634000)¶
-> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=138e-6..162e-6 rows=1 loops=642000)
-> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=144e-6..167e-6 rows=1 loops=642000)'
```
Исключаем таблицу film
```sql
EXPLAIN ANALYZE
SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name), SUM(p.amount) OVER (PARTITION BY c.customer_id)
FROM payment p, rental r, customer c, inventory i
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id
```
```
'EXPLAIN|-> Limit: 200 row(s)  (cost=0..0 rows=0) (actual time=14.6..14.7 rows=200 loops=1)¶
-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=14.6..14.6 rows=200 loops=1)¶
-> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=14.6..14.6 rows=391 loops=1)¶
-> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id )   (actual time=13.6..14.5 rows=642 loops=1)¶
-> Sort: c.customer_id  (actual time=13.5..13.6 rows=642 loops=1)¶
-> Stream results  (cost=30098 rows=16102) (actual time=0.0666..13.4 rows=642 loops=1)¶
-> Nested loop inner join  (cost=30098 rows=16102) (actual time=0.062..13.1 rows=642 loops=1)
-> Nested loop inner join  (cost=24462 rows=16102) (actual time=0.0593..12.5 rows=642 loops=1)¶
-> Nested loop inner join  (cost=18826 rows=16102) (actual time=0.0543..11.9 rows=642 loops=1)¶
-> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1633 rows=16086) (actual time=0.0426..10.7 rows=634 loops=1)¶
-> Table scan on p  (cost=1633 rows=16086) (actual time=0.0331..9.39 rows=16044 loops=1)¶
-> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00126..0.00176 rows=1.01 loops=634)¶
-> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=737e-6..761e-6 rows=1 loops=642)¶
-> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=846e-6..869e-6 rows=1 loops=642)
```
Заменяем OVER (PARTITION BY..) на группировку GROUP BY:

```sql
EXPLAIN ANALYZE
SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name) AS fio, SUM(p.amount)
FROM payment p, rental r, customer c, inventory i
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id
GROUP BY fio
```
```
EXPLAIN|-> Limit: 200 row(s)  (actual time=25.3..25.4 rows=200 loops=1)¶
-> Table scan on <temporary>  (actual time=25.3..25.3 rows=200 loops=1)¶
-> Aggregate using temporary table  (actual time=25.3..25.3 rows=391 loops=1)¶
-> Nested loop inner join  (cost=30098 rows=16102) (actual time=0.0634..24.7 rows=642 loops=1)
-> Nested loop inner join  (cost=24462 rows=16102) (actual time=0.0612..24.1 rows=642 loops=1)¶
-> Nested loop inner join  (cost=18826 rows=16102) (actual time=0.0563..23.5 rows=642 loops=1)
-> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1633 rows=16086) (actual time=0.0446..21.8 rows=634 loops=1)
-> Table scan on p  (cost=1633 rows=16086) (actual time=0.0359..20.7 rows=16044 loops=1)
-> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1) (actual time=0.00204..0.00252 rows=1.01 loops=634)
-> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=698e-6..719e-6 rows=1 loops=642)¶
-> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=786e-6..807e-6 rows=1 loops=642)
```
Создаем индекс payment_date:
```sql
CREATE INDEX payment_date ON payment(payment_date)
```
Получаем итоговый вариант запроса:
```sql
EXPLAIN ANALYZE
SELECT CONCAT (c.last_name, ' ', c.first_name) AS fio, SUM(p.amount)
FROM payment p
inner join rental r on p.payment_date = r.rental_date
inner join customer c on r.customer_id = c.customer_id
inner join inventory i on i.inventory_id =r.inventory_id
WHERE p.payment_date >= '2005-07-30' AND p.payment_date < DATE_ADD('2005-07-30', INTERVAL 1 DAY )
GROUP BY fio
```
```
Limit: 200 row(s)  (actual time=6.24..6.27 rows=200 loops=1)¶
-> Table scan on <temporary>  (actual time=6.24..6.26 rows=200 loops=1)¶
-> Aggregate using temporary table  (actual time=6.23..6.23 rows=391 loops=1)¶
-> Nested loop in|

```
![alt text](https://github.com/SemikovaTV/hw_index/blob/main/3.jpg)


Скрипт - [ссылка](https://github.com/SemikovaTV/hw_index/blob/main/script.sql)


