Create Procedure dbo.spDAML_FetchPropertySpecificationChanges
 	 @ChangeId 	 INT = NULL,
    @SpecId 	  	 INT = NULL,
 	 @PropId 	  	 INT = NULL,
 	 @CharId 	  	 INT = NULL,
    @StartTime  DATETIME = NULL,
    @EndTime    DATETIME = NULL,
 	 @UserId 	  	 INT 	 = NULL,
    @UTCOffset 	 VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
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
SET @SecurityClause = ' WHERE COALESCE(pps.Access_Level, ss.Access_Level, 3) >= 2 '
--   The Id clause part of the where clause limits by either variable, department, line, unit, or nothing
SELECT @IdClause = 
CASE WHEN (@ChangeId<>0 AND @ChangeId IS NOT NULL) THEN ' AND specs.AS_Id = ' + CONVERT(VARCHAR(10),@ChangeId) 
 	  WHEN (@SpecId<>0 AND @SpecId IS NOT NULL) THEN 'AND s.Spec_Id = ' + CONVERT(VARCHAR(10),@SpecId) 
 	  WHEN (@CharId<>0 AND @CharId IS NOT NULL) THEN 'AND specs.Char_Id = ' + CONVERT(VARCHAR(10),@CharId) 
     WHEN (@PropId<>0 AND @PropId IS NOT NULL) THEN 'AND s.Prop_Id = ' + CONVERT(VARCHAR(10),@PropId) 
     ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
-- The TimeClause determines the interval of time to return
-- EffectiveDate must be strictly less than IntervalEnd
-- ExpirationDate must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND specs.Effective_Date < ' + @ETime + 
 	  	  	       ' 	 AND 	 (specs.Expiration_Date > ' + @STime + ' OR specs.Expiration_Date IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause = 
'SELECT 	  	 PropertySpecificationChangeId 	 = specs.AS_Id,
 	  	  	 PropertySpecificationId = IsNull(s.Spec_Id,0),
 	  	  	 PropertySpecificationName = IsNull(s.Spec_Desc,''''),
 	  	  	 PropertyId 	  	  	  	 = s.Prop_Id,
 	  	  	 PropertyName 	  	  	 = IsNull(pp.Prop_Desc,''''),
 	  	  	 CharacteristicId 	  	 = IsNull(specs.Char_Id,0),
 	  	  	 CharacteristicName 	  	 = IsNull(c.Char_Desc,''''),
 	  	  	 Tag 	  	  	  	  	  	 = IsNull(s.Tag,''''),
 	  	  	 EffectiveDate 	  	  	 = CASE WHEN specs.Effective_Date IS NULL THEN ' + @MaxTime +
 	 ' 	  	  	  	  	  	  	  	  	    ELSE dbo.fnServer_CmnConvertFromDbTime(specs.Effective_Date,''UTC'')  ' + 
 	 ' 	  	  	  	  	  	  	  	   END, 
 	  	  	 ExpirationDate 	  	  	 = CASE WHEN specs.Expiration_Date IS NULL THEN ' + @MaxTime +
 	 ' 	  	  	  	  	  	  	  	  	    ELSE dbo.fnServer_CmnConvertFromDbTime(specs.Expiration_Date,''UTC'')  ' + 
 	 ' 	  	  	  	  	  	  	  	   END, 
 	  	  	 TCL 	  	  	  	  	  	 = IsNull(specs.T_Control,''''),
 	  	  	 TGT 	  	  	  	  	  	 = IsNull(specs.Target,''''), 
 	  	  	 UCL 	  	  	  	  	  	 = IsNull(specs.U_Control,''''),
 	  	  	 UEL 	  	  	  	  	  	 = IsNull(specs.U_Entry,''''), 
 	  	  	 URL 	  	  	  	  	  	 = IsNull(specs.U_Reject,''''), 
 	  	  	 UUL 	  	  	  	  	  	 = IsNull(specs.U_User,''''), 
 	  	  	 UWL 	  	  	  	  	  	 = IsNull(specs.U_Warning,''''), 
 	  	  	 LCL 	  	  	  	  	  	 = IsNull(specs.L_Control,''''),
 	  	  	 LEL 	  	  	  	  	  	 = IsNull(specs.L_Entry,''''), 
 	  	  	 LRL 	  	  	  	  	  	 = IsNull(specs.L_Reject,''''),
 	  	  	 LUL 	  	  	  	  	  	 = IsNull(specs.L_User,''''), 
 	  	  	 LWL 	  	  	  	  	  	 = IsNull(specs.L_Warning,''''),  	  	  	 
 	  	  	 TestingFrequency  	  	 = IsNull(specs.Test_Freq,0),
 	  	  	 CommentId 	  	  	  	 = IsNull(specs.Comment_Id,0)
 	 FROM 	  	 Product_Properties pp
 	 JOIN 	  	 Specifications s 	 ON 	 s.Prop_Id = pp.Prop_Id
 	 JOIN 	  	 Active_Specs specs 	 ON 	 specs.Spec_Id = s.Spec_Id
 	 JOIN 	  	 Characteristics 	 c 	 ON  specs.Char_Id = c.Char_Id
 	 LEFT JOIN 	 User_Security pps 	 ON 	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = ' + CONVERT(VARCHAR(10), @UserId) +
' 	 LEFT JOIN 	 User_Security ss 	 ON 	 s.Group_Id = ss.Group_Id
 	  	  	  	  	  	  	  	  	  	 AND 	 ss.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- No Order Clause
SET @OrderClause = ' ORDER BY s.Spec_Desc '
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
