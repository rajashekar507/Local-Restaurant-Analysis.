-- 03_analysis_queries.sql: All 10 analysis queries

-- 1. Total spent by each customer
SELECT 
    s.customer_id,
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_spent DESC;

-- 2. Unique visit count per customer
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;

-- 3. First order for each customer
WITH first_visits AS (
    SELECT customer_id, MIN(order_date) AS first_date
    FROM sales
    GROUP BY customer_id
)
SELECT s.customer_id, m.product_name AS first_order
FROM sales s
JOIN first_visits f ON s.customer_id = f.customer_id AND s.order_date = f.first_date
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id;

-- 4. Most popular menu item
SELECT m.product_name, COUNT(s.product_id) AS order_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY order_count DESC
LIMIT 1;

-- 5. Favorite dish per customer
WITH favorites AS (
    SELECT s.customer_id, m.product_name, COUNT(*) AS times_ordered,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS preference_rank
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name AS favorite_dish, times_ordered
FROM favorites
WHERE preference_rank = 1;

-- 6. First purchase after membership
WITH member_first_purchase AS (
    SELECT s.customer_id, s.order_date, m.product_name,
           ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS purchase_number
    FROM sales s
    JOIN members mb ON s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE s.order_date >= mb.join_date
)
SELECT customer_id, product_name AS first_member_purchase
FROM member_first_purchase
WHERE purchase_number = 1;

-- 7. Last order before membership
WITH before_joining AS (
    SELECT s.customer_id, s.order_date, m.product_name,
           ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS reverse_order
    FROM sales s
    JOIN members mb ON s.customer_id = mb.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE s.order_date < mb.join_date
)
SELECT customer_id, product_name AS last_pre_member_order
FROM before_joining
WHERE reverse_order = 1;

-- 8. Value before joining membership
SELECT s.customer_id, COUNT(*) AS items_before_joining, SUM(m.price) AS spent_before_joining
FROM sales s
JOIN members mb ON s.customer_id = mb.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

-- 9. Loyalty points calculation
SELECT s.customer_id,
    SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 20 ELSE m.price * 10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;

-- 10. New member bonus month points
WITH january_points AS (
    SELECT s.customer_id, s.order_date, mb.join_date, m.price, m.product_name,
        CASE
            WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + INTERVAL '6 days' THEN m.price * 20
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END AS points
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN members mb ON s.customer_id = mb.customer_id
    WHERE DATE_PART('month', s.order_date) = 1
)
SELECT customer_id, SUM(points) AS january_total
FROM january_points
WHERE customer_id IN ('A', 'B')
GROUP BY customer_id; 