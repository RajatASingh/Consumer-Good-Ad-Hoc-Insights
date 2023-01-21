# Request 1:

SELECT 
    DISTINCT market
    FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

# Request 2:

WITH unique_product_2020 
AS(SELECT 
         Count(distinct product_code) AS unique_product_2020
         FROM fact_sales_monthly 
         WHERE fiscal_year = 2020),
unique_product_2021
         AS (SELECT 
                  Count(distinct product_code) AS unique_product_2021
                  FROM fact_sales_monthly 
                  WHERE fiscal_year = 2021)
SELECT  
     unique_product_2020,
     unique_product_2021,
     ROUND(100 * (unique_product_2021 - unique_product_2020) / unique_product_2020,2) AS percentage_chg
FROM unique_product_2020, unique_product_2021;

# Request 3:

SELECT   
     COUNT(DISTINCT product_code) as product_count,
     segment
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

# Request 4:

WITH product_2020 AS
         (SELECT COUNT(DISTINCT f.product_code) AS product_count_2020,
               d.segment
               FROM dim_product d
		  INNER JOIN fact_sales_monthly f
          ON d.product_code = f.product_code
          WHERE fiscal_year = 2020
          GROUP BY d.segment) ,
product_2021 AS
         (SELECT COUNT(DISTINCT f.product_code) AS product_count_2021,
                 d.segment
                 FROM dim_product d
                 INNER JOIN fact_sales_monthly f
                 ON d.product_code = f.product_code
                 WHERE fiscal_year = 2021
                 GROUP BY d.segment)
select 
       product_2021.segment, 
       product_count_2020,
       product_count_2021,
       (product_count_2021 - product_count_2020) AS difference
     FROM product_2020 
     RIGHT JOIN product_2021
     ON product_2021.segment = product_2020.segment
     ORDER BY product_2020.segment, product_2021.segment;

# Request 5:

SELECT 
     d.product_code,
     d.product,
     f.manufacturing_cost
FROM dim_product d
INNER JOIN fact_manufacturing_cost f
ON d.product_code = f.product_code
	WHERE f.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
    OR f.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost);

# Request 6:

WITH avg_discount AS 
           (SELECT 
                  d.customer_code,
                  d.customer,
                  f.pre_invoice_discount_pct
                  FROM dim_customer d
			  INNER JOIN fact_pre_invoice_deductions f
              ON d.customer_code = f.customer_code
              WHERE market = 'India' AND fiscal_year = 2021)
SELECT  
      customer_code, 
      customer,
      ROUND(AVG(pre_invoice_discount_pct),3) AS average_discount_percentage
  FROM avg_discount
  GROUP BY customer
  ORDER BY average_discount_percentage DESC
  LIMIT 5;

# Request 7:

WITH gross_sales AS
          (SELECT 
               d.customer,
               MONTHNAME(fs.date) as 'Month',
               YEAR(fs.date) As 'Year',
               (fs.sold_quantity * fp.gross_price) as gross_sales_amount
			 FROM gdb023.fact_sales_monthly fs
             INNER JOIN fact_gross_price fp
             ON fs.product_code = fp.product_code
             INNER JOIN dim_customer d 
             ON fs.customer_code = d.customer_code
                WHERE d.customer = 'Atliq Exclusive')
SELECT 
     Year,
     Month,
     ROUND(SUM(gross_sales_amount),2) AS Gross_sales_Amount
  FROM gross_sales
  GROUP BY Month, year;

# Request 8:

WITH quarter_sales AS
(SELECT 
      Month(date) as 'Month',
      SUM(sold_quantity)  as total_sold_quantity
 FROM fact_sales_monthly
 WHERE fiscal_year = 2020
 GROUP BY Month)
 SELECT 
        Month,
	CASE
         WHEN Month BETWEEN 9 AND 11 THEN 'Q1'
         WHEN Month BETWEEN 3 AND 5 THEN 'Q3'
         WHEN Month BETWEEN 6 AND 8 THEN 'Q4'
	ELSE 'Q2'
END AS 'Quarter', 
ROUND(SUM(total_sold_quantity)  / 1000000,2) AS Total_Quantity_In_Million
FROM quarter_sales
GROUP BY Quarter;

# Request 9:

WITH channel_contribution
        AS (SELECT
               d.channel,
               ROUND(SUM(fs.sold_quantity * fp.gross_price),2) AS gross_sales   
               FROM dim_customer d
			 INNER JOIN fact_sales_monthly fs
             ON d.customer_code = fs.customer_code
             INNER JOIN fact_gross_price fp
             ON fs.product_code = fp.product_code
               WHERE fs.fiscal_year = 2021
               GROUP BY d.channel)
SELECT 
	 cc.* ,
     (gross_sales * 100 / p.s) AS percentage
     FROM channel_contribution CC
  CROSS JOIN (SELECT SUM(gross_sales) AS s FROM channel_contribution) p
  ORDER BY percentage DESC;

# Request 10:

WITH 
division_total_quantity
          AS (SELECT 
                  d.division, 
                  SUM(fs.sold_quantity) total_quantity,
                  d.product
                  FROM dim_product d
			   INNER JOIN fact_sales_monthly fs
               ON d.product_code = fs.product_code
                  WHERE fs.fiscal_year = 2021
                  GROUP BY d.division , d.product_code), 
result 
	AS (SELECT  
            division,
            product,
            total_quantity,
            DENSE_RANK() OVER(PARTITION BY division ORDER BY total_quantity DESC ) as rank_order
            FROM division_total_quantity)
SELECT 
     division,
     product,
     total_quantity,
     rank_order
     FROM result
	 WHERE rank_order BETWEEN 1 AND 3;
