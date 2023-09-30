Create Procedure dbo.spDAML_FetchProductionLines
    @LineId 	  	 INT = NULL,
    @DeptId 	  	 INT = NULL,
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
-- production units and lines have security
SET @SecurityClause = ' WHERE (COALESCE(pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
 	 WHEN (@DeptId<>0 AND @DeptId IS NOT NULL) THEN 'AND d.Dept_Id = ' + CONVERT(VARCHAR(10),@DeptId)
    ELSE ''
END
-- Units have no options clause
SET @OptionsClause = ''
-- Units have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT 	  	 ProductionLineId = pl.PL_Id,
 	  	  	 ProductionLine 	  	 = pl.pl_desc, 
 	  	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 CommentId = pl.Comment_Id,
 	  	  	 ExtendedInfo = pl.Extended_Info
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	 ON d.Dept_Id = pl.Dept_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 pl.PL_Id > 0
 	 LEFT JOIN 	 User_Security pls 	 ON pl.Group_Id = pls.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 pls.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + ' '
-- order clause
SET @OrderClause = ' ORDER BY d.Dept_Desc, pl.PL_Desc '
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
