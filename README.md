# Restaurant Customer Analytics: SQL Case Study & Business Insights

> Unlock actionable business insights from restaurant sales and membership data using advanced SQL analytics. This project presents a real-world case study of a Japanese restaurant, focusing on customer behavior, spending patterns, and the impact of loyalty programs. Through a series of well-structured SQL queries and business analysis, the repository demonstrates how data-driven decisions can improve customer engagement, optimize menu offerings, and drive business growth.

---

## My Journey with This Project

When I first encountered this dataset about a Japanese restaurant, I was intrigued by the real-world business questions it posed. As someone passionate about uncovering stories within data, I dove deep into analyzing customer behaviors, spending patterns, and the impact of loyalty programs.

## The Challenge

A small restaurant owner named Danny opened a cute little place selling his 3 favorite foods: sushi, curry, and ramen. He collected basic data about his customers but needed help understanding:
- Who his best customers were
- What they liked to order
- Whether his new membership program was working

This resonated with me because every small business faces these same questions. Could I help Danny make better decisions using just SQL?

## Setting Up the Database

I chose PostgreSQL for this analysis because of its robust analytical capabilities. Here's how I structured Danny's data:

**First, I created the database:**
```sql
-- Starting fresh with a new database
CREATE DATABASE danny_diner;
```

**Then built three interconnected tables:**

The sales records - every single transaction:
```sql
CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);
```

The menu - simple but essential:
```sql
CREATE TABLE menu (
    product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);
```

The membership tracker:
```sql
CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date DATE
);
```

## Loading Danny's Data

I carefully inserted the data, making sure every transaction was accounted for:

```sql
-- Sales data shows interesting patterns right away
INSERT INTO sales VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

-- Menu is straightforward
INSERT INTO menu VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

-- Only two members so far
INSERT INTO members VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
```

## Uncovering Customer Stories Through SQL

### Story 1: Following the Money

My first question was simple - who's spending what? This query revealed something interesting:

```sql
-- Let's see who our MVPs are
SELECT 
    s.customer_id,
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_spent DESC;
```

**What I discovered:** Customer A spent $76, B spent $74, and C spent $36. But here's the kicker - C isn't even a member yet! That's a missed opportunity.

### Story 2: Understanding Visit Patterns

How often do customers actually show up? This matters for staffing and fresh ingredient ordering:

```sql
-- Counting unique visit days tells us about customer habits
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;
```

**The insight:** Customer A and B visited 4 times each, while C came 2 times. The members definitely visit more frequently.

### Story 3: First Impressions Matter

What brings people in the door initially? I had to dig deeper for this one:

```sql
-- Using a subquery to find each customer's first order
WITH first_visits AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_date
    FROM sales
    GROUP BY customer_id
)
SELECT 
    s.customer_id,
    m.product_name AS first_order
FROM sales s
JOIN first_visits f
    ON s.customer_id = f.customer_id 
    AND s.order_date = f.first_date
JOIN menu m
    ON s.product_id = m.product_id
ORDER BY s.customer_id;
```

**Finding:** There's variety in first orders - curry and sushi for A, curry for B, and ramen for C. No single "gateway" dish.

### Story 4: The Crowd Favorite

What's flying off the shelves? This helps with inventory:

```sql
-- Simple but powerful - what sells most?
SELECT 
    m.product_name,
    COUNT(s.product_id) AS order_count
FROM sales s
JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY order_count DESC
LIMIT 1;
```

**Result:** Ramen wins with 8 orders! Despite being mid-priced, it's the clear favorite.

### Story 5: Personal Preferences

Everyone has their go-to order. Finding these patterns helps with personalization:

```sql
-- Window functions make this elegant
WITH favorites AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS times_ordered,
        RANK() OVER (
            PARTITION BY s.customer_id 
            ORDER BY COUNT(*) DESC
        ) AS preference_rank
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id,
    product_name AS favorite_dish,
    times_ordered
FROM favorites
WHERE preference_rank = 1;
```

**Insights:** A loves ramen (3 orders), B is torn between all three (2 each), and C is all about ramen (3 orders).

### Story 6: The Membership Effect

Does joining actually change behavior? Let's find out:

```sql
-- What happens after someone joins?
WITH member_first_purchase AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.order_date
        ) AS purchase_number
    FROM sales s
    JOIN members mb 
        ON s.customer_id = mb.customer_id
    JOIN menu m 
        ON s.product_id = m.product_id
    WHERE s.order_date >= mb.join_date
)
SELECT 
    customer_id,
    product_name AS first_member_purchase
FROM member_first_purchase
WHERE purchase_number = 1;
```

**Discovery:** Customer A went for curry, B chose sushi. Interesting that they tried something different!

### Story 7: Pre-Membership Behavior

