Create Procedure dbo.spDAML_FetchProductChanges
    @EventId 	 INT = NULL,
 	 @DeptId 	  	 INT = NULL,
 	 @LineId 	  	 INT = NULL,
 	 @UnitId 	  	 INT = NULL,
 	 @StartTime 	 DATETIME = NULL,
 	 @EndTime 	 DATETIME = NULL,
 	 @UserId 	  	 INT 	 = NULL,
    @UTCOffset 	 VARCHAR(30) = NULL,
    @MaxRecords INT = NULL
AS
-- Local variables
DECLARE 	 
    @TOPClause VARCHAR(20),
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(2000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(4000),
    @SelectClause   VARCHAR(4000),
    @OrderClause 	 VARCHAR(100),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25),
    @STime 	  	  	 VARCHAR(25),
    @ETime 	  	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Setup Top Clause if needed
SET @TOPClause = ''
if (@MaxRecords is not null) SET @TOPClause = ' TOP ' + Convert(VARCHAR(15), @MaxRecords)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND ps.Start_Id = ' + CONVERT(VARCHAR(10),@EventId) 
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   WHEN (@DeptId<>0 AND @DeptId IS NOT NULL) THEN 'AND d.Dept_Id = ' + CONVERT(VARCHAR(10),@DeptId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
-- The TimeClause determines the interval of time to return
-- EventStartTime must be strictly less than IntervalEnd
-- EventEndTime must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND ps.Start_Time < ' + @ETime + 
 	  	  	  	 ' 	 AND 	 (ps.End_Time > ' + @STime + ' OR ps.End_Time IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT' + @TOPClause + ' 	  	 ProductChangeId = ps.Start_Id,
 	  	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 ProductionLineId 	 = pl.PL_Id,
 	  	  	 ProductionLine 	  	 = pl.PL_Desc,
 	  	  	 ProductionUnitId 	 = ps.PU_Id,
 	  	  	 ProductionUnit 	  	 = pu.PU_Desc,
 	  	  	 StartTime 	  	  	 = dbo.fnServer_CmnConvertFromDbTime(ps.Start_Time,''UTC'') , 
 	  	  	 EndTime 	  	  	  	 = CASE 	 WHEN ps.End_Time IS NULL THEN ' + @MaxTime +
    '                    	  	  	  	 ELSE dbo.fnServer_CmnConvertFromDbTime(ps.End_Time,''UTC'') ' + 
 	 ' 	  	  	  	  	  	  	   END, 
 	  	  	 Confirmed 	  	  	 = ps.Confirmed, 
 	  	  	 ProductId 	  	  	 = ps.Prod_Id,
 	  	  	 ProductCode 	  	  	 = IsNull(p.Prod_Code,''''),
 	  	  	 CommentId 	  	  	 = IsNull(ps.Comment_Id,0),
 	  	  	 EventSubTypeId 	  	 = IsNull(ps.Event_Subtype_Id,0),
            ESignatureId 	  	 = IsNull(ps.Signature_Id,0),
 	  	  	 UserId 	  	  	  	 = IsNull(ps.User_Id,0),
 	  	  	 SecondUserId 	  	 = IsNull(ps.Second_User_Id,0)
 	 FROM 	  	 Departments d
 	 JOIN 	  	 Prod_Lines pl 	  	  	 ON 	 d.Dept_Id = pl.Dept_Id AND pl.PL_Id > 0
 	 JOIN 	  	 Prod_Units pu 	  	  	 ON 	 pl.PL_Id = pu.PL_Id AND pu.PU_Id > 0 
 	 JOIN 	  	 Production_Starts ps 	 ON  	 ps.PU_Id = pu.PU_Id
 	 JOIN 	  	 Products p  	  	  	  	 ON  	 ps.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	 pl.Group_Id = pls.Group_Id 	 
 	  	  	  	  	  	  	  	  	  	  	 AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + 	  	  	 
  ' LEFT JOIN 	 User_Security pus 	  	 ON 	 pu.Group_Id = pus.Group_Id 
 	  	  	  	  	  	  	  	  	  	     AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- product changes have no order clause
SET @OrderClause = ' ORDER BY ps.Start_Time '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
