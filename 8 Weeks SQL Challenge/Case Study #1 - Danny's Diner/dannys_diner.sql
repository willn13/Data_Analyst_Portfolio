
-- QUESTION 1

/*
What is the total amount each customer spent at the restaurant?
*/

SELECT s.customer_id,
       SUM(price) as total_spent
FROM menu AS m
JOIN sales AS s 
    ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- QUESTION 2
/*
How many days has each customer visited the restaurant?
*/
SELECT customer_id,
       COUNT(DISTINCT order_date) AS _days_visited
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- QUESTION 3
/*
What was the first item from the menu purchased by each customer?
*/
WITH new_table AS(
    SELECT customer_id,
           product_name,
           order_date,
           DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank
    FROM sales as s
    JOIN menu AS m
        ON s.product_id = m.product_id
)
SELECT customer_id, 
       product_name,
       order_date
FROM new_table
WHERE rank = 1
GROUP BY customer_id,product_name,order_date;

-- QUESTION 4

/*
What is the most purchased item on the menu and how many times was it purchased by all customers?
*/

SELECT product_name,
       COUNT(s.product_id)
FROM menu as m
JOIN sales as s
    ON m.product_id = s.product_id
GROUP BY product_name
LIMIT 1;

-- QUESTION 5

/*
Which item was the most popular for each customer?
*/

WITH new_table AS(
    SELECT customer_id,
           product_name,
           COUNT(s.product_id) AS total_times_ordered,
           DENSE_RANK() OVER(PARTITION BY customer_id 
                ORDER BY COUNT(s.product_id) DESC) AS rank
    FROM sales as s
    JOIN menu AS m
        ON s.product_id = m.product_id
GROUP BY 1, 2
)
SELECT customer_id, 
        product_name, 
        total_times_ordered
FROM new_table
WHERE rank = 1
GROUP BY customer_id,procut_name,total_times_ordered;

-- QUESTION 6

/*
Which item was purchased first by the customer after they became a member?
*/

WITH new_table AS (
    SELECT s.customer_id,
          product_name,
          join_date,
          order_date,
          DENSE_RANK() OVER(PARTITION BY s.customer_id 
            ORDER BY MIN(order_date - join_date)) AS rank
    FROM sales as s
    JOIN menu as m
        ON  s.product_id = m.product_id
    JOIN members as mem
        ON s.customer_id = mem.customer_id
        WHERE join_date <= order_date
GROUP BY 1, 2, 3, 4
)
SELECT customer_id, 
       product_name, 
        join_date, 
        order_date
FROM new_table
WHERE rank = 1
GROUP BY customer_id, product_name,join_date, order_date;

-- Question 7

/*
Which item was purchased just before the customer became a member?
*/

WITH new_table AS (
    SELECT s.customer_id,
          product_name,
          join_date,
          order_date,
          DENSE_RANK() OVER(PARTITION BY s.customer_id 
            ORDER BY MAX(join_date - order_date)) AS rank
    FROM sales as s
    JOIN menu as m
        ON  s.product_id = m.product_id
    JOIN members as mem
        ON s.customer_id = mem.customer_id
        WHERE order_date < join_date
GROUP BY 1, 2, 3, 4
)
SELECT customer_id, 
        product_name, 
        join_date, 
        order_date
FROM new_table
WHERE rank = 1
GROUP BY customer_id, product_name, join_date, order_Date;

-- Question 8

/*
What is the total items and amount spent for each member before they became a member?
*/

WITH new_table AS(
    SELECT s.customer_id,
            join_date,
            order_date,
            m.product_id,
            price
    FROM sales as s
    JOIN menu as m
        ON s.product_id = m.product_id
    JOIN members as mem 
        ON s.customer_id = mem.customer_id
    WHERE order_date < join_date
    GROUP BY 1,2,3,4,5
)
SELECT customer_id,
        COUNT(order_date) AS total_items,
        SUM(price) AS amount_spent
FROM new_table
WHERE order_date < join_date
GROUP BY customer_id;

-- Question 9

/*
If each $1 spent equates to 10 points and sushi has a 
2x points multiplier - how many points would 
each customer have?
*/

WITH new_table AS(
    SELECT  customer_id,
            price,
            CASE product_name
                WHEN 'sushi' THEN price * 20
                ELSE price * 10
                END AS points
    FROM sales as s
    JOIN menu as m
        ON s.product_id = m.product_id
)
SELECT  customer_id,
        SUM(points) AS total_points
FROM new_table
GROUP BY customer_id
ORDER BY total_points DESC;

-- Question 10

/*
In the first week after a customer 
joins the program (including their 
join date) they earn 2x points 
on all items, not just sushi - 
how many points do customer 
A and B have at the end of January?
*/

WITH new_table AS(
    SELECT  s.customer_id,
            price,
            order_date,
            CASE 
                WHEN product_name = 'sushi'  OR
                order_date BETWEEN join_date AND join_date + 6 THEN price * 20
                ELSE price * 10
                END AS points
    FROM sales as s
    JOIN menu as m
        ON s.product_id = m.product_id
    JOIN members as mem
        ON s.customer_id = mem.customer_id
)
SELECT  customer_id,
        SUM(points) AS total_points
FROM new_table
WHERE order_date < '2021-02-01'
GROUP BY customer_id
ORDER BY total_points DESC;

-- BONUS QUESTION 1

SELECT s.customer_id,
       order_date,
       s.product_id,
       product_name,
       price,
       CASE WHEN (order_date >= join_date)  THEN 'Y' else 'N' END AS member
FROM sales AS s
JOIN menu AS m
    ON s.product_id = m.product_id
JOIN members AS mem
    ON s.customer_id = mem.customer_id
ORDER BY customer_id, order_date;

-- BONUS QUESTION 2

WITH new_table AS(
    SELECT s.customer_id,
       order_date,
       s.product_id,
       product_name,
       price,
       CASE WHEN (order_date >= join_date)  THEN 'Y' else 'N' END AS member
    FROM sales AS s
    JOIN menu AS m
        ON s.product_id = m.product_id
    JOIN members as mem
        ON s.customer_id = mem.customer_id
    ORDER BY customer_id, order_date
)
SELECT *,
    CASE WHEN member = 'Y' THEN rank() OVER (PARTITION BY customer_id, member ORDER BY order_date) ELSE NULL END AS ranking
FROM new_table;