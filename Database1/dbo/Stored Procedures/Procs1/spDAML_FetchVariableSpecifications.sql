Create Procedure dbo.spDAML_FetchVariableSpecifications
    @LineId         INT = NULL,
    @UnitId         INT = NULL,
    @VarId 	  	  	 INT = NULL,
    @ProductCode 	 VARCHAR(25) = NULL,
    @TimeStamp 	  	 DATETIME = NULL,
 	 @UserId 	  	  	 INT 	 = NULL,
    @UTCOffset 	  	 VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(200),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(5000),
    @OrderClause 	 VARCHAR(100),
 	 @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- The variable, production unit and production line have security levels
SET @SecurityClause = ' WHERE COALESCE(vars.Access_Level, pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@VarId<>0 AND @VarId IS NOT NULL) THEN ' AND v.Var_Id = ' + CONVERT(VARCHAR(10),@VarId)
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN ' AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProductCode<>'' AND @ProductCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductCode)=0 AND CHARINDEX('_', @ProductCode)=0 )
     SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code = ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code LIKE ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
END
-- The TimeClause determines the interval of time to return
-- EffectiveDate must be less than TimeStamp
-- ExpirationDate must be greater than or equal to TimeStamp
SET @TimeClause = ' AND 	 vs.Effective_Date < ''' + CONVERT(VARCHAR(100),@TimeStamp,21) + ''' 
 	  	  	  	     AND (vs.Expiration_Date >= ''' + CONVERT(VARCHAR(100),@TimeStamp,21) + ''' 
 	  	  	  	       OR vs.Expiration_Date IS NULL)'
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 VariableSpecificationId = VS_Id,
 	  	  	 DepartmentId = d.Dept_Id,
 	  	  	 Department = d.Dept_Desc,
 	  	  	 ProductionLineId = pl.PL_Id,
 	  	  	 ProductionLine = pl.PL_Desc,
 	  	  	 ProductionUnitId = v.PU_Id,
 	  	  	 ProducitonUnit = pu.PU_Desc, 
 	  	  	 VariableId = vs.Var_Id,
 	  	  	 Variable = v.Var_Desc, 
 	  	  	 ProductId = p.Prod_Id,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDescription = p.Prod_Desc, 
 	  	  	 CharacteristicName = IsNull(v.Test_name,''''),
 	  	  	 EffectiveDate = dbo.fnServer_CmnConvertFromDbTime(vs.Effective_Date,''UTC'')  ' + ',
 	  	  	 ExpirationDate = CASE WHEN vs.Expiration_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	 ' 	  	   ELSE dbo.fnServer_CmnConvertFromDbTime(vs.Expiration_Date,''UTC'')  ' + 
 	  	 ' 	  	  	  	  	  END, 
 	  	  	 CommentId = IsNull(vs.Comment_Id, 0),
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
 	  	  	 TestingFrequency = Coalesce(vs.Test_Freq, v.Sampling_Interval,0),
            ESignatureId = IsNull(vs.ESignature_Level,0)
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	 ON  	 d.Dept_Id = pl.Dept_Id
 	 JOIN 	  	  	 Prod_Units pu 	 ON 	 pl.PL_Id = pu.PL_Id
 	 JOIN 	  	  	 Variables v 	  	 ON 	 pu.PU_Id = v.PU_Id
 	 JOIN 	  	  	 Var_Specs vs 	 ON 	 v.var_id = vs.var_id
 	 JOIN 	  	  	 PU_Products pup 	 ON 	 pu.PU_Id = pup.PU_Id 
 	 JOIN 	  	  	 Products p 	  	 ON 	 pup.Prod_Id = p.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 User_Security pls 	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) +
' 	 LEFT JOIN 	 User_Security pus 	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + 	 
' 	 LEFT JOIN 	 User_Security vars 	 ON 	  	 pu.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 	 
-- order clause
SET @OrderClause = ' ORDER BY 	 v.Var_Desc, p.Prod_Code, vs.Effective_Date'
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
