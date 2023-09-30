Create Procedure dbo.spDAML_FetchProductionPlanStartEventRecords
    @EventId 	 INT = NULL,
    @UnitId 	  	 INT = NULL,
 	 @LineId 	  	 INT = NULL,
 	 @ProdId 	  	 INT = NULL,
 	 @StartTime 	 DATETIME = NULL,
    @EndTime 	 DATETIME = NULL,
 	 @ProcessOrder 	 VARCHAR(50) = NULL,
    @ProductionPath VARCHAR(50) = NULL,
 	 @UTCOffset 	 VARCHAR(30) = NULL,
 	 @UserId 	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(1000),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(5000),
    @OrderClause 	 VARCHAR(100),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25),
    @STime 	  	  	 VARCHAR(100),
    @ETime 	  	  	 VARCHAR(100)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE (Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN ' AND (pps.PP_Start_Id = ' + CONVERT(VARCHAR(10),@EventId) + ') '
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND (pps.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ') '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND (pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ') '
   WHEN (@ProdId<>0 AND @ProdId IS NOT NULL) THEN 'AND (pp.Prod_Id = ' + CONVERT(VARCHAR(10),@ProdId) + ') '
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProcessOrder<>'' AND @ProcessOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProcessOrder)=0 AND CHARINDEX('_', @ProcessOrder)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order = ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
   ELSE
 	   SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order LIKE ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
END
IF (@ProductionPath<>'' AND @ProductionPath IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductionPath)=0 AND CHARINDEX('_', @ProductionPath)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (pep.Path_Code = ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
   ELSE
 	   SET @OptionsClause = @OptionsClause + ' AND (pep.Path_Code LIKE ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
END
-- The TimeClause determines the interval of time to return
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND (pps.Start_Time < ' + @ETime + ') 
 	  	  	  	  	  AND (pps.End_Time > ' +  @STime + ' OR pps.End_Time is null) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT ProductionPlanStartId = pps.PP_Start_Id,
 	  	  	  	  	 IsProduction = pps.Is_Production,
 	  	  	  	  	 ProductionPlanId = pps.PP_Id,
 	  	  	  	  	 ProcessOrder = IsNull(pp.Process_Order,''''),
 	  	  	  	  	 StartTime = dbo.fnServer_CmnConvertFromDbTime(pps.Start_Time,''UTC'')  ' + ',
 	  	  	  	  	 EndTime = CASE WHEN pps.End_Time IS NULL THEN ' + @MaxTime +
 	 ' 	  	  	  	  	  	  	    ELSE dbo.fnServer_CmnConvertFromDbTime(pps.End_Time,''UTC'')  ' +
 	 ' 	  	  	  	  	  	   END,
 	  	  	  	  	 DepartmentId = d.Dept_Id,
 	  	  	  	  	 Department = d.Dept_Desc,
 	  	  	  	  	 ProductionLineId = pl.PL_Id,
 	  	  	  	  	 ProductionLine = pl.PL_Desc,
 	  	  	  	  	 ProductionUnitId = pu.PU_Id,
 	  	  	  	  	 ProductionUnit = pu.PU_Desc,
 	  	  	  	  	 PathId = IsNull(pep.Path_Id,0),
 	  	  	  	  	 PathCode = IsNull(pep.Path_Code,''''),
 	  	  	  	  	 ProductId = IsNull(p.Prod_Id,0),
 	  	  	  	  	 ProductCode = IsNull(p.Prod_Code,''''),
 	  	  	  	  	 ProductionPlanSetupId = IsNull(pps.PP_Setup_Id,0),
 	  	  	  	  	 CommentId = IsNull(pps.Comment_Id,0)
 	  	  	  	 FROM 	  	  	 Production_Plan_Starts pps
 	  	  	  	 JOIN Production_Plan pp ON pps.PP_Id = pp.PP_Id
 	  	  	  	 JOIN Products p ON pp.Prod_Id = p.Prod_Id
 	  	  	  	 JOIN PrdExec_Paths pep ON pp.Path_Id = pep.Path_Id
 	  	  	  	 JOIN 	 Prod_Units pu 	  	  	  	 ON pps.PU_Id = pu.PU_Id 
 	  	  	  	 JOIN 	 Prod_Lines pl 	  	  	  	 ON pl.PL_Id = pu.PL_Id
 	  	  	  	 JOIN 	 Departments d 	  	  	  	 ON d.Dept_Id = pl.Dept_Id 
 	  	  	  	 LEFT JOIN 	  	 User_Security pls 	  	 ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 	  	  	  	 LEFT JOIN 	  	 User_Security pus 	  	 ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- order clause
SET @OrderClause = ' ORDER BY pps.Start_Time '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause +  @OrderClause )
