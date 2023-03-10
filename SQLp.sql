---review data
select top 10* from [dbo].[AdventureWorks_Products]
select top 10* from [dbo].[AdventureWorks_Returns]
select top 10* from [dbo].[AdventureWorks_Sales_2015]
select top 10* from [dbo].[AdventureWorks_Sales_2016]
select top 10* from [dbo].[AdventureWorks_Sales_2017]


---calculate return rate by product key during three years
create view Product_summary as
(select S.ProductKey,sum(OrderQuantity) Order_q, isnull(sum(ReturnQuantity),0) return_q,sum(isnull(ReturnQuantity,0))*100/sum(OrderQuantity) [return_rate(%)]
from (select ProductKey,Orderquantity
 from [dbo].[AdventureWorks_Sales_2015]
        union all select ProductKey,Orderquantity from [dbo].[AdventureWorks_Sales_2016]
        union all select ProductKey,Orderquantity from [dbo].[AdventureWorks_Sales_2017] ) S
left join [dbo].[AdventureWorks_Returns] R on R.ProductKey=S.ProductKey
group by S.ProductKey)

---calculate the total number of products bought by each customer during three years and classify customers 
CREATE view Type_customer as 
with C as (select CustomerKey,OrderQuantity 
        from [dbo].[AdventureWorks_Sales_2015]
        union all select CustomerKey,OrderQuantity from [dbo].[AdventureWorks_Sales_2016]
        union all select CustomerKey,OrderQuantity from [dbo].[AdventureWorks_Sales_2017] S)
select CustomerKey,sum(OrderQuantity) as totalorder,case 
        when sum(orderQuantity)>=5 then 'Gold'
        when sum(OrderQuantity)<=2 then 'Bronze'
        else 'Silver'
        end as type_customer
from C 
group by CustomerKey


---calculate the average number of orders by month order
create view TotalOrder_month as(
select month(orderdate) as month,sum(orderquantity)/3 as total_order
from (select OrderDate,OrderQuantity
from [dbo].[AdventureWorks_Sales_2015]
union all  select OrderDate,OrderQuantity from [dbo].[AdventureWorks_Sales_2016]
union all select OrderDate,OrderQuantity from [dbo].[AdventureWorks_Sales_2017]) M 
group by month(orderdate))


