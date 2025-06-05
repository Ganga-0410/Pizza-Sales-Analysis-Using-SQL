create table order_details
(
    order_detail_id int,
    order_id int,
    pizza_id varchar2(70),
    quantity number
);

create table orders1
(
    order_id int,
    dates date,
    times varchar2(50)
);

create table pizza_types
(
    pizza_type varchar2(60),
    p_name varchar2(200),
    p_category varchar2(100),
    ingredients varchar2(2000)
);

create table pizza1
(
    pizza_id varchar2(60),
    pizza_type varchar2(200),
    p_size varchar2(100),
    price number(4, 2)
);

select * from order_details;
select * from orders1;
select * from pizza_types;
select * from pizza1;
------------------------------------------------------------------------------------------------------
--Basic Questions
-- Retrieve the total number of orders placed.
select count(order_id) as total_orders from orders1;

-- Calculate the total revenue generated from pizza sales.
select SUM(od.quantity * p.price) as Total_revenue
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id;

-- Identify the highest-priced pizza. (the_greek pizza is having high price)  
select p_name, price
from (select pt.P_name, p.price, rank() over(order by p.price desc) as rn 
from pizza1 p join pizza_types pt on p.pizza_type = pt.pizza_type) rnk
where rn = 1;

-- Identify the most common pizza size ordered. (L size pizza is mostly ordered)
select p.p_size, count(od.order_detail_id) as total_orders
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id
group by p.p_size
order by total_orders desc;

--Intermediate Questions
--List the top 5 most ordered pizza names along with their quantities.
select p_name, total_quantity
from (select pt.p_name, sum(od.quantity) as total_quantity,
    rank() over(order by sum(od.quantity) desc) as rn
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id join pizza_types pt 
on p.pizza_type = pt.pizza_type
group by pt.p_name
order by total_quantity desc) rnk
where rn <= 5;

-- Determine the distribution of orders by hour of the day.
select extract(hour from TO_TIMESTAMP(times, 'HH24:MI:SS')) as order_hours,
    count(order_id) as total_orders_placed    
from orders1
group by extract(hour from TO_TIMESTAMP(times, 'HH24:MI:SS'))
order by total_orders_placed desc;

--Which pizza category has the highest total quantity of pizzas ordered?
select pt.p_category, sum(od.quantity) as total_quantity_ordered
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id 
join pizza_types pt
on p.pizza_type = pt.pizza_type
group by pt.p_category
order by total_quantity_ordered desc;

--Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(total_orders), 2) as Avg_orders_per_day
from (select o.dates , sum(od.quantity) as total_orders
from orders1 o join order_details od
on od.order_id = o.order_id
group by o.dates
order by o.dates);

--Determine the top 3 most ordered pizza names types based on revenue.
select p_name, total_revenue
from(select pt.p_name, sum(od.quantity * p.price) as total_revenue,
    rank() over(order by sum(od.quantity * p.price) desc) as rn
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id 
join pizza_types pt
on p.pizza_type = pt.pizza_type
group by pt.p_name) rnk
where rn <= 3;

--ADVANCED QUESTIONS
--Calculate the percentage contribution of each pizza category to total revenue.
with total_rev
as(select SUM(od.quantity * p.price) as Total_rev
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id),

each_pizza_rev as
(select pt.p_category, SUM(od.quantity * p.price) as Total_revenue
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id
join pizza_types pt
on p.pizza_type = pt.pizza_type
group by  pt.p_category)

select ep.p_category, Concat(Round((ep.total_revenue/tv.total_rev)*100, 2), '%') as Percent_Contri
from total_rev tv cross join each_pizza_rev ep
order by Percent_Contri desc;

--Analyze the cumulative revenue generated over time.
with cte as
(select o.dates , sum(od.quantity) as total_revenue
from orders1 o join order_details od
on od.order_id = o.order_id
group by o.dates
order by o.dates)

select dates, total_revenue, SUM(total_revenue) over(order by dates) as cum_rev
from cte;

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select p_category, p_name, total_revenue, total_orders, rn
from(select pt.p_category, pt.p_name, 
    sum(od.quantity * p.price) as total_revenue, 
    count(od.order_detail_id) as total_orders,
    rank() over(partition by pt.p_category order by sum(od.quantity * p.price) desc, count(od.order_detail_id)) as rn
from order_details od join pizza1 p
on od.pizza_id = p.pizza_id 
join pizza_types pt
on p.pizza_type = pt.pizza_type
group by pt.p_category, pt.p_name) rnk
where rn <= 3;






