---preview tables
select top 3*
from [Sales].[Store]
select top 3 *
from [Production].[Product]
select *
from  [Sales].[SalesOrderHeader]
select top 3 *
from [Sales].[SalesOrderDetail]
select top 3*
from [Person].[Address]
select * 
from [Person].[StateProvince]
---top 3 customers have the highest total sales for each year from 2011 to 2014 
with total_sale as (
    select year(orderdate) [year],customerid,sum(LineTotal) TotalSales
    from [Sales].[SalesOrderHeader] h 
    join [Sales].[SalesOrderDetail] d on h.SalesOrderID=d.SalesOrderID
    group by CustomerID,year(OrderDate)
),
rank_order as(
    select customerid,[year],TotalSales, RANK() over(partition by [year] order by TotalSales desc) ranking
    from total_sale
)
select customerid,[year],totalsales
from rank_order
where ranking in(1,2,3)
order by [year]
---compute revenue deltas between consecutive years of each product   
with total_sale as 
(select ProductID,sum(LineTotal) Total_Sale,year(OrderDate) [year]
from [Sales].[SalesOrderDetail] d 
join [Sales].[SalesOrderHeader] h on d.SalesOrderID=h.SalesOrderID
group by productid, year(OrderDate))
select productid, [year] ,
isnull(LAG(total_sale) over(partition by productid order by [year] ),0) previous_revenue,
isnull(total_sale-LAG(total_sale) over(partition by productid order by [year] ),0) delta
from total_sale
---Create a function that returns the average order size for a given customer and date range.
drop function if EXISTS avg_ordersize
go
create FUNCTION avg_ordersize(
    @customerID varchar(10)
    ,@start_date varchar(10)
    ,@end_date varchar(10))
    returns decimal(8,2)
as 
    begin 
        return(
            select sum(total_sale)/sum(total_order) avg 
            from (select customerid,convert(varchar(10),orderdate,112) [date],count(*) total_order,
            sum(LineTotal) total_sale
            from [Sales].[SalesOrderDetail] d 
            join [Sales].[SalesOrderHeader] h on d.SalesOrderID=h.SalesOrderID
            group by CustomerID, convert(varchar(10),orderdate,112)) a 
            where CustomerID=@customerID and 
            [date] BETWEEN @start_date and @end_date
    ) 
    end 
go 
select(dbo.avg_ordersize(29825, '20120101', '20121231'))

---Create a report that shows the names of all products that have been ordered by customers in the United States but not in Canada

with product_us as(
    SELECT distinct d.ProductID
    from [Sales].[SalesOrderHeader] h
    join [Sales].[SalesOrderDetail] d on h.SalesOrderID=d.SalesOrderID
    join [Sales].[Customer] c on c. CustomerID=h.CustomerID
    join [Person].[BusinessEntityContact] bc on bc.PersonID=c.PersonID
    join [Person].[BusinessEntityAddress] ba on ba.BusinessEntityID=bc.BusinessEntityID
    join [Person].[Address] pa on pa.AddressID=ba.AddressID
    join [Person].[StateProvince] pt on pt.StateProvinceID=pa.StateProvinceID
    where pt.CountryRegionCode='US'
),
produc_CA as( 
    SELECT distinct d.ProductID
    from [Sales].[SalesOrderHeader] h
    join [Sales].[SalesOrderDetail] d on h.SalesOrderID=d.SalesOrderID
    join [Sales].[Customer] c on c. CustomerID=h.CustomerID
    join [Person].[BusinessEntityContact] bc on bc.PersonID=c.PersonID
    join [Person].[BusinessEntityAddress] ba on ba.BusinessEntityID=bc.BusinessEntityID
    join [Person].[Address] pa on pa.AddressID=ba.AddressID
    join [Person].[StateProvince] pt on pt.StateProvinceID=pa.StateProvinceID
    where pt.CountryRegionCode='CA'
),
id_us as (select *
from product_us s 
where not exists(select * from produc_CA c where c.productid=s.productid )) 
select [name] from id_us 
join [Production].[Product] p on id_us.ProductID=p.ProductID
---Create a stored procedure named "GetProductByCategoryAndPrice" that accepts two parameters - category name and price range - and returns a list of products from the AdventureWorks2017 database's Production.Product table that belong to that category and fall within that price range.
drop PROCEDURE if EXISTS GetProductByCategoryAndPrice
go 
create PROC GetProductByCategoryAndPrice
@Cat_name varchar(50),
@Price_Max int, 
@Price_min int 
As 
   select p.name, p.ListPrice
   from [Production].[Product] p 
   join [Production].[ProductSubcategory] s on s.ProductSubcategoryid=p.ProductSubcategoryid
   join[Production].[ProductCategory] c on c.ProductCategoryID=s.productcategoryid 
   where c.name=@Cat_name and p.listprice BETWEEN @Price_min and @Price_max
go 
exec GetProductByCategoryAndPrice
@Cat_name= 'Bikes',
@Price_Min = 500.00,
@Price_Max = 2000.00




