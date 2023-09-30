Create Procedure dbo.spDAML_FetchGenealogyEventRecords
  @ComponentId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @EventName  VARCHAR(50) = NULL,
  @Levels     INT = NULL,
  @Direction  INT = NULL,
  @ShowAll    BIT = 1,
  @ParentProdEventId INT = NULL,
  @ChildProdEventId INT = NULL,
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
  @OrderClause VARCHAR(500),
  @GroupClause VARCHAR(500),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @EventId  INT,
  @CurrentLevel INT
CREATE TABLE #ResultComponents (
 Component_Id INT,
 Event_id   INT,
 LevelNumber  INT
)
DECLARE @SearchEvents TABLE (
 Event_Id   INT
)
-- Find components
IF @Levels = 0 SELECT @Levels = 200
IF @Direction Is NULL Select @Direction = 0
IF (@ComponentId IS NOT NULL) BEGIN
 SELECT @EventId = Event_Id
  FROM Event_Components
  WHERE Component_Id = @ComponentId
  SET @Levels = 1
END
ELSE IF (@UnitId IS NOT NULL) BEGIN
 SELECT TOP 1 @EventId = Event_Id 
  FROM Events 
  WHERE PU_Id = @UnitId
   AND  Event_Num = @EventName
END
ELSE BEGIN
 SELECT TOP 1 @EventId = Event_Id 
  FROM Events 
   JOIN Prod_Units ON Events.PU_Id = Prod_Units.PU_Id
  WHERE Prod_Units.PL_Id = @LineId
   AND Event_Num = @EventName
END
INSERT INTO @SearchEvents (Event_Id)
 VALUES (@EventId)
SELECT @CurrentLevel = 1
-- Find child events
IF @Direction IN (0,1)
BEGIN
 WHILE (SELECT COUNT(*) FROM @SearchEvents) > 0 AND @CurrentLevel <= @Levels
 BEGIN
  INSERT INTO #ResultComponents (Component_id, Event_Id, LevelNumber)
   SELECT Component_Id, Event_Id, @CurrentLevel 
    FROM Event_Components
    WHERE Source_Event_Id IN (SELECT Event_Id FROM @SearchEvents)
  DELETE FROM @SearchEvents
  INSERT INTO @SearchEvents (Event_id)
   SELECT Event_id 
    FROM #ResultComponents  
    WHERE LevelNumber = @CurrentLevel
  SELECT @CurrentLevel = @CurrentLevel + 1
 END  
END
DELETE @SearchEvents
-- find parent events
INSERT INTO @SearchEvents (Event_Id)
 VALUES (@EventId)
SELECT @CurrentLevel = -1
--Search Backward In Genealogy
IF @Direction IN (0,2)
BEGIN
 WHILE (SELECT COUNT(*) FROM @SearchEvents) > 0 AND @CurrentLevel >= (@Levels * -1)
 BEGIN
  INSERT INTO #ResultComponents  (Component_id, Event_Id, LevelNumber)
   SELECT Component_Id, Source_Event_Id, @CurrentLevel 
    FROM Event_Components
    WHERE Event_Id IN (SELECT Event_Id FROM @SearchEvents)
  DELETE FROM @SearchEvents
  INSERT INTO @SearchEvents (Event_id)
   SELECT Event_Id 
    FROM #ResultComponents 
    WHERE LevelNumber = @CurrentLevel
  SELECT @CurrentLevel = @CurrentLevel - 1
 END  
