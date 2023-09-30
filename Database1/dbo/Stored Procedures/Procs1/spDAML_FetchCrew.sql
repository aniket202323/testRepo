Create Procedure dbo.spDAML_FetchCrew
    @CrewId 	  	 INT = NULL,
    @UnitId 	  	 INT = NULL,
 	 @TimeStamp 	 DATETIME = NULL,
 	 @UserId 	  	 INT 	 = NULL,
 	 @UTCOffset 	 VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(200),
 	 @WhereClause 	 VARCHAR(1000),
    @SelectClause   VARCHAR(4000),
    @OrderClause 	 VARCHAR(100),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- The variable, production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@CrewId<>0 AND @CrewId IS NOT NULL) THEN ' AND cs.CS_Id = ' + CONVERT(VARCHAR(10),@CrewId)
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   ELSE ''
END
-- Crew records have no options
SET @OptionsClause = ''
-- The TimeStamp detemines the interval of time to return
-- EventStartTime must be strictly less than TimeStamp
-- EventEndTime must be greater than or equal to TimeStamp
SET @TimeClause = ' AND 	 cs.Start_Time < ''' + CONVERT(VARCHAR(100),@TimeStamp,21) + ''' 
 	  	  	  	     AND (cs.End_Time >= ''' + CONVERT(VARCHAR(100),@TimeStamp,21) + ''' 
 	  	  	  	       OR cs.End_Time IS NULL)'
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 CrewId 	  	  	  	 = cs.CS_Id,
 	  	  	 CrewDescription 	  	 = cs.Crew_Desc,
 	  	  	 ShiftDescription 	 = cs.Shift_Desc,
 	  	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 ProductionLineId 	 = pl.PL_Id,
 	  	  	 ProductionLine 	  	 = pl.PL_Desc,
 	  	  	 ProductionUnitId 	 = cs.PU_Id,
 	  	  	 ProductionUnit 	  	 = pu.PU_Desc,
 	  	  	 StartTime 	  	  	 = dbo.fnServer_CmnConvertFromDbTime(cs.Start_Time,''UTC'')  '  + ', 
 	  	  	 EndTime 	  	  	  	 = CASE WHEN cs.End_Time IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	 '  ELSE dbo.fnServer_CmnConvertFromDbTime(cs.End_Time,''UTC'')  ' +
 	  	  	  	 ' 	  	  	  	   END, 
 	  	  	 CommentId 	  	  	 = IsNull(cs.Comment_Id,0)
 	 FROM 	 Departments d
 	 JOIN 	 Prod_Lines pl 	  ON d.Dept_Id = pl.Dept_Id
 	 JOIN 	 Prod_Units pu  	  ON 	 pl.PL_Id = pu.PL_Id
 	 JOIN 	 Crew_Schedule cs ON 	 pu.PU_Id = cs.PU_Id 
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) +
' 	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 	 
-- order clause
SET @OrderClause = ' ORDER BY cs.Shift_Desc, cs.Crew_Desc  '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