What were they buying before joining? This might show what converts them:

```sql
-- Looking backward from join date
WITH before_joining AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.order_date DESC
        ) AS reverse_order
    FROM sales s
    JOIN members mb 
        ON s.customer_id = mb.customer_id
    JOIN menu m 
        ON s.product_id = m.product_id
    WHERE s.order_date < mb.join_date
)
SELECT 
    customer_id,
    product_name AS last_pre_member_order
FROM before_joining
WHERE reverse_order = 1;
```

**Pattern spotted:** Both A and B had sushi right before joining. Maybe sushi lovers are more likely to commit?

### Story 8: Pre-Membership Value

How much were they worth before becoming members?

```sql
-- Calculating the "courtship" period value
SELECT 
    s.customer_id,
    COUNT(*) AS items_before_joining,
    SUM(m.price) AS spent_before_joining
FROM sales s
JOIN members mb 
    ON s.customer_id = mb.customer_id
JOIN menu m 
    ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;
```

**Key finding:** A bought 2 items for $25, B bought 3 items for $40. They were already good customers before joining.

### Story 9: Basic Points System

If we gave 10 points per dollar, with sushi earning double:

```sql
-- Calculating hypothetical loyalty points
SELECT 
    s.customer_id,
    SUM(
        CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
JOIN menu m 
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;
```

**Points leaderboard:** A: 860, B: 940, C: 360. Customer B would be winning!

### Story 10: New Member Bonus Month

What if new members got double points on everything their first week?

```sql
-- Complex calculation for promotional period
WITH january_points AS (
    SELECT 
        s.customer_id,
        s.order_date,
        mb.join_date,
        m.price,
        m.product_name,
        CASE
            -- First week bonus
            WHEN s.order_date BETWEEN mb.join_date 
                AND mb.join_date + INTERVAL '6 days' 
            THEN m.price * 20
            -- Sushi always gets double
            WHEN m.product_name = 'sushi' 
            THEN m.price * 20
            -- Everything else
            ELSE m.price * 10
        END AS points
    FROM sales s
    JOIN menu m 
        ON s.product_id = m.product_id
    JOIN members mb 
        ON s.customer_id = mb.customer_id
    WHERE DATE_PART('month', s.order_date) = 1
)
SELECT 
    customer_id,
    SUM(points) AS january_total
FROM january_points
WHERE customer_id IN ('A', 'B')
GROUP BY customer_id;
```

**January results:** A earned 1,370 points, B earned 820. The promotion clearly drove A's behavior!

## What This Taught Me

Working through this dataset reinforced several key lessons:

1. **Simple questions often have complex answers** - Even "who spends the most" led to insights about membership conversion opportunities

2. **Window functions are incredibly powerful** - They made finding "first" and "favorite" items so much cleaner than subqueries

3. **Business context matters** - Every query should answer a real business question, not just display technical skills

4. **Data tells stories** - Customer C's behavior screams "convert me to a member!" while the pre-membership sushi pattern suggests a marketing opportunity

## Real-World Applications

This analysis translates directly to any business with:
- Customer loyalty programs
- Multiple product offerings  
- Membership or subscription models
- Need for personalization

The techniques I used here would work for:
- Coffee shop loyalty cards
- Gym membership analysis
- SaaS subscription patterns
- Retail customer segmentation

## My Approach to Problem-Solving

1. **Start simple** - Basic aggregations first
2. **Build complexity gradually** - Add CTEs and window functions as needed
3. **Always validate** - Check results make business sense
4. **Think about the "why"** - Not just what the data shows, but what it means

## Technical Challenges I Overcame

- **Date math** - Calculating "first week after joining" required careful interval handling
- **Ties in rankings** - Had to decide how to handle customers with equal preferences
- **Null handling** - Customer C's non-membership required careful LEFT JOIN consideration
- **Performance** - Indexed on customer_id and dates for faster queries

## Next Steps for Danny

Based on my analysis, I'd recommend:

1. **Immediately reach out to Customer C** with a membership offer
2. **Create a "Ramen Monday" promotion** since it's the favorite
3. **Track the sushi-to-membership pipeline** more closely
4. **Consider a referral bonus** - current members are engaged and might bring friends

## Conclusion

This project reminded me why I love data analysis. Behind every query is a real business decision, a real customer, and a real opportunity to make things better. Danny's tiny restaurant dataset taught me more about customer behavior than many larger, more complex projects.

The combination of SQL mastery and business thinking is what turns data into decisions. That's what I bring to every analysis - not just the technical skills to write complex queries, but the curiosity to ask the right questions and the communication skills to share what I find.

Feel free to explore the code, run the queries yourself, and let me know what other insights you discover. Data analysis is always better as a conversation than a monologue.
