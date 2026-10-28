select * from ecommerce_sales;

-- count the dataset:3392 dataset
select count(*)
from ecommerce_sales;

-- Step1:understading the dataset
-- we always perform cleaning in duplicate dataset
create table sales_staging1
like ecommerce_sales;

-- inserting value into staging table
insert into sales_staging1
select * 
from ecommerce_sales;

select * from sales_staging1;
select count(*)
from sales_staging1;

-- checking the datatype
describe sales_staging1;

-- as we founf inconsistency in catagory lets inspect further
select distinct category
from sales_staging1
order by category;

-- counting each category
select category,count(*) as total_records
from sales_staging1
group by category
order by total_records desc;

-- checking for the hidden space
select category,length(category) as length,
trim(category) as trimmed_category
from sales_staging1
where category like "%Fashion%";

-- check for duplicate records
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging1;

-- counting how many duplicates value are there using subquery
select count(*) as duplicate_records
from(
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging1) as duplicates
where rn>1;

-- viewing the duplicate records
select *
from(
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging1) as duplicates
where rn>1;

-- deleting the duplicate data
with duplicate_cte as (
select *,
row_number() over(
partition by `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging1
)
delete from duplicate_cte
where rn > 1;

-- checking for the null values
SELECT
    SUM(CASE WHEN `Order ID` IS NULL THEN 1 ELSE 0 END) 
    AS OrderID_Null,
    SUM(CASE WHEN `Customer ID` IS NULL THEN 1 ELSE 0 END)
    AS CustomerID_Null,
    SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) 
    AS Product_Null,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END)
    AS Category_Null,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) 
    AS Price_Null,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) 
    AS Quantity_Null,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END)
    AS Discount_Null,
    SUM(CASE WHEN `Order Date` IS NULL THEN 1 ELSE 0 END)
    AS OrderDate_Null,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) 
    AS Region_Null,
    SUM(CASE WHEN `Payment Method` IS NULL THEN 1 ELSE 0 END)
    AS PaymentMethod_Null,
    SUM(CASE WHEN `Delivery Time` IS NULL THEN 1 ELSE 0 END)
    AS DeliveryTime_Null
FROM sales_staging1;

select *
from sales_staging1
where price is null;

-- step2:cleaning the data
-- remove extra spaces
update sales_staging1
set category= Trim(Category);

-- verifing the category if whitw space is removed or not
select category,count(*) as total_records
from sales_staging1
group by Category
order by total_records Desc ;

-- Standardize Category Names
update sales_staging1
set category =
case
when lower(Category) in("fashion","fashions") THEN "Fashion"
when lower(category) in("beauty","beuty","Beauty & Personal Care") then "Beauty"
when lower(category) in ("book","books") then "Books"
when lower(category) in ("electronic","electronics","electroncs") then "Electronics"
when lower(category) in ("grocery","groceries") then "Grocery"
when lower(category) in ("sports","sport","sports & outdoors") then "Sports"
when lower(category) in ("toys","toys & Games","toy") then "Toys"
when lower(category) in ("home & kitchen","home kitchen","home and kitchen","home&kitchen") then "Home & kitchen"
else Category
END;

-- verifying it
select distinct(category)
from sales_staging1;

select category,count(*) as total_records
from sales_staging1
group by category
order by category;

-- moving to region and payment method
select distinct region
from sales_staging1
order by region;

select distinct `payment Method`
from sales_staging1
order by `Payment Method`;

-- How many records were affected
select `payment method`,count(*) as total_records
from sales_staging1
group by  `Payment Method`
order by total_records;

-- standarizing the payment method names
update sales_staging1
set `payment method`=
case
when lower(trim(`payment method`)) in ("cash on Delivery","cod")
then "Cash on Delivery"
when lower(trim(`payment method`)) in ("e-sewa","esewa","eSewa")
then "eSewa"
when lower(trim(`payment method`)) in ("wallet","mobile wallet")
then "Mobile Wallet"
when lower(trim(`payment method`)) in ("credit-card","credit card ","credit cared")
then "Credit Card"
when lower(trim(`payment method`)) in ("debit card") 
then "Debit Card"
when lower(trim(`payment method`)) = "upi"
then "UPI"
else `payment method`
end;

-- verifying it
select `payment method`,count(*) as total_records
from sales_staging1
group by `payment method`
order by `Payment Method`;

-- converting the data type as order date is in text form
select distinct `order date`
from sales_staging1
limit 20;

-- filtering the date thet is in format dd-mm-yyyy
select `order date`
from sales_staging1
where `Order Date` like "__-__-____"
limit 10; 

-- converting those rows in yyyy-mm-dd
update sales_staging1
set `order date`= date_format(
str_to_date(`order date`,"%d-%m-%Y"),"%Y-%m-%d"
)
where `order date` like "__-__-____";

-- converting the data type of order date into date as it was in teexxt
alter table sales_staging1
modify column `order date` date;

-- finding the date having 0000-00-00
select `order date`,count(*) as total
from sales_staging1
group by `order date`
having `order date`="0000-00-00";


-- converting 0000-00-00 into null
update sales_staging1
set `order date`= NULL
where `order date`="0000-00-00";

-- checking for the invalid date
select * from sales_staging1
where `order date`="2024-02-30";

-- finding all the invalid dates
select `order date`
from sales_staging1
where str_to_date(`order date`,"%Y-%m-%d") is null
and `order date` is not null;

-- making the dataset consistent
select `order date`, date_format(
str_to_date(`order date`,"%Y/%c/%e"),"%Y-%m-%d") as converted_date
from sales_staging1
where `order date` like "____/%";

-- selecting the date in d/m/y format
select `order date` from sales_staging1
where `order date` like "__/__/____";

-- converting them to y-m-d 
select `order date`,date_format(
str_to_date(`order date`,"%d/%m/%Y"),"%Y-%m-%d")as covert_date
from sales_staging1
where `order date` like "__/%";

-- updating the table (not runed)
update sales_staging1
set `order date`= NULL
where `order date` is not NULL
and(
(`order date` like "__/__/____"
and str_to_date(`order date`,"%d/%m/%Y") is null)
);


UPDATE sales_staging1
SET `Order Date` = DATE_FORMAT(
    STR_TO_DATE(`Order Date`, '%Y/%c/%e'),
    '%Y-%m-%d'
)
WHERE `Order Date` LIKE '____/%';

-- finally converting the datatype (not converted will convert in python)
alter table sales_staging1
modify column `Order Date` date;



-- handling the null values
-- 1st in price column
select *
from sales_staging1
where price is null;

select product,count(*) as total_records,
count(price) as price_available,
min(price) as min_price,
max(price) as max_price,
round(avg(price),2) as avg_price
from sales_staging1
group by product
order by product;

-- we leave the price column value as null 
-- filling with avg provide inconsistent price of the product as sum product varies largly


-- next missing column delivery time
select * 
from sales_staging1
where `Delivery Time` is NULL;

select min(`delivery time`) as min_day,
max(`delivery time`) as max_days,
round(avg(`delivery time`),2) as avg_day,
round(stddev(`delivery time`),2) as std_dev
from sales_staging1;

-- calculating median to fill the missing value od delivery time
-- using cte
with ordered_delivery as(
select `delivery time`,
row_number() over(order by `delivery time`) as row_num,
count(*) over() as total_rows
from sales_staging1
where `delivery time` is not null
)

select avg(`delivery time`) as median_delivery_time
from ordered_delivery
where row_num in (
floor((total_rows + 1)/2),
floor((total_rows + 2)/2)
);

-- filling the missing value with median 
update sales_staging1
set `delivery time`=6
where `delivery time` is NULL;

-- verifying the updates
select count(*) as missing_delivery_time
from sales_staging1
where `delivery time` is null;

-- deleting the duplicate records
-- detect
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   `Order ID`,
                   `Customer ID`,
                   Product,
                   Category,
                   Price,
                   Quantity,
                   Discount,
                   `Order Date`,
                   Region,
                   `Payment Method`,
                   `Delivery Time`
               ORDER BY `Order ID`
           ) AS rn
    FROM sales_staging1
)
SELECT *
FROM duplicate_cte
WHERE rn > 1;

-- checking version of mysql
select version();

-- checking if there is any primary key or not
show keys
from sales_staging1
where key_name = "primay";

-- no primary key so adding the primary key
alter table sales_staging1
add column id int auto_increment primary key;

-- after making the primary key we will verfy the id
select *
from sales_staging1
limit 5;

-- looking which is primary key
show keys
from sales_staging1
where key_name="Primary";

-- deleting the duplicate records
delete s1
from sales_staging1 as s1
join (
select id
from(select id,row_number() over(
partition by `Order ID`, `Customer ID`, Product, 
Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by id) as rn
from sales_staging1
)  t
where rn>1
) d
on s1.id= d.id;

-- verifying it
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   `Order ID`,
                   `Customer ID`,
                   Product,
                   Category,
                   Price,
                   Quantity,
                   Discount,
                   `Order Date`,
                   Region,
                   `Payment Method`,
                   `Delivery Time`
               ORDER BY `Order ID`
           ) AS rn
    FROM sales_staging1
)
SELECT *
FROM duplicate_cte
WHERE rn > 1;

-- now checking the cleaned dataset
select count(*) as total_records
from sales_staging1;

-- removed duplicate
-- missing values summary
SELECT
SUM(CASE WHEN `Order ID` IS NULL THEN 1 ELSE 0 END) AS OrderID_Null,
SUM(CASE WHEN `Customer ID` IS NULL THEN 1 ELSE 0 END) AS CustomerID_Null,
SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) AS Product_Null,
SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Category_Null,
SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS Price_Null,
SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_Null,
SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Discount_Null,
SUM(CASE WHEN `Order Date` IS NULL THEN 1 ELSE 0 END) AS OrderDate_Null,
SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS Region_Null,
SUM(CASE WHEN `Payment Method` IS NULL THEN 1 ELSE 0 END) AS PaymentMethod_Null,
SUM(CASE WHEN `Delivery Time` IS NULL THEN 1 ELSE 0 END) AS DeliveryTime_Null
FROM sales_staging1;


/* | Issue             | Action Taken                                                      | Reason                                                 |
| ----------------- | ----------------------------------------------------------------- | ------------------------------------------------------ |
| Duplicate Records | Removed 175 duplicates                                            | Prevent duplicate analysis                             |
| Category          | Standardized values                                               | Consistent grouping                                    |
| Payment Method    | Standardized values                                               | Consistent reporting                                   |
| Region            | Verified                                                          | No issues found                                        |
| Delivery Time     | Filled NULLs with median (6 days)                                 | Small range and median ≈ mean                          |
| Price             | Left NULL                                                         | High variation; imputation could bias results          |
| Order Date        | Mixed formats standardized where possible; invalid dates retained | Invalid dates require more flexible handling in Python |
*/



-- EDA analysis
-- 1. Total revenue generated by company
select round(sum(price*quantity*(1- Discount /100)),2) as total_revenue
from sales_staging1;
-- '272204118.87' total revenue were generated


-- 2.How many orders were successfully recorded
select count(*) as total_records
from sales_staging1;
-- 3210 records were successfully recorded

-- How many unique cistomer placed the order
select count(distinct( `Customer ID`)) as total_customer
from sales_staging1;
-- there were 665 unique customers


-- average number of order per customer
select  count(*) as total_records,
count(distinct( `Customer ID`)) as total_customer,
round( count(*)/count(distinct( `Customer ID`)),2) as avg_order
from sales_staging1;

-- How many product were sold in total
select sum(quantity) as total_quantity_sold
from sales_staging1;
-- 12800 products were sold
-- The company sold a total of 12,800 products across 3,210 orders.
-- This means customers often purchased more than one item per order.


-- Average Order values:(total_revenue/total orders)
-- on avg,how much revenue does each order generate

select  round(sum(price*quantity*(1- Discount /100)),2) as total_revenue,
count(*) as total_order,
round(sum(price*quantity*(1- Discount /100))/count(*),2)
as average_order_value
from sales_staging1;


-- product analysis
-- 1. which product sells the most?

select product,
sum(quantity) as total_quantity_sold
from sales_staging1
group by product
order by sum(quantity) desc
limit 10;
-- home theater system is the best selling product with 3120 units sold.

-- which product generate the highest revenue
select product,round(sum(price*quantity*(1- Discount /100)),2) 
as total_revenue
from sales_staging1
group by product
order by total_revenue desc
limit 10;
-- Insight 1: Home Theater System is the top revenue generator
-- It generated 97.85 million, making it the company's highest revenue product.


-- which product categories generate the highest revenue?
select Category,round(sum(price*quantity*(1- Discount /100)),2) 
as total_revenue
from sales_staging1
group by Category
order by total_revenue desc
limit 10;
-- Electronics dominates the business
-- Electronics generated 250.98 million in revenue, making it by far the company's largest revenue source.

-- Which region generates the highest revenue?
select region,round(sum(price*quantity*(1- Discount /100)),2) 
as total_revenue
from sales_staging1
group by region
order by total_revenue desc
limit 10;
-- Mumbai is the highest revenue-generating region
-- Mumbai contributed 89.33 million in revenue, making it the company's strongest market


-- which month has the highest sales?
select monthname(`order date`) as month,
sum(quantity) as total_quantity_sold,
round(SUM(Price * Quantity * (1 - Discount / 100)),2) 
as total_sales_per_month
from sales_staging1
GROUP BY MONTH(`Order Date`), MONTHNAME(`Order Date`)
order by total_sales_per_month desc
limit 10;
-- Insight 1: June is the strongest sales month
-- June generated 147.80 million in revenue and sold 3,795 units, making it the best-performing month.


-- Customer Behavior
-- Which payment method is used the most
select `payment method`,count(*) as total_orders
from sales_staging1
group by `Payment Method`
order by total_orders desc;
-- Mobile Wallet is the most preferred payment method
-- Customers placed 572 orders using Mobile Wallet, making it the most popular payment option.

-- Which payment method generates the highest revenue?
select `payment method`,count(*) as total_orders,
round(SUM(Price * Quantity * (1 - Discount / 100)),2) 
as highest_revenue
from sales_staging1
group by `Payment Method`
order by highest_revenue desc;


-- Who are the top 10 customers by total spending?
select `customer id`,
round(SUM(Price * Quantity * (1 - Discount / 100)),2) 
as total_spending_per_customer
from sales_staging1
group by `customer id`
order by total_spending_per_customer desc
limit 10;

-- Which customers placed the most orders?
select `customer id`,
count(*) as total_order
from sales_staging1
group by `Customer ID`
order by total_order desc;

-- What is the impact of discounts on sales?

select distinct discount
from sales_staging1
order by discount;

select discount,
count(*) as total_orders,
sum(quantity) as total_quantity_sold,
round(SUM(Price * Quantity * (1 - Discount / 100)),2) as total_revenue
from sales_staging1
group by Discount
order by Discount ;

-- Which regions have the fastest and slowest delivery times?
select region,round(avg(`delivery time`),2) as avg_delivery_time_days,
count(*) as total_orders
from sales_staging1
group by region
order by avg_delivery_time_days;

-- count order for each customer
select `customer id`,
count(*) as total_orders
from sales_staging1
group by `customer id`;

-- calculate repeat customer
select count(*) as repeat_customers
from(
select `customer id`,
count(*) as total_orders
from sales_staging1
group by `customer id`
having count(*) > 1
) as repeat_customers;