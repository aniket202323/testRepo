Create Procedure dbo.spDBR_Get_Product_Groups
as
 	 create table #pgs
 	 (
 	  	 product_grp_id int,
 	  	 product_grp_desc varchar(50)
 	 )
 	 insert into #pgs values(-3, '[all products]')
 	 insert into #pgs values(-2, '[products run]')
 	 insert into #pgs values(-1, '[any product]')
 	 insert into #pgs select product_grp_id, product_grp_desc from product_groups where product_grp_id > 0
 	 
 	 select * from #pgs
 	 drop table #pgs
 	 
 	 
