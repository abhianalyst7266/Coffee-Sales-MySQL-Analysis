CREATE DATABASE coffee;
USE coffee;

CREATE TABLE city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(50),
    population INT,
    estimated_rent INT,
    city_rank INT
);
select * from city;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    city_id INT
);
select * from customers ;
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price INT
);
select * from products ;
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date VARCHAR(20),
    product_id INT,
    customer_id INT,
    total INT,
    rating INT
);
select * from sales ;

SELECT 'city' AS tbl, COUNT(*) AS rows_count FROM city
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales', COUNT(*) FROM sales;


-- QUESTION

-- 1. Coffee Consumers Count
-- Question: How many people in each city are estimated to consume coffee, given that 25% of the population does?

select
	city_name,
	population,
	round(population * 0.25, 0) as estimated_coffee_consumption
from city
order by estimated_coffee_consumption desc;


-- 2. Total Revenue from Coffee Sales
-- Question: What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
c.city_name,
SUM(s.total) AS total_revenue
FROM sales s
JOIN customers cu
ON s.customer_id = cu.customer_id
JOIN city c
ON cu.city_id = c.city_id
WHERE s.sale_date >= '2023-10-01'
AND s.sale_date < '2024-01-01'
GROUP BY c.city_name
ORDER BY total_revenue DESC;

SELECT city_name, sum(s.total) AS total_revenue;


-- 3. Sales Count for Each Product
-- Question: How many units of each coffee product have been sold?   
select s.product_id, p.product_name, count(p.product_name) as total_quantity
from sales s
join products p
on s.product_id = p.product_id
group by 
    p.product_name,
    s.product_id
order by s.product_id asc;


-- 4. Average Sales Amount per City
-- Question: What is the average sales amount per customer in each city?
select c.city_name, cu.customer_id, cu.customer_name,
    AVG(s.total) AS avg_sales_per_customer
from city c
join customers cu on c.city_id = cu.city_id
join sales s on cu.customer_id = s.customer_id
group by cu.customer_name, c.city_name, cu.customer_id
order by cu.customer_id asc;


-- 5. City Population and Coffee Consumers
-- Question: Provide a list of cities along with their populations and estimated coffee consumers.
select
    city_name,
    population,
    ROUND(population * 0.25, 2) as estimated_coffee_consumer
from city
order by estimated_coffee_consumer asc;


-- 6. Top Selling Products by City
-- Question: What are the top 3 selling products in each city based on sales volume?
with ranked_products AS
(
    SELECT
        c.city_name,
        p.product_name,
        COUNT(*) AS sales_volume,
        ROW_NUMBER() OVER
        ( PARTITION BY c.city_name ORDER BY COUNT(*) DESC ) AS rn
    FROM sales s
    JOIN customers cu ON s.customer_id = cu.customer_id
    JOIN city c ON cu.city_id = c.city_id
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY c.city_name, p.product_name
)
SELECT
    city_name,
    product_name,
    sales_volume
FROM ranked_products
WHERE rn <= 3
ORDER BY
    city_name, rn;
    
    
-- 7. Customer Segmentation by City
-- Question: How many unique customers are there in each city who have purchased coffee products?
with uniquecustomer as (
select
    c.city_name,
    count(distinct cu.customer_name) as unique_customer
from city c
join customers cu
on c.city_id = cu.city_id
group by
    c.city_name
)
select
    city_name,
    unique_customer
from uniquecustomer
order by
    unique_customer desc;
    
    
    
    -- 8. Average Sale vs Rent
-- Question: Find each city and their average sale per customer and avg rate per customer
with averages as (
select
    c.city_name,
    cu.customer_name,
    round(sum(s.total)/count(distinct cu.customer_name), 2) as avg_sales_per_customer,
    round(avg(s.rating), 0) as avg_rating
from city c
join customers cu on c.city_id = cu.city_id
join sales s on cu.customer_id = s.customer_id
group by c.city_name, cu.customer_name
)
select city_name, customer_name, avg_sales_per_customer, avg_rating
from averages order by avg_sales_per_customer desc;



-- 9. Monthly Sales Growth
-- Question: Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with monthlysales as (
select year(s.sale_date) as sale_year, MONTH(s.sale_date) as sale_month, sum(s.total) as monthly_sales
from sales s
group by year(s.sale_date),month(s.sale_date)),
sales_growth as(select sale_year, sale_month, monthly_sales, lag(monthly_sales) over ( order by sale_year, sale_month ) as previous_month_sales from monthlysales
    )
        select sale_year,sale_month,monthly_sales,previous_month_sales,
            round((monthly_sales - previous_month_sales) * 100 / previous_month_sales, 2) as growth_percentage
        from sales_growth
        order by sale_year,sale_month; with monthlysales as (
select year(s.sale_date) as sale_year, MONTH(s.sale_date) as sale_month, sum(s.total) as monthly_sales
from sales s group by year(s.sale_date), month(s.sale_date)),
sales_growth as(select sale_year, sale_month, monthly_sales, lag(monthly_sales) over ( order by sale_year, sale_month ) as previous_month_sales from monthlysales)
select sale_year,sale_month,monthly_sales,previous_month_sales,
            round((monthly_sales - previous_month_sales) * 100 / previous_month_sales, 2) as growth_percentage
from sales_growth order by sale_year, sale_month;




-- 10. Market Potential Analysis
-- Question: Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.
SELECT
    c.city_name,
    sum(s.total) as total_sales,
    sum(s.rating) as total_rating,
    count(distinct cu.customer_name) as total_customer,
    ROUND(c.population * 0.25, 2) as estimated_coffee_consumer
from city c
join customers cu
on c.city_id = cu.city_id
join sales s
on cu.customer_id = s.customer_id
group by
    c.city_name,
    c.population
order by
    total_sales desc
LIMIT 3;