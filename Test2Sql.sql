--------------------------------------------------------------------------------
USE `northwind`;
--------------------------------------------------------------------------------
-- 1. Order Subtotals
select OrderID, 
    sum(UnitPrice * Quantity * (1- Discount))  as Subtotal
from order_details
group by OrderID
order by OrderID;

-- 2. Sales by Year
select distinct date(ord.ShippedDate) as ShippedDate, 
    ord.OrderID, 
    ord_d.Subtotal, 
    year(ord.ShippedDate) as Year
from Orders as ord
join 
( -- Inner query
    select distinct OrderID, 
	sum(UnitPrice * Quantity * (1 - Discount)) as Subtotal
    from order_details as ord_d
    group by OrderID    
)
ord_d 
using(orderId)
where ord.ShippedDate is not null
and ord.ShippedDate between date('1996-12-24') and date('1997-09-30')
order by ord.ShippedDate;

-- 3. Employee Sales by Country
select  emp.Country,
		emp.LastName, 
	    emp.FirstName, 
	    ord.ShippedDate,
		ord.OrderID,
		ordd.Subtotal as Sale_Amount
	from employees as emp
	join orders as ord
    join(
			-- Inner query
			select distinct OrderID, 
			sum(UnitPrice * Quantity ) as Subtotal
			from order_details as ord_d
			group by OrderID    
				) 
	ordd
	on emp.EmployeeID = ord.EmployeeID
	where ord.ShippedDate is not null
    order by ShippedDate;
    
  -- 4. Alphabetical List of Products
select * from categories;
select * from products;

select  prd.ProductID,
		prd.ProductName,
        prd.SupplierID,
        prd.CategoryID,
        prd.QuantityPerUnit,
        prd.ProductID,
        prd.UnitPrice
from Categories cat 
inner join Products prd 
on cat.CategoryID = prd.CategoryID
where prd.Discontinued = 'n'
order by prd.ProductName;

-- 5. Current Product List
select ProductID, ProductName
from products
where Discontinued = 'n'
order by ProductName;

-- 6. Order Details Extended
select ordd.OrderID, 
    ordd.ProductID, 
    prd.ProductName, 
    ordd.UnitPrice, 
    ordd.Quantity, 
    ordd.Discount, 
    round(ordd.UnitPrice * ordd.Quantity * (1 - ordd.Discount)) as ExtendedPrice
from Products as prd 
inner join Order_Details as ordd
on prd.ProductID = ordd.ProductID
order by ordd.OrderID;

-- 7. Sales by Category
select cat.CategoryID, 
    cat.CategoryName,  
    prd.ProductName, 
    sum(round(ordd.UnitPrice * ordd.Quantity * (1 - ordd.Discount))) as ProductSales
from Order_Details as ordd
inner join Orders as ords
using(OrderID )
inner join Products as prd 
using(ProductID)
inner join Categories as cat
using(CategoryID)
where ords.OrderDate between date('1997/1/1') and date('1997/12/31')
group by cat.CategoryID, cat.CategoryName, prd.ProductName
order by cat.CategoryName, prd.ProductName, ProductSales;
 
 -- 8. Ten Most Expensive Products
select  ProductName as Ten_Most_Expensive_Products, UnitPrice
from Products as p1
where 10 >=    (   -- inner query
					select count(UnitPrice)
                    from Products as p2
                    where p2.UnitPrice >= p1.UnitPrice
                    )
order by UnitPrice desc;
 
 -- 9. Products by Category
 select cat.CategoryName, 
    prd.ProductName, 
    prd.QuantityPerUnit, 
    prd.UnitsInStock, 
    prd.Discontinued
from Categories as cat
join Products as prd
using(CategoryID)
where prd.Discontinued = 'n'
order by cat.CategoryName,
		 prd.ProductName;
 
 -- 10. Customers and Suppliers by City
 -- two tables 'Customers' and 'Suppliers'
select City, CompanyName, ContactName, 'Customers' as Relationship 
from Customers
union
select City, CompanyName, ContactName,'Suppliers'
from Suppliers
order by City, CompanyName;

-- 11. Products Above Average Price
-- Only one table
select ProductName, UnitPrice
from Products
where UnitPrice > (	-- inner query
					select avg(UnitPrice) 
                    from Products
                    )
order by UnitPrice;

-- 12. Product Sales for 1997
select  cat.CategoryName, 
    prd.ProductName, 
    format(sum(ordd.UnitPrice * ordd.Quantity * ( 1- ordd.Discount)),2) as ProductSales,
    concat('Qtr', quarter(ords.ShippedDate)) as ShippedQuarter
