select * from list_of_orders
select * from Order_details
select * from sales_target

-------------------------------------------------------------------------------------------------------------

--Creating view for further visualisation

create view combined_orders as
select o.order_id,o.amount,o.profit,o.quantity,o.category,o.sub_category,l.order_date,l.customername,l.state,l.city
from [Ecommerce_project]..Order_details o
join [Ecommerce_project]..list_of_orders l
on o.Order_id=l.Order_id;

-------------------------------------------------------------------------------------------------------------

--Find the number of orders, customers, cities, and states.

select count(distinct(order_id)) as Total_orders,
count(distinct(customername)) as Total_customers,
count(distinct(city)) as Total_cities,
count(distinct(state)) as Total_states
from combined_orders;

-------------------------------------------------------------------------------------------------------------

--Find the new customers who made purchases in the year 2019.
--Order the result by the amount they spent.

select CustomerName,sum(Amount) as Amount from combined_orders
where CustomerName not in (select customername from combined_orders where order_date like '%2018%')
group by CustomerName
order by amount desc;

-------------------------------------------------------------------------------------------------------------

--Find the top profitable states & cities so that the company can expand its business. 
--Determine the number of products sold and the number of customers in these top profitable states & cities.

select state,city,count(distinct(customername)) as Total_customers,sum(profit) as total_profit,sum(quantity) as total_quantity
from combined_orders
group by state,city
order by total_profit desc;

-------------------------------------------------------------------------------------------------------------

--Display the details (in terms of “order_date”, “order_id”, “State”, and “CustomerName”) for the first order in each state.
--Order the result by “order_id”.

select order_date,order_id,state,customername from 
(select *,ROW_NUMBER() over (partition by state order by order_id) as rownumber_per_state from combined_orders) firstorder
where rownumber_per_state=1
order by order_id

-------------------------------------------------------------------------------------------------------------

-- Determine the number of orders (in the form of a histogram) and sales for different days of the week.

select day_of_order,
 right(replicate('*',num_of_orders) + '*',num_of_orders) as histogram,sales 
from ( select DATENAME(WEEKDAY,order_date ) as day_of_order,count(distinct(Order_id)) as num_of_orders,
 sum(amount) as sales from combined_orders group by DATENAME(WEEKDAY,order_date )) sales_per_day
order by sales desc;

-------------------------------------------------------------------------------------------------------------


--Check the monthly profitability and monthly quantity sold.
 
 select concat_ws(' - ',DATENAME(MONTH,order_date),DATENAME(YEAR,ORDER_DATE)) as Month_of_year,sum(profit) as Total_profit,
 sum(quantity) as Total_quantity 
 from combined_orders
 group by concat_ws(' - ',DATENAME(MONTH,order_date),DATENAME(YEAR,ORDER_DATE))
 order by Total_profit desc

 -------------------------------------------------------------------------------------------------------------

 --Determine the number of times that salespeople hit or failed to hit the sales target for each category.

 create view sales_by_category as
 select convert(nvarchar,concat_ws('-',SUBSTRING(DATENAME(MONTH,order_date),1,3),SUBSTRING(DATENAME(YEAR,ORDER_DATE),3,2))) as Month_of_year,category,sum(amount) as sales 
 from combined_orders
 group by category,convert(nvarchar,concat_ws('-',SUBSTRING(DATENAME(MONTH,order_date),1,3),SUBSTRING(DATENAME(YEAR,ORDER_DATE),3,2)))


create view sales_vs_target as
select *,CASE 
              WHEN sales>=target then 'Hit'
			  else 'Fail'
			  end as Hit_or_Fail
from (select s.Month_of_year,s.category,s.sales,t.target from sales_by_category s 
join sales_target t
on s.Month_of_year=t.month_of_order
and s.category=t.Category) st;


Select h.Category,h.Hit,f.Fail 
from
(select category,count(*) as hit
from sales_vs_target where Hit_or_Fail='Hit' 
group by category) h
join 
(select category,count(*) as fail
from sales_vs_target where Hit_or_Fail='Fail' 
group by category) f
on h.category=f.category


-------------------------------------------------------------------------------------------------------------

-- Find the total sales, total profit, and total quantity sold for each category and sub-category. 
--Return the maximum cost and maximum price for each sub-category too.

select z.Category,z.Sub_Category, sum(z.Quantity) total_quantities, sum(z.Profit) total_profit, sum(z.Amount) total_sales, max(z.cost) as max_cost, max(z.price) max_price from
(select *, round(((Amount-Profit)/Quantity),3) as cost, round((Amount/Quantity),3) as price from [Ecommerce_project]..order_Details)z
group by z.Category,z.Sub_Category
order by total_quantities
-------------------------------------------------------------------------------------------------------------