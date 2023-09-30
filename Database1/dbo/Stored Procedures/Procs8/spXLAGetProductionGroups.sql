Create Procedure dbo.spXLAGetProductionGroups
 	 @ProdUnitId int 	  	  	 /* Production Unit Id */
AS
Declare @queryType tinyint
If @ProdUnitId Is Null SELECT @queryType =  1 
Else SELECT @queryType = 2
If @queryType = 1 	  	 -- @pu_id Null   
   BEGIN
 	   SELECT  DISTINCT pug.PUG_Id, pug.PUG_Desc
 	     FROM  PU_Groups pug
 	     JOIN  Variables v ON v.PUG_Id = pug.PUG_Id
 	    WHERE  pug.PUG_Id <> 0
 	      AND  v.PUG_Id IS NOT NULL
 	 ORDER BY  pug.PUG_Desc  	 
   END
else if @queryType = 2 	  	 -- @pu_id Not Null
   BEGIN
 	   SELECT  DISTINCT pug.PUG_Id, pug.PUG_Desc
 	     FROM  PU_Groups pug
 	     JOIN  Prod_Units pu ON  pug.PU_Id = pu.PU_Id 
 	     JOIN  Variables v ON v.PUG_Id = pug.PUG_Id
 	    WHERE  pug.PUG_Id <> 0
 	      AND  pug.PU_Id = @ProdUnitId 
 	      AND  v.PUG_Id IS NOT Null
 	 ORDER BY  pug.PUG_Desc
   END
