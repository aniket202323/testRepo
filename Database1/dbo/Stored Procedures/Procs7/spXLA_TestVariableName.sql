-- DESCRIPTION: spXLA_TestVariableName returns Test_Name to caller, intended for use as input to "Tests Data By Test Variable Name".
--              ECR #29188: MT/1-14-2005. 
CREATE PROCEDURE dbo.spXLA_TestVariableName
 	   @Line 	  	  	 Int 	  	  	 --Production Line
 	 , @Location  	  	 Int 	  	  	 --Master Unit or Slave Unit
 	 , @ProductionGroup  	 Int 	  	  	 --Production Group
 	 , @SearchString 	  	 varchar(50) = NULL 	 --Filter For Test_Name
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
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name
  END
Else If @QType = @NoLineHasUnitNoGroupNoString 	  	 --2
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name  END
Else If @QType = @NoLineHasUnitHasGroupNoString 	  	 --3
  BEGIN
        SELECT DISTINCT v.Test_Name
          FROM Variables v
          JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
          JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
         WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
      ORDER BY v.Test_Name
   END
Else If @QType = @NoLineNoUnitNoGroupHasString 	  	 --4
  BEGIN
      SELECT DISTINCT v.Test_Name         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%'
    ORDER BY v.Test_Name
  END
Else If @QType = @NoLineHasUnitNoGroupHasString 	  	 --5
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
         AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name
  END
Else If @QType = @NoLineHasUnitHasGroupHasString 	 --6
  BEGIN
      SELECT DISTINCT v.Test_Name         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name 	 
  END
Else If @QType = @NoLineNoUnitHasGroupNoString 	  	 --13
  BEGIN
      SELECT DISTINCT v.Test_Name         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name 	 
  END
Else If @QType = @NoLineNoUnitHasGroupHasString 	  	 --14
  BEGIN
      SELECT DISTINCT v.Test_Name         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name 	 
  END
Else If @QType = @HasLineNoUnitNoGroupNoString 	  	 --7
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineHasUnitNoGroupNoString 	  	 --8
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineHasUnitHasGroupNoString 	 --9
   BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineNoUnitNoGroupHasString 	  	 --10
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineHasUnitNoGroupHasString 	 --11
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%'
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineHasUnitHasGroupHasString 	 --12
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineNoUnitHasGroupNoString 	  	 --15
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
    ORDER BY v.Test_Name
  END
Else If @QType = @HasLineNoUnitHasGroupHasString 	 --16
  BEGIN
      SELECT DISTINCT v.Test_Name
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
       WHERE v.PU_Id <> 0 AND v.Test_Name IS NOT NULL
         AND v.Test_Name LIKE '%' + LTRIM(RTRIM(@SearchString)) + '%' 
    ORDER BY v.Test_Name
  END
--EndIf
