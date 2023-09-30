Create Procedure dbo.spDAML_FetchProductionUnits
    @UnitId 	  	 INT = NULL,
    @DeptId 	  	 INT = NULL,
 	 @LineId 	  	 INT = NULL,
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
SET @SecurityClause = ' WHERE (COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
    WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
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
'SELECT 	 ProductionUnitId 	  	 = pu.PU_Id,
 	  	  	 ProductionUnit 	  	 = pu.pu_desc,
 	  	  	 ProductionLineId 	 = pl.PL_Id,
 	  	  	 ProductionLine 	  	 = pl.pl_desc, 
 	  	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 MasterUnitId 	  	 = CASE 
 	  	  	  	  	  	  	  	  	  	 WHEN pu.Master_Unit IS NULL THEN pu.PU_Id 
 	  	  	  	  	  	  	  	  	  	 ELSE pu.Master_Unit
 	  	  	  	  	  	  	  	  	 END,
 	  	  	 MasterUnit 	  	  	 = 	 CASE 
 	  	  	  	  	  	  	  	  	  	 WHEN pu.Master_Unit IS NULL THEN pu.pu_desc 
 	  	  	  	  	  	  	  	  	  	 ELSE pu2.PU_Desc
 	  	  	  	  	  	  	  	  	 END,
 	  	  	 IsMasterUnit 	  	 = 	 CASE 
 	  	  	  	  	  	  	  	  	  	 WHEN pu.Master_Unit IS NULL THEN 1 
 	  	  	  	  	  	  	  	  	  	 ELSE 0 
 	  	  	  	  	  	  	  	  	 END,
 	  	  	 HasProductionEvents 	 = (SELECT COUNT(EC_Id) FROM Event_Configuration WHERE PU_Id = pu.PU_Id AND ET_Id = 1),
 	  	  	 ExtendedInfo 	  	 = pu.Extended_Info,
 	  	  	 CommentId 	  	  	 = pu.Comment_Id
 	 FROM 	 Departments d
 	 INNER 	 JOIN 	 Prod_Lines pl 	  	 ON 	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0 
 	 INNER 	 JOIN 	 Prod_Units pu 	  	 ON 	  	 pl.pl_id = pu.pl_id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0 
 	 LEFT 	 JOIN 	 Prod_Units pu2 	  	 ON 	  	 pu2.PU_Id = pu.Master_Unit
 	 LEFT 	 JOIN 	 User_Security pls 	 ON 	  	 pl.Group_Id = pls.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pls.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + ' ' + ' 
 	 LEFT 	 JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pus.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + ' '  	 
-- order clause
SET @OrderClause = ' ORDER BY pl.PL_Desc, pu.PU_Order '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
