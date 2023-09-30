-- DESCRIPTION: spXLASearchVariable_Secure is modified from spXLASearchVariable_Expand. 
--              Changes: Only public variables (Group_Id is Null) and selected security variables (Group_Id not Null). 
--              Security variables are retrievable if the user belongs to the specified group or if user belong to 
--              admin group. MT/5-20-2002
CREATE PROCEDURE dbo.spXLASearchVariable_Secure
 	   @Line 	  	  	 Int 	  	 --Production Line
 	 , @Location  	  	 Int 	  	 --Master Unit or Slave Unit
 	 , @ProductionGroup  	 Int 	  	 --Production Group
 	 , @SearchString 	  	 varchar(50) 	 --Var_Desc Filter
 	 , @User_Id 	  	 Int
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Needed to define query types
DECLARE @QType  	  	  	  	  	 TinyInt
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
 	 --General need
DECLARE @Admin 	  	  	  	  	 TinyInt
-- Define query type
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
-- Get Security Memberships of this user; And Verify If User Is In Admin Group
--
CREATE TABLE #User_Security( Group_Id Int)
INSERT INTO #User_Security
  SELECT us.Group_Id FROM User_Security us WHERE us.User_Id = @User_Id
SELECT @Admin = 0
If EXISTS ( SELECT Group_Id FROM #User_Security WHERE Group_Id = 1 ) SELECT @Admin = 1
--EndIf
-- Get Variables Based On The Query Type Figured Previously AND Security Membership of This User
--
If @QType = @NoLineNoUnitNoGroupNoString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitNoGroupNoString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @NoLineHasUnitHasGroupNoString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
   END
Else If @QType = @NoLineNoUnitNoGroupHasString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id         
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%'
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitNoGroupHasString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
         AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @NoLineHasUnitHasGroupHasString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @NoLineNoUnitHasGroupNoString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @NoLineNoUnitHasGroupHasString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	  	 
  END
Else If @QType = @HasLineNoUnitNoGroupNoString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineHasUnitNoGroupNoString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @HasLineHasUnitHasGroupNoString
   BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitNoGroupHasString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineHasUnitNoGroupHasString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location) 
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%'
    ORDER BY v.Var_Desc, pu.PU_Desc
  END
Else If @QType = @HasLineHasUnitHasGroupHasString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id  AND (pu.PU_Id = @Location OR pu.Master_Unit = @Location)
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitHasGroupNoString 	 
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
Else If @QType = @HasLineNoUnitHasGroupHasString
  BEGIN
      SELECT DISTINCT v.Var_Id, v.Var_Desc, v.Eng_Units, pu.PU_Desc, ds.DS_Desc, v.Group_Id
        FROM Variables v
        JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
        JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id AND pug.PUG_Id = @ProductionGroup
        JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id  AND pl.PL_Id = @Line
        JOIN Data_Source ds ON ds.DS_Id = v.DS_Id
        LEFT JOIN #User_Security us ON us.Group_Id = v.Group_Id
       WHERE v.PU_Id <> 0 
         AND (v.Group_Id Is NULL OR v.Group_Id = us.Group_Id OR @Admin = 1)
         AND v.Var_Desc LIKE '%' + ltrim(rtrim(@SearchString)) + '%' 
    ORDER BY v.Var_Desc, pu.PU_Desc  	 
  END
--EndIf
DROP TABLE #User_Security
