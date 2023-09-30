Create Procedure dbo.spDAML_FetchVariableSpecificationChanges
 	 @ChangeId 	 INT = NULL,
    @LineId 	  	 INT = NULL,
 	 @UnitId 	  	 INT = NULL,
 	 @VarId 	  	 INT = NULL,
    @StartTime  DATETIME = NULL,
    @EndTime    DATETIME = NULL,
    @ProductCode VarChar(25) = NULL,
 	 @UserId 	  	 INT 	 = NULL,
    @UTCOffset 	 VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(1000),
    @SelectClause   VARCHAR(5000),
 	 @OrderClause 	 VARCHAR(500),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25),
    @STime 	  	  	 VARCHAR(25),
    @ETime 	  	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- All queries check user security
SET @SecurityClause = ' WHERE COALESCE(vars.Access_Level, pus.Access_Level, pls.Access_Level, 3) >= 2 '
--   The Id clause part of the where clause limits by either variable, department, line, unit, or nothing
SELECT @IdClause = 
CASE WHEN (@ChangeId<>0 AND @ChangeId IS NOT NULL) THEN ' AND vs.VS_Id = ' + CONVERT(VARCHAR(10),@ChangeId) 
 	  WHEN (@VarId<>0 AND @VarId IS NOT NULL) THEN 'AND v.Var_Id = ' + CONVERT(VARCHAR(10),@VarId) 
 	  WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) 
     WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) 
     ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProductCode<>'' AND @ProductCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductCode)=0 AND CHARINDEX('_', @ProductCode)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (p.Prod_Code = ''' + CONVERT(VARCHAR(25),@ProductCode) + ''') '
   ELSE
 	   SET @OptionsClause = @OptionsClause + ' AND (p.Prod_Code LIKE ''' + CONVERT(VARCHAR(25),@ProductCode) + ''') '
END
-- The TimeClause determines the interval of time to return
-- EffectiveDate must be strictly less than IntervalEnd
-- ExpirationDate must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
if (@EndTime IS NULL) BEGIN
   SET @TimeClause = ' AND 	 vs.Effective_Date < ' + @STime + ' 
 	  	  	  	        AND (vs.Expiration_Date >= ' + @STime + ' 
 	  	  	  	        OR vs.Expiration_Date IS NULL)'
END
ELSE BEGIN
   SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
   SET @TimeClause = ' AND vs.Effective_Date < ' + @ETime + 
 	  	  	          ' AND (vs.Expiration_Date > ' + @STime + ' OR vs.Expiration_Date IS NULL) '
END
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause = 
'SELECT 	 VariableSpecificationChangeId = vs.VS_Id,
 	  	  	 DepartmentId = d.Dept_Id,
 	  	  	 Department = d.Dept_Desc,
 	  	  	 ProductionLineId = pl.PL_Id,
 	  	  	 ProductionLine = pl.PL_Desc,
 	  	  	 ProductionUnitId = pu.PU_Id,
 	  	  	 ProductionUnit = pu.PU_Desc,
 	  	  	 VariableId = v.Var_Id,
 	  	  	 Variable = v.Var_Desc, 
 	  	  	 ProductId = vs.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDescription = p.Prod_Desc, 
 	  	  	 TestName = IsNull(v.Test_Name,''''),
 	  	  	 EffectiveDate = dbo.fnServer_CmnConvertFromDbTime(vs.Effective_Date,''UTC'')  ' +  ', 
 	  	  	 ExpirationDate = CASE WHEN vs.Expiration_Date IS NULL THEN ' + @MaxTime +
 	 ' 	  	  	  	  	  	  	   ELSE dbo.fnServer_CmnConvertFromDbTime(vs.Expiration_Date,''UTC'')  ' + 
 	 ' 	  	  	  	  	  	  END,
 	  	  	 CommentId = IsNull(vs.Comment_Id,0),
 	  	  	 UCL = IsNull(vs.U_Control,''''),
 	  	  	 URL = IsNull(vs.U_Reject,''''),
 	  	  	 UWL = IsNull(vs.U_Warning,''''), 
 	  	  	 UUL = IsNull(vs.U_User,''''), 
 	  	  	 TCL = IsNull(vs.T_Control,''''),
 	  	  	 TGT = IsNull(vs.Target,''''), 
 	  	  	 LCL = IsNull(vs.L_Control,''''),
 	  	  	 LUL = IsNull(vs.L_User,''''), 
 	  	  	 LWL = IsNull(vs.L_Warning,''''), 
 	  	  	 LRL = IsNull(vs.L_Reject,''''),
 	  	  	 LEL = IsNull(vs.L_Entry,''''), 
 	  	  	 UEL = IsNull(vs.U_Entry,''''), 
 	  	  	 TestingFrequency = Coalesce(vs.Test_Freq, v.Sampling_Interval, 0)
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	 d.Dept_Id = pl.Dept_Id
 	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON  	 pu.PL_Id = pl.PL_Id
 	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	 pu.PU_Id = v.PU_Id
 	 JOIN 	  	  	 Var_Specs vs 	  	  	 ON 	 v.Var_Id = vs.Var_Id
 	 JOIN 	  	  	 PU_Products pup 	  	  	 ON 	 pup.PU_Id = pu.PU_Id
 	 JOIN 	  	  	 Products p 	  	  	  	 ON 	 p.Prod_Id = pup.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 p.Prod_Id = vs.Prod_Id
 	 LEFT JOIN 	  	 User_Security pls 	  	 ON 	 pl.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + '
 	 LEFT JOIN 	  	 User_Security pus 	  	 ON 	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + '
 	 LEFT JOIN 	  	 User_Security vars 	  	 ON 	 pu.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- order clause
SET @OrderClause = ' ORDER BY v.Var_Desc, p.Prod_Code, vs.Effective_Date '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
