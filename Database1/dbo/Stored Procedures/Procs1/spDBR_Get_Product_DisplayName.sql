Create Procedure dbo.spDBR_Get_Product_DisplayName
@product_id int
as
 	 
 	 if (@product_id = -1)
 	 begin
 	  	 insert into #sp_name_results select '[any product]'
 	 end
 	 else
 	 begin
 	  	  	 insert into #sp_name_results select Prod_desc from products where prod_id = @product_id
 	 end
 	 
