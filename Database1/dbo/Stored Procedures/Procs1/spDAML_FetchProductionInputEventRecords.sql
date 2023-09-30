Create Procedure dbo.spDAML_FetchProductionInputEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @InputName VARCHAR(50) = NULL,
  @InputPosition VARCHAR(50) = NULL,
  @UTCOffset VARCHAR(30) = NULL,
  @UserId  INT = NULL,
  @MaxRecords INT = NULL
AS
-- Local variables
DECLARE 
  @TOPClause VARCHAR(20),
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(1000),
  @TimeClause  VARCHAR(1000),
  @WhereClause VARCHAR(2000),
  @SelectClause   VARCHAR(5000),
  @OrderClause VARCHAR(100),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(100),
  @ETime   VARCHAR(100)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Setup Top Clause if needed
SET @TOPClause = ''
if (@MaxRecords is not null) SET @TOPClause = ' TOP ' + Convert(VARCHAR(15), @MaxRecords)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN ' AND (peie.Input_Event_Id = ' + CONVERT(VARCHAR(10),@EventId) + ') '
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND (pei.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ') '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND (pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ') '
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@InputName<>'' AND @InputName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @InputName)=0 AND CHARINDEX('_', @InputName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (pei.Input_Name = ''' + CONVERT(VARCHAR(50),@InputName) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (pei.Input_Name LIKE ''' + CONVERT(VARCHAR(50),@InputName) + ''') '
END
IF (@InputPosition<>'' AND @InputPosition IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @InputPosition)=0 AND CHARINDEX('_', @InputPosition)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (peip.PEIP_Desc = ''' + CONVERT(VARCHAR(50),@InputPosition) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (peip.PEIP_Desc LIKE ''' + CONVERT(VARCHAR(50),@InputPosition) + ''') '
END
-- The TimeClause determines the interval of time to return
SET @TimeClause = ' '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT' + @TOPClause + ' ProductionInputEventId = peie.Input_Event_Id,
   ProductionInputId = pei.PEI_Id,
   InputName = pei.Input_Name, 
   ProductionInputPositionId = peie.PEIP_Id,
   InputPosition = peip.PEIP_Desc, 
   DepartmentId = d.Dept_Id,
   Department = d.Dept_Desc,
   ProductionLineId = pl.PL_Id,
   ProductionLine = pl.PL_Desc,
   ProductionUnitId = pei.PU_Id,
   ProductionUnit = pu.PU_Desc, 
   SourceEventId = IsNull(peie.Event_Id,0),
   SourceEventName = IsNull(e.Event_Num, ''''),
   SourceDepartmentId = IsNull(srcd.Dept_Id,0),
   SourceDepartment = IsNull(srcd.Dept_Desc,''''),
   SourceProductionLineId = IsNull(srcpl.PL_Id,0),
   SourceProductionLine = IsNull(srcpl.PL_Desc,''''),
   SourceProductionUnitId = IsNull(e.PU_Id,0),
   SourceProductionUnit = IsNull(srcpu.PU_Desc,''''),
   Timestamp = peie.TimeStamp, 
   DimensionX = IsNull(peie.Dimension_X,0), 
   DimensionY = IsNull(peie.Dimension_Y,0), 
   DimensionZ = IsNull(peie.Dimension_Z,0), 
   DimensionA = IsNull(peie.Dimension_A,0), 
   Unloaded = IsNull(peie.Unloaded,0),
   CommentId = IsNull(peie.Comment_Id,0),
   EntryOn = CASE WHEN peie.Entry_On IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(peie.Entry_On,''UTC'')  ' + 
           ' END,
   ESignatureId = IsNull(peie.Signature_Id, 0)
  FROM Departments d
  JOIN Prod_Lines pl ON d.Dept_Id = pl.Dept_Id
  JOIN Prod_Units pu ON pl.PL_Id = pu.PL_Id
  JOIN PrdExec_Inputs pei ON pu.PU_Id = pei.PU_Id
  JOIN PrdExec_Input_Event peie ON pei.PEI_Id = peie.PEI_Id 
  JOIN PrdExec_Input_Positions peip ON peip.PEIP_Id = peie.PEIP_Id
  LEFT JOIN Events e ON peie.Event_Id = e.Event_Id
  LEFT JOIN Prod_Units srcpu ON e.PU_Id = srcpu.PU_Id
  LEFT JOIN Prod_Lines srcpl ON srcpu.PL_Id = srcpl.PL_Id
  LEFT JOIN Departments srcd ON srcpl.Dept_Id = srcd.Dept_Id
  LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
  LEFT JOIN User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- order clause
SET @OrderClause = ' ORDER BY pl.PL_Desc, pu.PU_Order, pei.Input_Order, peip.PEIP_Desc '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause )
