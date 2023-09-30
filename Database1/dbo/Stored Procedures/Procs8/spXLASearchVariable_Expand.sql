-- DESCRIPTION: spXLASearchVariable_Expand returns variables and their info based on specified input. Input parameter
--              nomenclature follows terms used by PrfXla.xla. Code based on spXLASearchVariable; input parameter
--              rearranged into better logical order, and SQL statement expanded to cover all possible combination 
--              of inputs. However, PrfXla.xla may disallow certain combination. MT/4-3-2002. 
CREATE PROCEDURE dbo.spXLASearchVariable_Expand
 	   @Line 	  	  	 Int 	  	  	 --Production Line
 	 , @Location  	  	 Int 	  	  	 --Master Unit or Slave Unit
 	 , @ProductionGroup  	 Int 	  	  	 --Production Group
 	 , @SearchString 	  	 varchar(50) = NULL 	 --Filter For Var_Desc
AS
DECLARE @QType tinyint
DECLARE @NoLineNoUnitNoGroupNoString 	  	 TinyInt
DECLARE @NoLineNoUnitNoGroupHasString 	  	 TinyInt
DECLARE @NoLineHasUnitNoGroupNoString  	  	 TinyInt
DECLARE @NoLineHasUnitNoGroupHasString 	  	 TinyInt 	 
DECLARE @NoLineNoUnitHasGroupNoString  	  	 TinyInt
DECLARE @NoLineNoUnitHasGroupHasString 	  	 TinyInt
DECLARE @NoLineHasUnitHasGroupNoString  	  	 TinyInt
DECLARE @NoLineHasUnitHasGroupHasString 	  	 TinyInt
DECLARE @HasLineNoUnitNoGroupNoString  	  	 TinyInt
DECLARE @HasLineNoUnitNoGroupHasString 	  	 TinyInt
DECLARE @HasLineHasUnitNoGroupNoString  	  	 TinyInt
DECLARE @HasLineHasUnitNoGroupHasString 	  	 TinyInt
DECLARE @HasLineNoUnitHasGroupNoString  	  	 TinyInt
DECLARE @HasLineNoUnitHasGroupHasString 	  	 TinyInt
DECLARE @HasLineHasUnitHasGroupNoString 	  	 TinyInt
DECLARE @HasLineHasUnitHasGroupHasString 	 TinyInt
SELECT @NoLineNoUnitNoGroupNoString 	 = 1 
SELECT @NoLineNoUnitNoGroupHasString 	 = 4
SELECT @NoLineHasUnitNoGroupNoString  	 = 2
SELECT @NoLineHasUnitNoGroupHasString 	 = 5
SELECT @NoLineNoUnitHasGroupNoString  	 = 13
SELECT @NoLineNoUnitHasGroupHasString 	 = 14
SELECT @NoLineHasUnitHasGroupNoString  	 = 3
SELECT @NoLineHasUnitHasGroupHasString 	 = 6
SELECT @HasLineNoUnitNoGroupNoString  	 = 7
SELECT @HasLineNoUnitNoGroupHasString 	 = 10
SELECT @HasLineHasUnitNoGroupNoString  	 = 8
SELECT @HasLineHasUnitNoGroupHasString 	 = 11
SELECT @HasLineNoUnitHasGroupNoString  	 = 15
SELECT @HasLineNoUnitHasGroupHasString 	 = 16
SELECT @HasLineHasUnitHasGroupNoString 	 = 9
SELECT @HasLineHasUnitHasGroupHasString 	 = 12
-- FIGURE OUT QUERY TYPE BASED ON INPUT PARAMETERS
If @Line Is NULL
  BEGIN
    If @Location is NULL AND @ProductionGroup Is NULL
      SELECT @QType = Case When @SearchString Is NULL Then @NoLineNoUnitNoGroupNoString Else @NoLineNoUnitNoGroupHasString End
    Else If @Location Is NOT NULL AND @ProductionGroup Is NULL
      SELECT @QType = Case When @SearchString Is NULL Then @NoLineHasUnitNoGroupNoString Else @NoLineHasUnitNoGroupHasString End
    Else If @Location Is NULL AND @ProductionGroup Is NOT NULL
      SELECT @QType = Case When @SearchString Is NULL Then @NoLineNoUnitHasGroupNoString Else @NoLineNoUnitHasGroupHasString End
    Else If @Location Is NOT NULL AND @ProductionGroup Is NOT NULL
      SELECT @QType = Case When @SearchString Is NULL Then @NoLineHasUnitHasGroupNoString Else @NoLineHasUnitHasGroupHasString End
    --EndIf
  END
Else --Has Line
  BEGIN
    If @Location is NULL AND @ProductionGroup Is NULL
      SELECT @QType = Case When @SearchString Is NULL Then @HasLineNoUnitNoGroupNoString Else @HasLineNoUnitNoGroupHasString End
    Else If @Location Is NOT NULL AND @ProductionGroup Is NULL
      SELECT @QType = Case When @SearchString Is NULL Then @HasLineHasUnitNoGroupNoString Else @HasLineHasUnitNoGroupHasString End
    Else If @Location Is NULL AND @ProductionGroup Is NOT NULL
      SELECT @QType = Case When @SearchString Is NULL Then @HasLineNoUnitHasGroupNoString Else @HasLineNoUnitHasGroupHasString End
    Else If @Location Is NOT NULL AND @ProductionGroup Is NOT NULL
      SELECT @QType = Case When @SearchString Is NULL Then @HasLineHasUnitHasGroupNoString Else @HasLineHasUnitHasGroupHasString End
    --EndIf
  END
--EndIf @Line
-- QUERY BASED ON THE QUERY TYPE PREVIOUSLY FIGURED 
If @QType = @NoLineNoUnitNoGroupNoString 	  	 --1
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitNoGroupNoString 	  	 --2
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @NoLineHasUnitHasGroupNoString 	  	 --3
  BEGIN
        SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
          FROM Variables v
          JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
          JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
          JOIN Data_Source ds ON ds.ds_id = v.ds_id
         WHERE v.PU_Id <> 0
      ORDER BY v.Var_Desc, pu.PU_Desc  	 
   END
Else If @QType = @NoLineNoUnitNoGroupHasString 	  	 --4
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0 
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%'
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitNoGroupHasString 	  	 --5
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
         AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0 
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitHasGroupHasString 	 --6
  BEGIN
      SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @NoLineNoUnitHasGroupNoString 	  	 --13
  BEGIN
      SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @NoLineNoUnitHasGroupHasString 	  	 --14
  BEGIN
      SELECT  v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @HasLineNoUnitNoGroupNoString 	  	 --7
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineHasUnitNoGroupNoString 	  	 --8
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @HasLineHasUnitHasGroupNoString 	 --9
   BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitNoGroupHasString 	  	 --10
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineHasUnitNoGroupHasString 	 --11
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%'
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @HasLineHasUnitHasGroupHasString 	 --12
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0 
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitHasGroupNoString 	  	 --15
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitHasGroupHasString 	 --16
  BEGIN
      SELECT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.ds_id = v.ds_id
       WHERE v.PU_Id <> 0 
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
--EndIf
