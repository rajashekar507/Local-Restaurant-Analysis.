# Technical Notes

## Database & Tools
- PostgreSQL used for its analytical strengths.
- Data split into three tables: sales, menu, members.

## SQL Techniques
- Used CTEs and window functions for advanced analytics.
- Aggregations for spend and visit analysis.
- Subqueries for first/last order logic.
- CASE statements for custom points calculations.

## Challenges Overcome
- Date math for membership periods and promotions.
- Handling ties in rankings and nulls for non-members.
- Ensured queries answered real business questions, not just technical ones.

## Performance
- Indexed on customer_id and dates for faster queries.
- Queries validated for business sense and accuracy. 