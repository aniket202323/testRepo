Create Procedure dbo.spDAML_FetchDepartments
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
SET @SecurityClause = ' WHERE 1=1 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@DeptId<>0 AND @DeptId IS NOT NULL) THEN 'AND d.Dept_Id = ' + CONVERT(VARCHAR(10),@DeptId)
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
'SELECT 	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 CommentId = d.Comment_Id,
 	  	  	 ExtendedInfo = d.Extended_Info
 	 FROM 	  	  	 Departments d '
-- order clause
SET @OrderClause = ' ORDER BY d.Dept_Desc '
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
