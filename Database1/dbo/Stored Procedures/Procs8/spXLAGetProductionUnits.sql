CREATE PROCEDURE dbo.spXLAGetProductionUnits
 	   @Method integer 
 	 , @ProdLineId 	 Integer = NULL
AS 
DECLARE @queryType 	 tinyint
If @Method = 1 AND @ProdLineId Is NULL SELECT @queryType = 1
Else If @Method = 1 AND @ProdLineId Is NOT NULL SELECT @queryType = 2
Else If @Method = 2 AND @ProdLineId Is NULL SELECT @queryType = 3
Else If @Method = 2 AND @ProdLineId Is NOT NULL SELECT @queryType = 4
/*
 If @Method = 1 
   select * from prod_units
     where pu_id > 0  
     order by pu_desc
 else if @Method = 2
   select * from prod_units 
     where master_unit is NULL and
           pu_id > 0
     order by pu_desc
*/
If @queryType = 1 	  	 -- @Method = 1 AND @ProdLineId Is NULL
  BEGIN
 	 SELECT * FROM prod_units WHERE pu_id > 0 ORDER BY pu_desc
  END
Else If @queryType = 2 	  	 -- @Method = 1 AND @ProdLineId Is NOT NULL
  BEGIN
 	   SELECT  pu.* 
 	     FROM  prod_units pu
 	     JOIN  Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @ProdLineId
 	    WHERE  pu.pu_id > 0 
 	 ORDER BY  pu.pu_desc
  END
Else If @queryType = 3 	  	 -- @Method = 2 AND @ProdLineId Is NULL
  BEGIN  
 	 SELECT * FROM prod_units WHERE master_unit is NULL AND pu_id > 0 ORDER BY pu_desc
  END
Else  	  	  	  	 -- @Method = 2 AND @ProdLineId Is NOT NULl
  BEGIN
 	   SELECT  pu.* 
 	     FROM  prod_units pu
 	     JOIN  Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @ProdLineId
 	    WHERE  master_unit is NULL AND pu_id > 0 
 	 ORDER BY  pu_desc
  END
--EndIf
