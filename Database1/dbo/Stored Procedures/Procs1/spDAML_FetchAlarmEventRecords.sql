Create Procedure dbo.spDAML_FetchAlarmEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @VariableId INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @UnitName VARCHAR(50) = NULL,
  @VariableName VARCHAR(50) = NULL,
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
  @FromClause VARCHAR(5000),
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
-- The variable, production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(vars.Access_Level, pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND a.Alarm_Id = ' + CONVERT(VARCHAR(10),@EventId)
   WHEN (@VariableId<>0 AND @VariableId IS NOT NULL) THEN 'AND v.Var_Id = ' + CONVERT(VARCHAR(10),@VariableId)
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND v.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- All will be treated as masks, if and only if they contain mask characters
SET @OptionsClause = ''
IF (@UnitName<>'' AND @UnitName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @UnitName)=0 AND CHARINDEX('_', @UnitName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND pu.PU_Desc = ''' + CONVERT(VARCHAR(50),@UnitName) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND pu.PU_Desc LIKE ''' + CONVERT(VARCHAR(50),@UnitName) + ''' '
END 
IF (@VariableName<>'' AND @VariableName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @VariableName)=0 AND CHARINDEX('_', @VariableName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND v.Var_Desc = ''' + CONVERT(VARCHAR(50),@VariableName) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND v.Var_Desc LIKE ''' + CONVERT(VARCHAR(50),@VariableName) + ''' '
END  
-- The TimeClause determines the interval of time to return
-- EventStartTime must be strictly less than IntervalEnd
-- EventEndTime must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND a.Start_Time < ' + @ETime + 
                  ' AND (a.End_Time > ' + @STime + ' OR a.End_Time IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT' + @TOPClause + '  VariableAlarmEventId = a.Alarm_Id,
   AlarmDescription = a.Alarm_Desc,
   AlarmTypeId = a.Alarm_Type_Id,
   AlarmType = type.Alarm_Type_Desc,
   AlarmTemplateId = IsNull(atemp.AT_Id,0),
   AlarmTemplate = IsNull(atemp.AT_Desc,''''),
   AlarmTemplateVariableDataId = IsNull(a.ATD_Id,0),
   AlarmTemplateVariableRuleDataId = IsNull(a.ATVRD_Id,0),
   AlarmTemplateSPCRuleDataId = IsNull(a.ATSRD_Id,0),
   AlarmSPCRuleId = IsNull(asr.Alarm_SPC_Rule_Id,0),
   AlarmSPCRule = IsNull(asr.Alarm_SPC_Rule_Desc,''''),
   AlarmPriorityId = IsNull(atemp.AP_Id,0),
   AlarmPriority = IsNull(ap.AP_Desc,''''),
   AlarmSubTypeId = IsNull(a.SubType,0),
   DepartmentId = IsNull(d.Dept_Id,0),
   Department = IsNull(d.Dept_Desc,''''),
   ProductionLineId = IsNull(pl.PL_Id,0),
   ProductionLine = IsNull(pl.PL_Desc,''''),
   ProductionUnitId = IsNull(v.PU_Id,0),
   ProductionUnit = IsNull(pu.PU_Desc,''''), 
   SourceProductionUnitId = IsNull(Source_PU_Id,0),
   VariableId = IsNull(a.Key_Id,0),
   VariableName = IsNull(v.Var_Desc,''''),
   StartTime = dbo.fnServer_CmnConvertFromDbTime(a.Start_Time,''UTC''),
   EndTime = CASE WHEN a.End_Time IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(a.End_Time,''UTC'')'  +
           ' END, 
   StartValue = IsNull(a.Start_Result,''''),
   EndValue = IsNull(a.End_Result,''''),
   MinValue = IsNull(a.Min_Result,''''),
   MaxValue = IsNull(a.Max_Result,''''),
   Cause1Id = IsNull(a.Cause1,0),
   Cause1 = IsNull(cr1.Event_Reason_Name,''''), 
   Cause2Id = IsNull(a.Cause2,0),
   Cause2 = IsNull(cr2.Event_Reason_Name,''''),
   Cause3Id = IsNull(a.Cause3,0),
   Cause3 = IsNull(cr3.Event_Reason_Name,''''),
   Cause4Id = IsNull(a.Cause4,0),
   Cause4 = IsNull(cr4.Event_Reason_Name,''''),
   Action1Id = IsNull(a.Action1,0),
   Action1 = IsNull(ar1.Event_Reason_Name,''''),
   Action2Id = IsNull(a.Action2,0),
   Action2 = IsNull(ar2.Event_Reason_Name,''''),
   Action3Id = IsNull(a.Action3,0),
   Action3 = IsNull(ar3.Event_Reason_Name,''''),
   Action4Id = IsNull(a.Action4,0),
   Action4 = IsNull(ar4.Event_Reason_Name,''''),
   ResearchOpenDate = CASE WHEN a.Research_Open_Date IS NULL THEN ' + @MaxTime +
                    ' ELSE dbo.fnServer_CmnConvertFromDbTime(a.Research_Open_Date,''UTC'') ' + 
                    ' END,
   ResearchCloseDate = CASE WHEN a.Research_Close_Date IS NULL THEN ' + @MaxTime +
                     ' ELSE dbo.fnServer_CmnConvertFromDbTime(a.Research_Close_Date,''UTC'') ' + 
                     ' END,
   ResearchStatusId = IsNull(a.Research_Status_Id,0),
   ResearchStatus = IsNull(rs.Research_Status_Desc,''''),
   ResearchUserId = IsNull(a.Research_User_Id,0),
   ResearchUserName = IsNull(ru.UserName,''''),
   Ack = a.Ack,
   AckById = IsNull(a.Ack_By,0),
   AckBy = IsNull(au.UserName,''''),
   AckOn = CASE WHEN a.Ack_On IS NULL THEN ' + @MaxTime +
            ' ELSE dbo.fnServer_CmnConvertFromDbTime(a.Ack_On,''UTC'') ' + 
            ' END,
   CauseCommentId = IsNull(a.Cause_Comment_Id,0),
   ActionCommentId = IsNull(a.Action_Comment_Id,0),
   ResearchCommentId = IsNull(a.Research_Comment_Id,0),
   VariableCommentId = IsNull(v.Comment_Id,0),
   ESignatureId = IsNull(a.Signature_Id,0),
   UserId = a.User_Id '
SET @FromClause = ' FROM Alarms a
 INNER JOIN Alarm_Types type ON type.Alarm_Type_Id = a.Alarm_Type_Id AND type.Alarm_Type_Id IN (1, 2, 4)
 INNER JOIN Alarm_Template_Var_Data atvd ON atvd.ATD_Id = a.ATD_Id
 INNER JOIN Alarm_Templates atemp ON atemp.AT_Id = atvd.AT_Id
 INNER JOIN Alarm_Priorities ap ON ap.AP_Id = atemp.AP_Id
 INNER JOIN Variables v ON v.Var_Id = a.Key_Id
 INNER JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id
 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 INNER JOIN Departments d ON d.Dept_Id = pl.Dept_Id
 LEFT JOIN Alarm_Template_SPC_Rule_Data atsrd ON atsrd.ATSRD_Id = a.ATSRD_Id
 LEFT JOIN Alarm_SPC_Rules asr ON asr.Alarm_SPC_Rule_Id = atsrd.Alarm_SPC_Rule_Id
 LEFT JOIN Event_Reasons cr1 ON cr1.Event_Reason_Id = a.Cause1
 LEFT JOIN Event_Reasons cr2 ON cr2.Event_Reason_Id = a.Cause2
 LEFT JOIN Event_Reasons cr3 ON cr3.Event_Reason_Id = a.Cause3
 LEFT JOIN Event_Reasons cr4 ON cr4.Event_Reason_Id = a.Cause4
 LEFT JOIN Event_Reasons ar1 ON ar1.Event_Reason_Id = a.Action1
 LEFT JOIN Event_Reasons ar2 ON ar2.Event_Reason_Id = a.Action2
 LEFT JOIN Event_Reasons ar3 ON ar3.Event_Reason_Id = a.Action3
 LEFT JOIN Event_Reasons ar4 ON ar4.Event_Reason_Id = a.Action4
 LEFT JOIN Research_Status rs ON rs.Research_Status_Id = a.Research_Status_Id
 LEFT JOIN Users au ON au.User_Id = a.Ack_By
 LEFT JOIN Users ru ON ru.User_Id = a.Research_User_Id
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security vars ON v.Group_Id = vars.Group_Id AND vars.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 
-- Order Clause 
SET @OrderClause = ' ORDER BY a.Start_Time, a.Alarm_Id'
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @FromClause + @WhereClause + @OrderClause)
