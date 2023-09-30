Create Procedure dbo.spDAML_FetchWasteEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @EventType  VARCHAR(100) = NULL,
  @EventName VARCHAR(25) = NULL,
  @ProdEventId INT = NULL,
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
  @TimeClause  VARCHAR(500),
  @WhereClause VARCHAR(2000),
  @SelectClause   VARCHAR(5000),
  @FromClause  VARCHAR(5000),
  @OrderClause VARCHAR(100),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(25),
  @ETime   VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Setup Top Clause if needed
SET @TOPClause = ''
if (@MaxRecords is not null) SET @TOPClause = ' TOP ' + Convert(VARCHAR(15), @MaxRecords)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE (COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN ' AND (wed.WED_Id = ' + CONVERT(VARCHAR(10),@EventId) + ') '
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND (wed.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ') '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN ' AND (pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ') '
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@EventName<>'' AND @EventName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @EventName)=0 AND CHARINDEX('_', @EventName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (e.Event_Num = ''' + CONVERT(VARCHAR(25),@EventName) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (e.Event_Num LIKE ''' + CONVERT(VARCHAR(25),@EventName) + ''') '
END   
IF (@EventType<>'' AND @EventType IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @EventType)=0 AND CHARINDEX('_', @EventType)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (wet.WET_Name = ''' + CONVERT(VARCHAR(100),@EventType) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (wet.WET_Name LIKE ''' + CONVERT(VARCHAR(100),@EventType) + ''') '
END
-- The TimeClause determines the interval of time to return
-- Timestamp must be less than or equal IntervalEnd
-- Timestamp must be greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND (wed.Timestamp > ' + @STime + ' AND wed.TimeStamp <= ' + @ETime + ') '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
' SELECT' + @TOPClause + ' WasteEventId = wed.WED_Id,
   DepartmentId = d.Dept_Id,
   Department = d.Dept_Desc,
   ProductionLineId = pl.PL_Id,
   ProductionLine = pl.PL_Desc,
   ProductionUnitId = wed.PU_Id,
   ProductionUnit = pu.PU_Desc, 
   WasteEventTypeId = IsNull(wed.WET_Id,0),
   WasteEventType = IsNull(wet.WET_Name,''''), 
   FaultId = IsNull(wed.WEFault_Id,0),
   FaultName = IsNull(wef.WEFault_Name,''''),
   SourceDepartment = IsNull(sd.Dept_Desc,''''),
   SourceProductionLine = IsNull(spl.PL_Desc,''''),
   SourceProductionUnitId = IsNull(wed.Source_PU_Id,0),
   SourceProductionUnit = IsNull(spu.PU_Desc,''''),
   EventId = IsNull(wed.Event_Id,0),
   EventName = IsNull(e.Event_Num,''''), 
   EventConfigurationId = IsNull(wed.EC_Id,0),
   WasteEventTime = dbo.fnServer_CmnConvertFromDbTime(wed.Timestamp,''UTC'')  ' +  ', 
   MeasureId = IsNull(wed.WEMT_Id,0),
   Measurement = IsNull(wem.WEMT_Name,''''), 
   Amount = IsNull(wed.Amount,0),
   ReasonTreeDataId = IsNull(wed.Event_Reason_Tree_Data_Id,0),
   Cause1Id = IsNull(wed.Reason_Level1,0),
   Cause1 = IsNull(rl1.Event_Reason_Name,''''),
   Cause2Id = IsNull(wed.Reason_Level2,0),
   Cause2 = IsNull(rl2.Event_Reason_Name,''''),
   Cause3Id = IsNull(wed.Reason_Level3,0),
   Cause3 = IsNull(rl3.Event_Reason_Name,''''),
   Cause4Id = IsNull(wed.Reason_Level4,0),
   Cause4 = IsNull(rl4.Event_Reason_Name,''''),
   CauseCommentId = IsNull(wed.Cause_Comment_Id,0),
   Action1Id = IsNull(wed.Action_Level1,0),
   Action1 = IsNull(al1.Event_Reason_Name,''''),
   Action2Id = IsNull(wed.Action_Level2,0),
   Action2 = IsNull(al2.Event_Reason_Name,''''),
   Action3Id = IsNull(wed.Action_Level3,0),
   Action3 = IsNull(al3.Event_Reason_Name,''''),
   Action4Id = IsNull(wed.Action_Level4,0),
   Action4 = IsNull(al4.Event_Reason_Name,''''),
   ActionCommentId = IsNull(wed.Action_Comment_Id,0),
   ResearchOpenDate = CASE WHEN wed.Research_Open_Date IS NULL THEN ' + @MaxTime +
                    ' ELSE dbo.fnServer_CmnConvertFromDbTime(wed.Research_Open_Date,''UTC'')  ' + 
                    ' END,
   ResearchCloseDate = CASE WHEN wed.Research_Close_Date IS NULL THEN ' + @MaxTime +
                     ' ELSE dbo.fnServer_CmnConvertFromDbTime(wed.Research_Close_Date,''UTC'')  ' + 
                     ' END,
   ResearchStatusId = IsNull(wed.Research_Status_Id,0),
   ResearchStatus = IsNull(rs.Research_Status_Desc,''''),
   ResearchUserId = IsNull(wed.Research_User_Id,0),
   ResearchUserName = IsNull(ru.UserName,''''),
   ResearchCommentId = IsNull(wed.Research_Comment_Id,0),
   UserGeneral1 = IsNull(wed.User_General_1,''''),
   UserGeneral2 = IsNull(wed.User_General_2,''''),
   UserGeneral3 = IsNull(wed.User_General_3,''''),
   UserGeneral4 = IsNull(wed.User_General_4,''''),
   UserGeneral5 = IsNull(wed.User_General_5,''''),
   ESignatureId = IsNull(wed.Signature_Id,0),
   UserId = IsNull(wed.User_Id,0) '
SET @FromClause = ' FROM Departments d
 JOIN  Prod_Lines pl ON d.Dept_Id = pl.Dept_Id
 JOIN  Prod_Units pu ON pl.PL_Id = pu.PL_Id
 JOIN  Waste_Event_Details wed ON pu.PU_Id = wed.PU_Id
 LEFT JOIN Waste_Event_Type wet ON wed.WET_Id = wet.WET_Id
 LEFT JOIN Waste_Event_Meas wem ON wed.WEMT_Id = wem.WEMT_Id 
 LEFT JOIN   Waste_Event_Fault wef ON wef.WEFault_Id = wed.WEFault_Id        
 LEFT JOIN Prod_Units spu ON wed.Source_PU_Id = spu.PU_Id       
 LEFT JOIN Prod_Lines spl ON spu.PL_Id = spl.PL_Id 
 LEFT JOIN Departments sd ON sd.Dept_Id = spl.Dept_Id        
 JOIN  Users u ON wed.User_Id = u.User_id         
 LEFT JOIN Events e ON wed.Event_Id = e.Event_Id        
 LEFT JOIN Event_Reasons rl1 ON wed.Reason_Level1 = rl1.Event_Reason_Id   
 LEFT JOIN Event_Reasons rl2 ON wed.Reason_Level2 = rl2.Event_Reason_Id   
 LEFT JOIN Event_Reasons rl3 ON wed.Reason_Level3 = rl3.Event_Reason_Id
 LEFT JOIN Event_Reasons rl4 ON wed.Reason_Level4 = rl4.Event_Reason_Id   
 LEFT JOIN Event_Reasons al1 ON wed.Action_Level1 = al1.Event_Reason_Id   
 LEFT JOIN Event_Reasons al2 ON wed.Action_Level2 = al2.Event_Reason_Id   
 LEFT JOIN Event_Reasons al3 ON wed.Action_Level3 = al3.Event_Reason_Id   
 LEFT JOIN Event_Reasons al4 ON wed.Action_Level4 = al4.Event_Reason_Id   
 LEFT JOIN Research_Status rs ON wed.Research_Status_Id = rs.Research_Status_Id 
 LEFT JOIN Users ru ON wed.Research_User_Id = ru.User_Id      
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- Add criteria for Production Event Search
IF (@ProdEventId IS NOT NULL) BEGIN
 	 SET @FromClause = @FromClause + ' JOIN Events evt on evt.Event_Id = ud.Event_Id'
 	 SET @WhereClause = @WhereClause + ' AND evt.Event_Id = ' + CONVERT(VARCHAR(10),@ProdEventId)
END
-- order clause
SET @OrderClause = ' ORDER BY wed.Timestamp '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @FromClause + @WhereClause + @OrderClause)
