SELECT * FROM coffee_schema.`coffee shop csv file`;
describe `coffee shop csv file`;
------------------------------------ PRE-PREPROCESSING ------------------------------------------------------
-- CHANGE transaction_date FROM TEXT TO DATE DATA-TYPE 
Alter table coffee_schema.`coffee shop csv file`
modify column transaction_date DATE;
   -- format date -> Y/M/D
update coffee_schema.`coffee shop csv file`
set transaction_date = date_format(transaction_date, '%Y-%m-%d');

-- CHANGE transaction_date FROM TEXT TO TIME DATA-TYPE 
alter table coffee_schema.`coffee shop csv file`
modify column transaction_time TIME;

UPDATE `coffee shop csv file`
SET transaction_time = str_to_date(transaction_time, '%H-%i-%s');
describe `coffee shop csv file`;

-- Rename column name 
alter table coffee_schema.`coffee shop csv file`
rename column ï»¿transaction_id to transaction_id;
-----------------------------------------------------------------------------------------------------------------------------------

-- Q-1> calculate tot sales for each month 
select month(transaction_date)as monthh, date_format(transaction_date, '%M') as Mname, round(sum(transaction_qty*unit_price),2) as revenue from coffee_schema.`coffee shop csv file`
group by 1,2;

-- Q-2> Calculate sales difference between current & Previous Month (MoM Growth)
with A as 
(
select month(transaction_date)as monthh, date_format(transaction_date, '%M') as Mname, round(sum(transaction_qty*unit_price),2) as revenue from coffee_schema.`coffee shop csv file`
group by 1,2
)
select monthh, Mname, revenue, lag(revenue)over (order by monthh) as PreSales, 
round((revenue - lag(revenue)over (order by monthh)),0) as Growth from A ;

 -- Q-3> Calculate total orders for each month , MoM order growth 
with a as 
(
 select month(transaction_date)as monthh, date_format(transaction_date, '%M') as Mname, 
 count(transaction_id) as orders from coffee_schema.`coffee shop csv file`
 group by 1,2
 )
 select monthh, Mname, orders, lag(orders) over (order by monthh) as preorders, 
 (orders-lag(orders) over (order by monthh)) as Difference from a ; 
 
 -- Q-4> Sales Anaysis by weekend and weekdays 
 with A as 
 (
 SELECT 
    DAYOFWEEK(transaction_date) AS dayy,
    dayname(transaction_date) AS dayname,
    month(transaction_date) as monthh,
    case when dayname(transaction_date) in ('Sunday', 'Saturday') then 'weekend' else 'weekday' end as daytype,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_amount, 
    COUNT(transaction_id) as Total_orders , sum(transaction_qty) as Total_Qty  
FROM 
    coffee_schema.`coffee shop csv file`
GROUP BY 
    1,2, 3, 4
)
select round(sum(total_amount),2), sum(Total_orders), sum(Total_Qty), daytype  from A 
where monthh = 6 
group by 4;

-- Q-5> Sales Analysis by store location
select store_location, monthname(transaction_date) monthh, 
ROUND(SUM(transaction_qty * unit_price), 2) AS total_amount , 
count(transaction_id) orderid
from coffee_schema.`coffee shop csv file`
group by 1,2;

-- Q-6> Daiy sales Analysis with Average line 
with B as 
(
with A as 
(
select day(transaction_date) as dayy, month(transaction_date) as monthh, ROUND(SUM(transaction_qty * unit_price), 2) AS revenue 
from coffee_schema.`coffee shop csv file`
where month(transaction_date) = 5
group by 1,2
)
select dayy, revenue, round(avg(revenue) over (partition by monthh),2) as Avgg from A
)
select *,
case when revenue > Avgg then 'Above Average' 
else 'Below Average' 
end as revStatus 
from B;

-- Q-7> Find sales by category
select ROUND(SUM(transaction_qty * unit_price), 2) AS revenue, product_category 
from coffee_schema.`coffee shop csv file`
group by 2
order by 1 desc;

-- Q-8> Sales Analysis by Days and Hours 
select dayname(transaction_date) as dayy, 
hour(transaction_time) as timee, 
ROUND(SUM(transaction_qty * unit_price), 2) AS revenue
from coffee_schema.`coffee shop csv file`
where month(transaction_date) = 5
group by 1,2
order by revenue desc
limit 10;
