Create Procedure dbo.spDAML_FetchVariableResultRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @VarId      INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @VariableName VarChar(50) = NULL,
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
  @WhereClause VARCHAR(1000),
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
-- The variable, production unit, and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(vars.Access_Level, pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND t.Test_Id = ' + CONVERT(VARCHAR(10),@EventId) 
   WHEN (@VarId<>0 AND @VarId IS NOT NULL) THEN 'AND t.Var_Id = ' + CONVERT(VARCHAR(10),@VarId)
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND v.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@VariableName<>'' AND @VariableName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @VariableName)=0 AND CHARINDEX('_', @VariableName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND v.Var_Desc = ''' + CONVERT(VARCHAR(50),@VariableName) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND v.Var_Desc LIKE ''' + CONVERT(VARCHAR(50),@VariableName) + ''' '
END
-- The TimeClause determines the interval of time to return
-- ResultOn must be less than or equal to IntervalEnd
-- ResultOn must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND t.Result_On <= ' + @ETime + ' AND t.Result_On > ' + @STime
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause = ' SELECT' + @TOPClause + ' VariableResultId = t.Test_Id,
   TestName = IsNull(v.Test_name,''''), 
   DepartmentId = d.Dept_Id,
   Department = d.Dept_Desc,
   ProductionLineId = pl.PL_Id,
   ProductionLine = pl.PL_Desc,
   ProductionUnitId = v.PU_Id,
   ProductionUnit = pu.PU_Desc,
   VariableId = t.Var_Id,
   Variable = v.Var_Desc, 
   ResultOn = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,''UTC'')  ' +  ',
   Value = IsNull(t.Result,''''), 
   Canceled = t.Canceled,
   EventId = IsNull(t.Event_Id,0),
   EventName = IsNull(e.Event_Num,''''), 
   ProductionPlanStartId = IsNull(pps.PP_Start_Id,0),
   ProductionPlanId = IsNull(pps.PP_Id,0),
   ProcessOrder = IsNull(pp.Process_Order,''''),
   ProductId = IsNull(p.Prod_Id,0),
   ProductCode = IsNull(p.Prod_Code,''''), 
   LCL = IsNull(vs.L_Control,''''),
   LEL = IsNull(vs.L_Entry,''''),     
   LRL = IsNull(vs.L_Reject,''''),
   LUL = IsNull(vs.L_User,''''),
   LWL = IsNull(vs.L_Warning,''''), 
   UCL = IsNull(vs.U_Control,''''),
   UEL = IsNull(vs.U_Entry,''''),
   URL = IsNull(vs.U_Reject,''''), 
   UUL = IsNull(vs.U_User,''''), 
   UWL = IsNull(vs.U_Warning,''''), 
   TCL = IsNull(vs.T_Control,''''),
   TGT = IsNull(vs.Target,''''), 
   CommentId = IsNull(t.Comment_Id,0),
   ESignatureId = IsNull(t.Signature_Id,0),
   SecondUserId = IsNull(t.Second_User_Id,0) '
SET @FromClause = ' FROM Departments d
 JOIN Prod_Lines pl ON d.Dept_Id = pl.Dept_Id AND pl.PL_Id > 0
 JOIN Prod_Units pu ON pl.PL_Id = pu.PL_Id AND pu.PU_Id > 0
 JOIN Variables v ON pu.PU_Id = v.PU_Id
 JOIN Tests t ON v.Var_Id = t.Var_Id 
   AND t.Result_On > ' + @STime + ' AND t.Result_On <= ' + @ETime + '
 LEFT JOIN Events e ON e.PU_Id = v.PU_Id AND e.TimeStamp = t.Result_On
 LEFT JOIN Production_Starts ps ON ps.PU_Id = e.PU_Id 
   AND ps.Start_Time < t.Result_On AND (ps.End_Time >= t.Result_On OR ps.End_Time IS NULL)
 LEFT JOIN Production_Plan_Starts pps ON pps.PU_Id = e.PU_Id 
   AND pps.Start_Time < t.Result_On AND (pps.End_Time >= t.Result_On OR pps.End_Time IS NULL)
 LEFT JOIN Production_Plan pp  ON pps.PP_Id = pp.PP_Id 
 LEFT JOIN Var_Specs vs  ON  vs.Var_id = t.Var_Id
   AND vs.Prod_id = CASE WHEN e.Applied_Product IS NULL THEN ps.Prod_id ELSE e.Applied_product END
   AND vs.Effective_Date < t.Result_On AND (vs.Expiration_date >= t.Result_On OR vs.Expiration_date IS NULL)
 LEFT JOIN Products p ON p.Prod_id = CASE WHEN e.Applied_Product IS NULL THEN ps.Prod_id ELSE e.Applied_product END
 LEFT JOIN User_Security pls ON  pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON  pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security vars ON  v.Group_Id = vars.Group_Id AND vars.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 
-- order clause 
SET @OrderClause = ' ORDER BY ResultOn '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @FromClause + @WhereClause + @OrderClause)
