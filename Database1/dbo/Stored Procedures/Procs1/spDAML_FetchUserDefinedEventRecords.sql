Create Procedure dbo.spDAML_FetchUserDefinedEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @EventType  VARCHAR(50) = NULL,
  @EventName VARCHAR(1000) = NULL,
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
  @OptionsClause  VARCHAR(2000),
  @TimeClause  VARCHAR(500),
  @WhereClause VARCHAR(4000),
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
SET @SecurityClause = ' WHERE COALESCE(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND ud.UDE_Id = ' + CONVERT(VARCHAR(10),@EventId) 
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND ud.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@EventName<>'' AND @EventName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @EventName)=0 AND CHARINDEX('_', @EventName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ud.UDE_Desc = ''' + CONVERT(VARCHAR(1000),@EventName) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND ud.UDE_Desc LIKE ''' + CONVERT(VARCHAR(1000),@EventName) + ''' '
END
IF (@EventType<>'' AND @EventType IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @EventType)=0 AND CHARINDEX('_', @EventType)=0 )
     SET @OptionsClause = @OptionsClause + ' AND es.Event_Subtype_Desc = ''' + CONVERT(VARCHAR(50),@EventType) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND es.Event_Subtype_Desc LIKE ''' + CONVERT(VARCHAR(50),@EventType) + ''' '
END
-- The TimeClause determines the interval of time to return
-- EventStartTime must be strictly less than IntervalEnd
-- EventEndTime must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND ud.Start_Time < ' + @ETime + 
    ' AND (ud.End_Time > ' + @STime + ' OR ud.End_Time IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
' SELECT DISTINCT' + @TOPClause + ' UserDefinedEventId = ud.UDE_Id,
  EventName = ud.UDE_Desc, 
  DepartmentId = IsNull(d.Dept_Id,0),
  Department = IsNull(d.Dept_Desc,''''),
  ProductionLineId = IsNull(pl.PL_Id,0),
  ProductionLine = IsNull(pl.PL_Desc,''''),
  ProductionUnitId = IsNull(ud.PU_Id,0),
  ProductionUnit = IsNull(pu.PU_Desc,''''),
  EventId = IsNull(ud.Event_Id,0),
  EventSubTypeId = ud.Event_Subtype_Id,
  EventSubType = es.Event_Subtype_Desc,
  StartTime = CASE WHEN ud.Start_Time IS NULL THEN ' + @MaxTime + 
 	  	  	 ' ELSE dbo.fnServer_CmnConvertFromDbTime(ud.Start_Time,''UTC'')  ' + 
 	  	  	 ' END,
  EndTime = CASE WHEN ud.End_Time IS NULL THEN ' + @MaxTime + 
 	  	  	 ' ELSE dbo.fnServer_CmnConvertFromDbTime(ud.End_Time,''UTC'')  ' + 
 	  	  	 ' END, 
  Cause1Id = IsNull(ud.Cause1,0),
  Cause1 = IsNull(cr1.Event_Reason_Name,''''),
  Cause2Id = IsNull(ud.Cause2,0),
  Cause2 = IsNull(cr2.Event_Reason_Name,''''),
  Cause3Id = IsNull(ud.Cause3,0),
  Cause3 = IsNull(cr3.Event_Reason_Name,''''),
  Cause4Id = IsNull(ud.Cause4,0),
  Cause4 = IsNull(cr4.Event_Reason_Name,''''),
  Action1Id = IsNull(ud.Action1,0),
  Action1 = IsNull(ar1.Event_Reason_Name,''''),
  Action2Id = IsNull(ud.Action2,0),
  Action2 = IsNull(ar2.Event_Reason_Name,''''),
  Action3Id = IsNull(ud.Action3,0),
  Action3 = IsNull(ar3.Event_Reason_Name,''''),
  Action4Id = IsNull(ud.Action4,0),
  Action4 = IsNull(ar4.Event_Reason_Name,''''),
  ResearchOpenDate = CASE WHEN ud.Research_Open_Date IS NULL THEN ' + @MaxTime +
                   ' ELSE dbo.fnServer_CmnConvertFromDbTime(ud.Research_Open_Date,''UTC'')  ' + 
                   ' END,
  ResearchCloseDate = CASE WHEN ud.Research_Close_Date IS NULL THEN ' + @MaxTime +
                    ' ELSE dbo.fnServer_CmnConvertFromDbTime(ud.Research_Close_Date,''UTC'')  ' + 
                    ' END,
  ResearchStatusId = IsNull(ud.Research_Status_Id,0),
  ResearchStatus = IsNull(rs.Research_Status_Desc,''''),
  ResearchUserId = IsNull(ud.Research_User_Id,0),
  ResearchUserName = IsNull(ru.UserName,''''),
  Ack = ud.Ack,
  AckById = IsNull(ud.Ack_By,0),
  AckBy = IsNull(au.UserName,''''),
  AckOn = CASE WHEN ud.Ack_On IS NULL THEN ' + @MaxTime +
        ' ELSE dbo.fnServer_CmnConvertFromDbTime(ud.Ack_On,''UTC'')  ' +
        ' END,
  CommentId = IsNull(ud.Comment_Id,0),
  CauseCommentId = IsNull(ud.Cause_Comment_Id,0),
  ActionCommentId = IsNull(ud.Action_Comment_Id,0),
  ResearchCommentId = IsNull(ud.Research_Comment_Id,0),
  ESignatureId = IsNull(ud.Signature_Id,0),
  UserId = IsNull(ud.User_Id,0) '
SET @FromClause = ' FROM User_Defined_Events ud 
 INNER JOIN Prod_Units pu ON pu.PU_Id = ud.PU_Id 
 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 INNER JOIN Departments d ON d.Dept_Id = pl.Dept_Id
 INNER JOIN Event_Configuration ec ON ec.PU_Id = ud.PU_Id AND ec.ET_Id = 14
 INNER JOIN Event_SubTypes es ON ec.Event_SubType_Id = es.Event_SubType_Id AND es.event_subtype_id = ud.Event_Subtype_Id
 LEFT JOIN Event_Reasons cr1 ON cr1.Event_Reason_Id = ud.Cause1
 LEFT JOIN Event_Reasons cr2 ON cr2.Event_Reason_Id = ud.Cause2
 LEFT JOIN Event_Reasons cr3 ON cr3.Event_Reason_Id = ud.Cause3
 LEFT JOIN Event_Reasons cr4 ON cr4.Event_Reason_Id = ud.Cause4
 LEFT JOIN Event_Reasons ar1 ON ar1.Event_Reason_Id = ud.Action1
 LEFT JOIN Event_Reasons ar2 ON ar2.Event_Reason_Id = ud.Action2
 LEFT JOIN Event_Reasons ar3 ON ar3.Event_Reason_Id = ud.Action3
 LEFT JOIN Event_Reasons ar4 ON ar4.Event_Reason_Id = ud.Action4
 LEFT JOIN Research_Status rs ON rs.Research_Status_Id = ud.Research_Status_Id
 LEFT JOIN Users au ON au.User_Id = ud.Ack_By
 LEFT JOIN Users ru ON ru.User_Id = ud.Research_User_Id
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON  pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- Add criteria for Production Event Search
IF (@ProdEventId IS NOT NULL) BEGIN
 	 SET @FromClause = @FromClause + ' JOIN Events evt on evt.Event_Id = ud.Event_Id'
 	 SET @WhereClause = @WhereClause + ' AND evt.Event_Id = ' + CONVERT(VARCHAR(10),@ProdEventId)
END
-- order clause
SET @OrderClause = ' ORDER BY StartTime, UserDefinedEventId'
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
set rowcount 10
EXECUTE (@SelectClause + @FromClause + @WhereClause + @OrderClause)