END
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Setup Top Clause if needed
SET @TOPClause = ''
if (@MaxRecords is not null) SET @TOPClause = ' TOP ' + Convert(VARCHAR(15), @MaxRecords)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE (Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = ''
-- options clause
SET @OptionsClause = ' AND rc.Event_Id <> ' + CONVERT(VARCHAR(10),@EventId) 
IF (@ComponentId IS NOT NULL) SET @OptionsClause = @OptionsClause + ' AND ec.Component_Id = ' + CONVERT(VARCHAR(10),@ComponentId)
-- Add criteria for Production Event Search
IF (@ParentProdEventId IS NOT NULL) SET @OptionsClause = @OptionsClause + ' AND e1.Event_Id = ' + CONVERT(VARCHAR(10),@ParentProdEventId)
IF (@ChildProdEventId IS NOT NULL)  SET @OptionsClause = @OptionsClause + ' AND e2.Event_Id = ' + CONVERT(VARCHAR(10),@ChildProdEventId)
-- The TimeClause determines the interval of time to return
SET @TimeClause = ' '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
Set @SelectClause = 'SELECT' + @TOPClause + ' GenealogyEventId = ec.Component_Id,
   ParentGenealogyEventId = IsNull(ec.Parent_Component_Id,0),
   ParentDepartmentId = IsNull(pl1.Dept_Id,0),
   ParentDepartment = IsNull(d1.Dept_Desc,''''),
   ParentProductionLineId = IsNull(pu1.pl_Id,0),
   ParentProductionLine = IsNull(pl1.pl_desc,''''),
   ParentProductionUnitId = IsNull(e1.pu_id,0),
   ParentProductionUnit = IsNull(pu1.pu_desc, ''''),
   ParentEventId = ec.Source_Event_id,
   ParentEventName = e1.Event_Num, 
   ParentEventSubtypeId = IsNull(ec1.Event_Subtype_Id,0),
   ParentEventSubtype = IsNull(es1.Event_Subtype_Desc,''''), 
   ChildDepartmentId = pl2.Dept_Id,
   ChildDepartment = d2.Dept_Desc,
   ChildProductionLineId = pu2.pl_id,
   ChildProductionLine = pl2.pl_desc,
   ChildProductionUnitId = e2.pu_id,
   ChildProductionUnit = pu2.pu_desc, 
   ChildEventId = ec.Event_id,
   ChildEventName = e2.Event_Num, 
   ChildEventSubtypeId = IsNull(ec2.Event_Subtype_Id,0),
   ChildEventSubtype = IsNull(es2.Event_Subtype_Desc,''''), 
   ProductionInputId = ISNull(ec.PEI_Id,0),
   InputName = IsNull(pei.Input_Name,''''), '
IF ( @ShowAll = 1 ) Begin
 Set @SelectClause = @SelectClause + ' DimensionX = IsNull(ec.Dimension_X,0), 
   DimensionY = IsNull(ec.Dimension_Y,0),
   DimensionZ = IsNull(ec.Dimension_Z,0),
   DimensionA = IsNull(ec.Dimension_A,0),
   Level = rc.LevelNumber,
   ExtendedInfo = IsNull(ec.Extended_Info,0),
   StartCoordinateX = IsNull(ec.Start_Coordinate_X,0),
   StartCoordinateY = IsNull(ec.Start_Coordinate_Y,0),
   StartCoordinateZ = IsNull(ec.Start_Coordinate_Z,0),
   StartCoordinateA = IsNull(ec.Start_Coordinate_A,0),
   StartTime = CASE WHEN ec.Start_Time IS NULL THEN ' + @MinTime +
             ' ELSE dbo.fnServer_CmnConvertFromDbTime(ec.Start_Time,''UTC'')  ' + 
             ' END,
   EndTime = CASE WHEN ec.TimeStamp IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(ec.TimeStamp,''UTC'') ' + 
           ' END, 
   EntryOn = CASE WHEN ec.Entry_On IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(ec.Entry_On,''UTC'')  ' + 
           ' END, 
   ReportAsConsumption = ec.Report_As_Consumption,
   ESignatureId = IsNull(ec.Signature_Id,0)'
End 
Else Begin
 Set @SelectClause = @SelectClause + ' DimensionX = SUM(ec.Dimension_X), 
   DimensionY = SUM(ec.Dimension_Y),
   DimensionZ = SUM(ec.Dimension_Z),
   DimensionA = SUM(ec.Dimension_A),
   Level = rc.LevelNumber,
   ExtendedInfo = NULL,
   StartCoordinateX = NULL,
   StartCoordinateY = NULL,
   StartCoordinateZ = NULL,
   StartCoordinateA = NULL,
   StartTime = MIN(ec.Start_Time),
   EndTime = MAX(ec.Timestamp), 
   EntryOn = MAX(ec.Entry_On), 
   ReportAsConsumption = ec.Report_As_Consumption,
   ESignatureId = Max(ec.Signature_Id)'
End
Set @SelectClause = @SelectClause +  ' FROM #ResultComponents rc
   JOIN Event_Components ec ON ec.Component_Id = rc.Component_Id
   JOIN Events e1 ON e1.Event_id = ec.Source_Event_id 
   LEFT JOIN Event_Configuration ec1 ON e1.PU_Id = ec1.PU_Id AND ec1.ET_Id = 1
   LEFT JOIN Event_SubTypes es1 ON ec1.Event_Subtype_Id = es1.Event_Subtype_Id
   LEFT JOIN PrdExec_Inputs pei ON ec.PEI_Id = pei.PEI_Id
   JOIN Prod_Units pu1 ON pu1.PU_id = e1.PU_Id
   JOIN Prod_Lines pl1 ON pl1.pl_id = pu1.PL_Id
   JOIN Departments d1 ON pl1.Dept_Id = d1.Dept_Id
   JOIN Events e2 ON e2.Event_id = ec.Event_id
   LEFT JOIN Event_Configuration ec2 ON e2.PU_Id = ec2.PU_Id AND ec2.ET_Id = 1
   LEFT JOIN Event_SubTypes es2 ON ec2.Event_Subtype_Id = es2.Event_Subtype_Id
   JOIN Prod_Units pu2 ON pu2.PU_id = e2.PU_Id
   JOIN Prod_Lines pl2 ON pl2.PL_Id = pu2.PL_Id
   JOIN Departments d2 ON pl2.Dept_Id = d2.Dept_Id
   LEFT JOIN User_Security pls ON pl1.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) +
 ' LEFT JOIN User_Security pus ON pu1.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 
-- group clause
Set @GroupClause = 'GROUP BY ec.Component_Id, pl1.Dept_Id, d1.Dept_Desc,pu1.pl_Id,pl1.pl_desc,e1.pu_id,pu1.pu_desc,
  ec.Source_Event_id,e1.Event_Num, ec1.Event_Subtype_Id,es1.Event_Subtype_Desc, 
  ec.Parent_Component_Id,
  pl2.Dept_Id,d2.Dept_Desc,pu2.pl_id,pl2.pl_desc,e2.pu_id,pu2.pu_desc, 
  ec.Event_id,e2.Event_Num, ec2.Event_Subtype_Id,es2.Event_Subtype_Desc,
  ec.PEI_Id, pei.Input_Name, rc.LevelNumber, ec.Report_As_Consumption '
SET @OrderClause = 'ORDER BY rc.LevelNumber'
-- SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause, gc=@GroupClause -- For debugging
if (@ShowAll = 1)
 EXECUTE (@SelectClause + @WhereClause + @OrderClause)
else
 EXECUTE (@SelectClause + @WhereClause + @GroupClause)
DROP TABLE #ResultComponents
