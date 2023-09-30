/* 
   ----------------------------------------------------------------------------------
 	 Date: 	 Modified 7-17-2001 MT
 	 Desc:  	 Added 'Product Line' as additional filter to previous version
   ----------------------------------------------------------------------------------
*/
Create Procedure dbo.spXlaSearchVariable
 	   @SearchString 	  	 varchar(50)
 	 , @MasterUnit  	  	 int
 	 , @ProductionGroup  	 int = Null
 	 , @ProductionLine 	 int = NULL
AS
Declare @queryType tinyint
If @SearchString Is Null And @MasterUnit is Null And @ProductionGroup Is Null And @ProductionLine Is Null
  SELECT @queryType = 1
Else If @SearchString Is Null And @MasterUnit is Not Null And @ProductionGroup Is Null And @ProductionLine Is Null
  SELECT @queryType = 2
Else If @SearchString Is Null And @MasterUnit is Not Null And @ProductionGroup Is Not Null And @ProductionLine Is Null
  SELECT @queryType = 3
Else If @SearchString Is Not Null And @MasterUnit is Null And @ProductionGroup Is Null And @ProductionLine Is Null
  SELECT @queryType = 4
Else If @SearchString Is Not Null And @MasterUnit is Not Null And @ProductionGroup Is Null And @ProductionLine Is Null
  SELECT @queryType = 5
Else If @SearchString Is Not Null And @MasterUnit is Not Null And @ProductionGroup Is Not Null And @ProductionLine Is Null
  SELECT @queryType = 6
Else If @SearchString Is Null And @MasterUnit is Null And @ProductionGroup Is Null And @ProductionLine Is NOT Null
  SELECT @queryType = 7
Else If @SearchString Is Null And @MasterUnit is Not Null And @ProductionGroup Is Null And @ProductionLine Is NOT Null
  SELECT @queryType = 8
Else If @SearchString Is Null And @MasterUnit is Not Null And @ProductionGroup Is Not Null And @ProductionLine Is NOT Null
  SELECT @queryType = 9
Else If @SearchString Is Not Null And @MasterUnit is Null And @ProductionGroup Is Null And @ProductionLine Is NOT Null
  SELECT @queryType = 10
Else If @SearchString Is Not Null And @MasterUnit is Not Null And @ProductionGroup Is Null And @ProductionLine Is NOT Null
  SELECT @queryType = 11
Else If @SearchString Is Not Null And @MasterUnit is Not Null And @ProductionGroup Is Not Null And @ProductionLine Is NOT Null
  SELECT @queryType = 12
If @queryType = 1 	  	 -- @SearchString Null, @MasterUnit Null, @ProductionGroup Null, @ProductionLine Null 
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
 	     FROM  Variables v
 	     JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	     JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
else if @queryType = 2 	  	 -- @SearchString Null, @MasterUnit Not Null, @ProductionGroup Null, @ProductionLine Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	      AND  (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit) 
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc
   END
else if @queryType = 3 	  	 -- @SearchString Null, @MasterUnit Not Null, @ProductionGroup Not Null, @ProductionLine Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id 
 	      AND  (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit)
 	     JOIN  PU_Groups pug ON pug.PUG_Id = v.PUG_Id 
 	      AND  pug.PUG_Id = @ProductionGroup
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
else if @queryType = 4 	  	 -- @SearchString Not Null, @MasterUnit Null, @ProductionGroup Null, @ProductionLine Null
  BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
 	     FROM  Variables v
 	     JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	     JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
 	      AND  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
  END
else if @queryType = 5 	  	 -- @SearchString Not Null, @MasterUnit Not Null, @ProductionGroup Null, @ProductionLine Null
  BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
 	     FROM  Variables v
 	     JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	      AND  (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit)
 	     JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
 	      AND  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
  END
else if @queryType = 6 	  	 -- @SearchString Not Null, @MasterUnit Not Null, @ProductionGroup Not Null, @ProductionLine Null
  BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id 
 	      AND  (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit)
 	     JOIN  PU_Groups pug ON pug.PUG_Id = v.PUG_Id  
 	      AND  pug.PUG_Id = @ProductionGroup
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
 	      AND  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @queryType = 7 	  	 -- @SearchString Null, @MasterUnit Null, @ProductionGroup Null, @ProductionLine Not Null 
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
 	     FROM  Variables v
 	     JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	     JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @ProductionLine
 	     JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
else if @queryType = 8 	  	 -- @SearchString Null, @MasterUnit Not Null, @ProductionGroup Null, @ProductionLine NOT Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit) 
            JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @ProductionLine
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc
   END
else if @queryType = 9 	  	 -- @SearchString Null, @MasterUnit Not Null, @ProductionGroup Not Null, @ProductionLine NOT Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit)
 	     JOIN  PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
            JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @ProductionLine
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
 	    WHERE  v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
Else If @queryType = 10 	  	 -- @SearchString Not Null, @MasterUnit Null, @ProductionGroup Null, @ProductionLine NOT Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
 	     FROM  Variables v
 	     JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id
 	     JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @ProductionLine
 	     JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' AND v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
Else If @queryType = 11 	  	 -- @SearchString Not Null, @MasterUnit Not Null, @ProductionGroup Null, @ProductionLine NOT Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit) 
            JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @ProductionLine
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' AND v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc
   END
Else If @queryType = 12 	  	 --@SearchString Not Null, @MasterUnit Not Null, @ProductionGroup Not Null, @ProductionLine NOT Null
   BEGIN
 	   SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
            FROM  Variables v
            JOIN  Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @MasterUnit OR pu.Master_Unit = @MasterUnit)
 	     JOIN  PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
            JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @ProductionLine
            JOIN  Data_Source ds ON ds.ds_id = v.ds_id
           WHERE  v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' AND v.PU_Id <> 0
 	 ORDER BY  v.Var_Desc, pu.PU_Desc  	 
   END
