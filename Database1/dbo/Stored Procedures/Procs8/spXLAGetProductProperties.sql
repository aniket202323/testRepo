Create Procedure dbo.spXLAGetProductProperties
 	 @ID int = 0,
 	 @SearchString varchar(50) = NULL
AS 
If @ID = 0
    if @SearchString Is NULL
 	 BEGIN
        	     SELECT prop_id, prop_desc FROM product_properties ORDER BY prop_desc
 	 END
    Else
 	 BEGIN
        	     SELECT prop_id, prop_desc 
 	     FROM   product_properties 
 	     WHERE  prop_desc like '%' + ltrim(rtrim(@SearchString)) + '%' 
 	     ORDER BY prop_desc
 	 END
Else
    BEGIN
      	 /* select prop_desc from product_properties where prop_id = @ID */
        SELECT * FROM product_properties WHERE prop_id = @ID
    END
