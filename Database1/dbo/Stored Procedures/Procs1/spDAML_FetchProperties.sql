Create Procedure dbo.spDAML_FetchProperties
    @PropId 	  	 INT = NULL,
 	 @FamId 	  	 INT = NULL,
 	 @ProdId 	  	 INT = NULL,
 	 @UserId 	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
   @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(1000),
    @SelectClause   VARCHAR(4000),
    @OrderClause 	 VARCHAR(500)
-- All queries check user security
SET @SecurityClause = ' WHERE COALESCE(pps.Access_Level, 3) >= 2 '
--   The Id clause part of the where clause limits by either variable, department, line, unit, or nothing
SELECT @IdClause = 
CASE WHEN (@PropId<>0 AND @PropId IS NOT NULL) THEN 'AND pp.Prop_Id = ' + CONVERT(VARCHAR(10),@PropId) 
   WHEN (@ProdId<>0 AND @ProdId IS NOT NULL) THEN 'AND p.Prod_Id = ' + CONVERT(VARCHAR(10),@ProdId) 
   WHEN (@FamId<>0 AND @FamId IS NOT NULL) THEN 'AND pf.Product_Family_Id = ' + CONVERT(VARCHAR(10),@FamId)
   ELSE ''
END
-- Properties have no options clause
SET @OptionsClause = ''
-- Properties have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
 	 'SELECT 	 DISTINCT 
 	  	  	 PropertyId = pp.Prop_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 CommentId = IsNull(pp.Comment_Id,0),
 	  	  	 ProductFamilyId = IsNull(pp.Product_Family_Id,0),
 	  	  	 ProductFamily = IsNull(pf.Product_Family_Desc,'''')
 	 FROM 	 Product_Properties pp
    LEFT OUTER JOIN Product_Family pf ON pp.Product_Family_Id = pf.Product_Family_Id
    LEFT OUTER JOIN Products p ON pf.Product_Family_Id = p.Product_Family_Id
 	 LEFT OUTER JOIN 	 User_Security pps ON pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- Order Clause
SET @OrderClause = ' ORDER BY pp. Prop_Desc '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
