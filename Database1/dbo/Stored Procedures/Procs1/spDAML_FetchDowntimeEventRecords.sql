Create Procedure dbo.spDAML_FetchDowntimeEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @UTCOffset VARCHAR(30) = NULL,
  @UserId  INT = NULL,
  @MaxRecords INT = NULL
AS
-- Local variables
DECLARE 
  @TOPClause VARCHAR(20),
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(2000),
  @TimeClause  VARCHAR(500),
  @WhereClause VARCHAR(3000),
  @SelectClause   VARCHAR(5000),
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
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND ted.TEDet_Id = ' + CONVERT(VARCHAR(10),@EventId) 
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND ted.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- Downtime events have no options
SET @OptionsClause = ''
-- The TimeClause determines the interval of time to return
-- EventStartTime must be strictly less than IntervalEnd
-- EventEndTime must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND ted.Start_Time < ' + @ETime + 
                  ' AND (ted.End_Time > ' + @STime + ' OR ted.End_Time IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
' SELECT' + @TOPClause + ' DowntimeEventId = ted.TEDet_Id,
   DepartmentId = d.Dept_Id,
   Department = d.Dept_Desc,
   ProductionLineId = pl.PL_Id,
   ProductionLine = pl.PL_Desc, 
   ProductionUnitId = ted.PU_Id,
   ProductionUnit = pu.PU_Desc, 
   StartTime = dbo.fnServer_CmnConvertFromDbTime(ted.Start_Time,''UTC'')  ' +  ', 
   EndTime = CASE WHEN ted.End_Time IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(ted.End_Time,''UTC'')  ' + 
           ' END, 
   Duration  = CASE WHEN ted.End_Time IS NULL THEN 0
               ELSE DATEDIFF(SECOND, ted.Start_Time, ted.End_Time) / 60.0
               END,
   FaultId = IsNull(ted.TEFault_Id,0),
   FaultName = IsNull(tef.TEFault_Name,''''),
   ReasonTreeDataId = IsNull(ted.Event_Reason_Tree_Data_Id,0),
   Cause1Id = IsNull(ted.Reason_Level1,0),
   Cause1 = IsNull(rl1.Event_Reason_Name,''''),
   Cause2Id = IsNull(ted.Reason_Level2,0),
   Cause2 = IsNull(rl2.Event_Reason_Name,''''),
   Cause3Id = IsNull(ted.Reason_Level3,0),
   Cause3 = IsNull(rl3.Event_Reason_Name,''''),
   Cause4Id = IsNull(ted.Reason_Level4,0),
   Cause4 = IsNull(rl4.Event_Reason_Name,''''),
   CauseCommentId = IsNull(ted.Cause_Comment_Id,0),
   Action1Id = IsNull(ted.Action_Level1,0),
   Action1 = IsNull(al1.Event_Reason_Name,''''),
   Action2Id = IsNull(ted.Action_Level2,0),
   Action2 = IsNull(al2.Event_Reason_Name,''''),
   Action3Id = IsNull(ted.Action_Level3,0),
   Action3 = IsNull(al3.Event_Reason_Name,''''),
   Action4Id = IsNull(ted.Action_Level4,0),
   Action4 = IsNull(al4.Event_Reason_Name,''''),
   ActionCommentId = IsNull(ted.Action_Comment_Id,0),
   ResearchOpenDate = CASE WHEN ted.Research_Open_Date IS NULL THEN ' + @MaxTime +
                    ' ELSE dbo.fnServer_CmnConvertFromDbTime(ted.Research_Open_Date,''UTC'')  ' + 
                    ' END,
    ResearchCloseDate = CASE WHEN ted.Research_Close_Date IS NULL THEN ' + @MaxTime +
                      ' ELSE dbo.fnServer_CmnConvertFromDbTime(ted.Research_Close_Date,''UTC'')  ' +
                      ' END,
   ResearchStatusId = IsNull(ted.Research_Status_Id,0),
   ResearchStatus = IsNull(rs.Research_Status_Desc,''''),
   ResearchUserId = IsNull(ted.Research_User_Id,0),
   ResearchUserName = IsNull(ru.UserName,''''),
   ResearchCommentId = IsNull(ted.Research_Comment_Id,0),
   SourceDepartment = IsNull(sd.Dept_Desc,''''),
   SourceProductionLine = IsNull(spl.PL_Desc,''''),
   SourceProductionUnitId = IsNull(ted.Source_PU_Id,0),
   SourceProductionUnit = IsNull(spu.PU_Desc,''''),
   DowntimeStatusId = IsNull(ted.TEStatus_Id,0),
   DowntimeStatusName = IsNull(tes.TEStatus_Name,''''),
   ESignatureId  = IsNull(ted.Signature_Id,0),
   UserId = IsNull(ted.User_Id,0)
 FROM Departments d
 JOIN Prod_Lines pl ON d.Dept_Id = pl.Dept_Id
 JOIN Prod_Units pu ON pl.PL_Id = pu.PL_Id
 JOIN Timed_Event_Details ted ON ted.PU_Id = pu.PU_Id
 LEFT JOIN Prod_Units spu ON ted.Source_PU_Id = spu.PU_Id
 LEFT JOIN Prod_Lines spl ON spu.PL_Id = spl.PL_Id
 LEFT JOIN Departments sd ON spl.Dept_Id = sd.Dept_Id
 LEFT JOIN Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
 LEFT JOIN Event_Reasons rl1 ON ted.Reason_Level1 = rl1.Event_Reason_Id
 LEFT JOIN Event_Reasons rl2 ON ted.Reason_Level2 = rl2.Event_Reason_Id
 LEFT JOIN Event_Reasons rl3 ON ted.Reason_Level3 = rl3.Event_Reason_Id
 LEFT JOIN Event_Reasons rl4 ON ted.Reason_Level4 = rl4.Event_Reason_Id
 LEFT JOIN Event_Reasons al1 ON ted.Action_Level1 = al1.Event_Reason_Id
 LEFT JOIN Event_Reasons al2 ON ted.Action_Level2 = al2.Event_Reason_Id
 LEFT JOIN Event_Reasons al3 ON ted.Action_Level3 = al3.Event_Reason_Id
 LEFT JOIN Event_Reasons al4 ON ted.Action_Level4 = al4.Event_Reason_Id
 LEFT JOIN Research_Status rs ON ted.Research_Status_Id = rs.Research_Status_Id
 LEFT JOIN Users ru ON ted.Research_User_Id = ru.User_Id
 LEFT JOIN Timed_Event_Status tes ON ted.PU_Id = tes.PU_Id AND ted.TEStatus_Id = tes.TEStatus_Id
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
SET @OrderClause = ' ORDER BY Start_Time ASC '
-- SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
