select * from ecommerce_sales;

-- count the dataset:3392 dataset
select count(*)
from ecommerce_sales;

-- Step1:understading the dataset
-- we always perform cleaning in duplicate dataset
create table sales_staging
like ecommerce_sales;

-- inserting value into staging table
insert into sales_staging
select * 
from ecommerce_sales;

select * from sales_staging;
select count(*)
from sales_staging;

-- checking the datatype
describe sales_staging;

-- as we founf inconsistency in catagory lets inspect further
select distinct category
from sales_staging
order by category;

-- counting each category
select category,count(*) as total_records
from sales_staging
group by category
order by total_records desc;

-- checking for the hidden space
select category,length(category) as length,
trim(category) as trimmed_category
from sales_staging
where category like "%Fashion%";

-- check for duplicate records
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging;

-- counting how many duplicates value are there using subquery
select count(*) as duplicate_records
from(
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging) as duplicates
where rn>1;

-- viewing the duplicate records
select *
from(
select *,row_number()
over( partition by  `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging) as duplicates
where rn>1;

-- deleting the duplicate data
with duplicate_cte as (
select *,
row_number() over(
partition by `Order ID`, `Customer ID`, 
Product, Category, Price, Quantity, Discount, 
`Order Date`, Region, `Payment Method`, `Delivery Time`
order by `Order ID`) as rn
from sales_staging
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
FROM sales_staging;

select *
from sales_staging
where price is null;

-- step2:cleaning the data
-- remove extra spaces
update sales_staging
set category= Trim(Category);

-- verifing the category if whitw space is removed or not
select category,count(*) as total_records
from sales_staging
group by Category
order by total_records Desc ;

-- Standardize Category Names
update sales_staging
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
from sales_staging;

select category,count(*) as total_records
from sales_staging
group by category
order by category;

-- moving to region and payment method
select distinct region
from sales_staging
order by region;

select distinct `payment Method`
from sales_staging
order by `Payment Method`;

