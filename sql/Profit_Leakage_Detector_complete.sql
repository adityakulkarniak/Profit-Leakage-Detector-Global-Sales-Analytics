use profitleakage;
select * from customer_segments;
select * from profit_data;
select * from sales_data;

## step 1) Total revenue:
SELECT 
    SUM(revenue) AS total_revenue
FROM
    sales_data;

##  1.1) Revenue by Region:
SELECT 
    region, ROUND(SUM(revenue), 2) AS region_revenue
FROM
    sales_data
GROUP BY region;

## step 2) -- Step 2.1: Join sales_data with customer_segments to bring customer_name, industry, and revenue_contribution into sales records
SELECT 
    s.sale_id,
    s.sale_date,
    s.region,
    s.product,
    s.customer_id,
    c.customer_name,
    c.industry,
    c.revenue_contribution,
    s.units_sold,
    s.revenue
FROM
    sales_data s
        JOIN
    customer_segments c ON s.customer_id = c.customer_id
LIMIT 10;

## step 2.2) Step 2.2: Join sales_data with profit_data to add profit_margin for each sale, based on product and region
SELECT 
    s.sale_id,
    s.sale_date,
    s.region,
    s.product,
    s.customer_id,
    s.units_sold,
    s.revenue,
    p.profit_margin
FROM
    sales_data s
        JOIN
    profit_data p ON s.product = p.product
        AND s.region = p.region
LIMIT 10;

## Step 2.3: Triple join of sales_data, customer_segments, and profit_data to create a full view with customer, sales, and profitability information
SELECT 
    s.sale_id,
    s.sale_date,
    s.region,
    s.product,
    s.customer_id,
    c.customer_name,
    c.industry,
    c.revenue_contribution,
    s.units_sold,
    s.revenue,
    p.profit_margin
FROM
    sales_data s
        JOIN
    customer_segments c ON s.customer_id = c.customer_id
        JOIN
    profit_data p ON s.product = p.product
        AND s.region = p.region
LIMIT 10;
    
## step 2.4) group total revenue by customer identity to identify major revenue-contributing industries 
    
SELECT 
    c.industry, SUM(s.revenue) AS total_revenue
FROM
    sales_data s
        JOIN
    customer_segments c ON s.customer_id = c.customer_id
GROUP BY c.industry;
    
## Step 3.1): Group revenue by region and product to see which products perform well in which regions
   SELECT 
    region, product, ROUND(SUM(revenue), 2) AS total_revenue
FROM
    sales_data
GROUP BY region , product
ORDER BY total_revenue DESC;

SELECT 
    s.customer_id,
    c.customer_name,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM
    sales_data s
        JOIN
    customer_segments c ON s.customer_id = c.customer_id
GROUP BY s.customer_id , c.customer_name
ORDER BY total_revenue DESC
LIMIT 5;

SELECT 
    p.region, p.product, p.revenue, p.cost, p.profit_margin
FROM
    profit_data p
WHERE
    p.profit_margin < 15
ORDER BY p.revenue DESC;

-- Step 3.4): Join sales and profit data to analyze average revenue per product-region with profit margins
SELECT 
    s.region,
    p.product,
    p.profit_margin,
    ROUND(AVG(s.revenue), 2) AS avg_revenue
FROM
    sales_data s
        JOIN
    profit_data p ON s.product = p.product
        AND s.region = p.region
GROUP BY s.region , p.product , p.profit_margin
ORDER BY avg_revenue DESC;

-## Step 4.1): The region with the highest total revenue
SELECT 
    region, ROUND(SUM(revenue), 2) AS total_revenue
FROM
    sales_data
GROUP BY region
HAVING SUM(revenue) = (SELECT 
        MAX(region_total)
    FROM
        (SELECT 
            region, SUM(revenue) AS region_total
        FROM
            sales_data
        GROUP BY region) AS sub);

-- Step 4.2): customers whose revenue_contribution is higher than average
select 
	customer_id,
    customer_name,
    revenue_contribution
    FROM 
    customer_segments
WHERE 
    revenue_contribution > (
        SELECT AVG(revenue_contribution)
        FROM customer_segments
    )
ORDER BY 
    revenue_contribution DESC;
    
## Step 4.3): Products with profit margins below the overall average (profit risk areas)
select
	product,
    region,
    profit_margin
from
	profit_data
where 
	profit_margin < (
select 
	avg(profit_margin)
    from profit_data
    )
order by profit_margin desc;

-- Step 5.1): regions earning more than average total revenue using nested subquery

SELECT 
    region, SUM(revenue) AS total_revenue
FROM
    sales_data
GROUP BY region
HAVING SUM(revenue) > (SELECT 
        AVG(region_total)
    FROM
        (SELECT 
            region, SUM(revenue) AS region_total
        FROM
            sales_data
        GROUP BY region) AS sub);

-- Step 6.1: Adding profit risk flags based on profit margin thresholds
SELECT 
    product,
    region,
    revenue,
    cost,
    profit_margin,
    CASE 
        WHEN profit_margin < 10 THEN 'High Risk'
        WHEN profit_margin BETWEEN 10 AND 20 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_flag
FROM 
    profit_data
ORDER BY 
    risk_flag;

-- Step 7.1: Rank products by revenue within regions using RANK()

SELECT 
    region,
    product,
    SUM(revenue) AS total_revenue,
    RANK() OVER (PARTITION BY region ORDER BY SUM(revenue) DESC) AS revenue_rank
FROM 
    sales_data
GROUP BY 
    region, product;

-- Step 8.1: Identify products with high revenue but profit margins below 20%
SELECT 
    s.product,
    s.region,
    SUM(s.revenue) AS total_revenue,
    p.profit_margin
FROM
    sales_data s
        JOIN
    profit_data p ON s.product = p.product
        AND s.region = p.region
GROUP BY s.product , s.region , p.profit_margin
HAVING SUM(s.revenue) > 50000
    AND p.profit_margin < 20
ORDER BY total_revenue DESC;

-- Step 9.1: Find top 5 customers linked to low-margin product sales (profit leak contributors)
SELECT 
    s.customer_id,
    c.customer_name,
    SUM(s.revenue) AS total_revenue,
    AVG(p.profit_margin) AS avg_profit_margin
FROM
    sales_data s
        JOIN
    customer_segments c ON s.customer_id = c.customer_id
        JOIN
    profit_data p ON s.product = p.product
        AND s.region = p.region
WHERE
    p.profit_margin < 15
GROUP BY s.customer_id , c.customer_name
ORDER BY total_revenue DESC
LIMIT 5;
