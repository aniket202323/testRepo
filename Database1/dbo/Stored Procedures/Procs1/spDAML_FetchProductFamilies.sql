Create Procedure dbo.spDAML_FetchProductFamilies
 	 @FamId 	  	 INT = NULL,
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
-- product families have security
SET @SecurityClause = ' WHERE (COALESCE(pfs.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause =
CASE WHEN (@FamId<>0 AND @FamId IS NOT NULL) THEN ' AND pf.Product_Family_Id = ' + CONVERT(VARCHAR(10),@FamId)
   ELSE ''
END
-- Product families have no options clause
SET @OptionsClause = ''
-- Product families have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
 	 'SELECT 	 ProductFamilyId = pf.Product_Family_Id,
 	  	  	 ProductFamily = pf.Product_Family_Desc,
 	  	  	 CommentId = IsNull(pf.Comment_Id,0),
 	  	  	 ExtendedInfo = IsNull(pf.External_Link,'''')
 	 FROM 	  	 Product_Family pf
 	 LEFT JOIN 	 User_Security pfs 	 ON  	 pf.Group_Id = pfs.Group_Id
 	  	  	  	  	  	  	  	  	 AND 	 pfs.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- order clause
SET @OrderClause = ' ORDER BY pf.Product_Family_Desc '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