from Categories as cat
join Products as prd
using(CategoryID)
join Order_Details as ordd
using(ProductID)
join Orders as ords 
using(OrderID)
where ords.ShippedDate between date('1997-01-01') and date('1997-12-31')
group by cat.CategoryName, 
    prd.ProductName,
    concat('Qtr ', quarter(ords.ShippedDate))
order by cat.CategoryName, 
    prd.ProductName,
    ShippedQuarter;

-- 13. Category Sales for 1997
select CategoryName,  format(sum(ProductSales), 2) as CategorySales
from
	(
		select  cat.CategoryName, 
		prd.ProductName, 
		format(sum(ordd.UnitPrice * ordd.Quantity * ( 1- ordd.Discount)),2) as ProductSales,
		concat('Qtr', quarter(ords.ShippedDate)) as ShippedQuarter
	from Categories as cat
	join Products as prd
	using(CategoryID)
	join Order_Details as ordd
	using(ProductID)
	join Orders as ords 
	using(OrderID)
	where ords.ShippedDate between date('1997-01-01') and date('1997-12-31')
	group by cat.CategoryName, 
			prd.ProductName,
		concat('Qtr ', quarter(ords.ShippedDate))
	order by cat.CategoryName, 
			prd.ProductName,
			ShippedQuarter
						) as cate
	group by CategoryName;
    
-- 14. Quarterly Orders by Product
select prd.ProductName, 
       cus.CompanyName, 
    year(OrderDate) as OrderYear,
    format(sum(case quarter(ord.OrderDate) 
    when '1' 
        then ordd.UnitPrice * ordd.Quantity * (1-ordd.Discount) 
        else 0 
        end), 0) "Qtr 1",
    format(sum(case quarter(ord.OrderDate) 
    when '2' 
		 then ordd.UnitPrice * ordd.Quantity * (1-ordd.Discount) 
         else 0 
         end), 0) "Qtr 2",
    format(sum(case quarter(ord.OrderDate) 
    when '3' 
		 then ordd.UnitPrice * ordd.Quantity * (1-ordd.Discount) 
         else 0 
         end), 0) "Qtr 3",
    format(sum(case quarter(ord.OrderDate) 
    when '4' 
        then ordd.UnitPrice * ordd.Quantity * (1-ordd.Discount)
        else 0
        end), 0) "Qtr 4"
from Products as prd 
join Order_Details as ordd  
using(ProductID )
join Orders as ord
 using(OrderID)
join Customers as cus
 using(CustomerID)
where ord.OrderDate between date('1997-01-01') and date('1997-12-31')
group by prd.ProductName, 
         cus.CompanyName, 
		 year(OrderDate)
order by prd.ProductName, cus.CompanyName;

-- 15. Invoice
select b.ShipName, 
    b.ShipAddress, 
    b.ShipCity, 
    b.ShipRegion, 
    b.ShipPostalCode, 
    b.ShipCountry, 
    b.CustomerID, 
    c.CompanyName, 
    c.Address, 
    c.City, 
    c.Region, 
    c.PostalCode, 
    c.Country, 
    concat(d.FirstName, ' ', d.LastName) as Salesperson, 
	b.OrderID, 
    b.OrderDate, 
    b.RequiredDate, 
    b.ShippedDate, 
    a.CompanyName, 
    e.ProductID, 
    f.ProductName, 
    e.UnitPrice, 
    e.Quantity, 
    e.Discount,
    e.UnitPrice * e.Quantity * (1 - e.Discount) as ExtendedPrice,
    b.Freight
from Shippers as a 
join Orders as b 
on a.ShipperID = b.ShipVia 
join Customers as c
using(CustomerID )
join Employees as d 
using(EmployeeID)
join Order_Details as e 
using(OrderID)
join Products as f 
using(ProductID)
order by b.ShipName;

-- 16. Number of units in stock by category and supplier continent
select c.CategoryName as "Product Category", 
       case 
       when s.Country in 
                 ('UK','Spain','Sweden','Germany','Norway',
                  'Denmark','Netherlands','Finland','Italy','France')
            then 'Europe'
		    when s.Country in ('USA','Canada','Brazil') 
            then 'America'
				else 'Asia-Pacific'
			end as "Supplier Continent", 
        sum(p.UnitsInStock) as UnitsInStock
from Suppliers as s 
inner join Products as p 
using(SupplierID)
inner join Categories as c 
using(CategoryID)
group by c.CategoryName, 
         case 
         when s.Country in 
                 ('UK','Spain','Sweden','Germany','Norway',
                  'Denmark','Netherlands','Finland','Italy','France')
              then 'Europe'
		 when s.Country in ('USA','Canada','Brazil') 
              then 'America'
				else 'Asia-Pacific'
			end;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------