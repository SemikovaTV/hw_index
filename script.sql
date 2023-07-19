SELECT SUM(index_length)/SUM(data_length)*100 AS 'INDEX/DATA,%'
FROM INFORMATION_SCHEMA.TABLES

EXPLAIN ANALYZE
SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name), SUM(p.amount) OVER (PARTITION BY c.customer_id, f.title)
FROM payment p, rental r, customer c, inventory i, film f
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id

EXPLAIN ANALYZE
SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name), SUM(p.amount) OVER (PARTITION BY c.customer_id)
FROM payment p, rental r, customer c, inventory i
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id

EXPLAIN FORMAT = TRADITIONAL
SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name) AS fio, SUM(p.amount)
FROM payment p, rental r, customer c, inventory i
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id
GROUP BY fio

CREATE INDEX payment_date ON payment(payment_date)

SELECT DISTINCT CONCAT (c.last_name, ' ', c.first_name) AS fio, SUM(p.amount)
FROM payment p, rental r, customer c, inventory i
WHERE DATE(p.payment_date) = '2005-07-30' AND p.payment_date =r.rental_date AND r.customer_id=c.customer_id AND i.inventory_id =r.inventory_id
GROUP BY fio

