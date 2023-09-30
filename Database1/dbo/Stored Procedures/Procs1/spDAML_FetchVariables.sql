Create Procedure dbo.spDAML_FetchVariables
    @VarId 	  	 INT = NULL,
 	 @DeptId 	  	 INT = NULL,
 	 @LineId 	  	 INT = NULL,
 	 @UnitId 	  	 INT = NULL,
    @ForChildren 	 BIT = NULL,
 	 @UserId 	  	 INT 	 = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(5000),
 	 @OrderClause 	 VARCHAR(500)
-- Determine Where clause
-- All queries check user security
SET @SecurityClause = ' WHERE (COALESCE(vars.Access_Level, pus.Access_Level, pls.Access_Level, 3) >= 2) '
--   The Id clause part of the where clause limits by either variable, department, line, unit, or nothing
--   If only children are desired, match the variable id to the parent variable.
SELECT @IdClause = 
CASE WHEN (@VarId<>0 AND @VarId IS NOT NULL AND @ForChildren=1) THEN 'AND v.PVar_Id = ' + CONVERT(VARCHAR(10),@VarId) 
   WHEN(@VarId<>0 AND @VarId IS NOT NULL) THEN 'AND v.Var_Id = ' + CONVERT(VARCHAR(10),@VarId)
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND pu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ' AND v.PVar_Id IS NULL '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pl.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ' AND v.PVar_Id IS NULL '
   WHEN (@DeptId<>0 AND @DeptId IS NOT NULL) THEN 'AND d.Dept_Id = ' + CONVERT(VARCHAR(10),@DeptId) + ' AND v.PVar_Id IS NULL '
   ELSE ''
END
-- Variables have no options clause
SET @OptionsClause = ''
-- Variables have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
 	 'SELECT 	 VariableId 	  	  	 = v.Var_Id,
 	  	  	 Variable 	   	  	 = v.Var_Desc, 
 	  	  	 DepartmentId 	  	 = d.Dept_Id,
 	  	  	 Department 	  	  	 = d.Dept_Desc,
 	  	  	 ProductionLineId 	 = pl.PL_Id,
 	  	  	 ProductionLine 	  	 = pl.PL_Desc,
 	  	  	 ProductionUnitId 	 = v.PU_Id,
 	  	  	 ProductionUnit 	  	 = pu.PU_Desc, 
 	  	  	 EngineeringUnits 	 = IsNull(v.Eng_Units,''''), 
 	  	  	 TestName 	  	  	 = IsNull(v.Test_Name,''''),
 	  	  	 DataSourceId 	  	 = v.DS_Id,
 	  	  	 DataSource 	  	  	 = ds.DS_Desc,
 	  	  	 CalculationId 	  	 = IsNull(v.Calculation_Id,0),
 	  	  	 Calculation 	  	  	 = IsNull(calc.Calculation_Name,''''), 
 	  	  	 EventTypeId 	  	  	 = v.Event_Type,   
 	  	  	 EventType 	  	  	 = et.ET_Desc,
 	  	  	 EventSubTypeId 	  	 = IsNull(v.Event_Subtype_Id,0),
 	  	  	 EventSubType 	  	 = IsNull(est.Event_SubType_Desc,''''),
 	  	  	 DataTypeId 	  	  	 = v.Data_Type_Id,
 	  	  	 DataType 	  	  	 = IsNull(dt.Data_Type_Desc,''''),
 	  	  	 ParentVariableId 	 = IsNull(v.PVar_Id,0),
 	  	  	 ParentVariable 	  	 = IsNull(pv.Var_Desc,''''),
 	  	  	 InputTag 	  	  	 = IsNull(v.Input_Tag,''''),
 	  	  	 OutputTag 	  	  	 = IsNull(v.Output_Tag,''''),
 	  	  	 LELTag 	  	  	  	 = IsNull(v.LEL_Tag,''''),
 	  	  	 LRLTag 	  	  	  	 = IsNull(v.LRL_Tag,''''),
 	  	  	 LULTag 	  	  	  	 = IsNull(v.LUL_Tag,''''),
 	  	  	 LWLTag 	  	  	  	 = IsNull(v.LWL_Tag,''''),
 	  	  	 UELTag 	  	  	  	 = IsNull(v.UEL_Tag,''''),
 	  	  	 URLTag 	  	  	  	 = IsNull(v.URL_Tag,''''),
 	  	  	 UULTag 	  	  	  	 = IsNull(v.UUL_Tag,''''),
 	  	  	 UWLTag 	  	  	  	 = IsNull(v.UWL_Tag,''''),
 	  	  	 TargetTag 	  	  	 = IsNull(v.Target_Tag,''''),
 	  	  	 CommentId 	  	  	 = IsNull(v.Comment_Id,0),
 	  	  	 ExtendedInfo 	  	 = IsNull(v.Extended_Info,''''),
 	  	  	 WriteGroupDataSourceId 	 = IsNull(v.Write_Group_DS_Id,0)
 	 FROM 	  	  	 Departments d
 	 INNER 	 JOIN 	 Prod_Lines pl 	  	  	 ON  	 pl.Dept_Id = d.Dept_Id
 	 INNER 	 JOIN 	 Prod_Units pu 	  	  	 ON  	 pu.PL_Id = pl.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.pu_id > 0
 	 INNER 	 JOIN 	 Variables v  	  	  	 ON 	 v.PU_Id = pu.PU_Id
 	 INNER 	 JOIN 	 Data_Source ds 	  	  	 ON 	 ds.DS_Id = v.DS_Id
 	 INNER 	 JOIN 	 Event_Types 	 et 	  	  	 ON 	 et.ET_Id = v.Event_Type
 	 INNER 	 JOIN 	 Data_Type dt 	  	  	 ON 	 dt.Data_Type_Id = v.Data_Type_Id
 	 LEFT 	 JOIN 	 Event_SubTypes est 	  	 ON 	 est.Event_Subtype_Id = v.Event_SubType_Id
 	 LEFT 	 JOIN 	 Calculations calc 	  	 ON 	 calc.Calculation_Id = v.Calculation_Id  
    LEFT 	 JOIN 	 Variables pv 	  	  	 ON  v.PVar_Id = pv.Var_Id 
 	 LEFT 	 JOIN 	 User_Security pls 	  	 ON 	 pl.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + ' ' + ' 
 	 LEFT 	 JOIN 	 User_Security pus 	  	 ON 	 pu.Group_Id = pus.Group_Id    
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = ' + CONVERT(VARCHAR(10), @UserId) + ' ' + ' 
 	 LEFT 	 JOIN 	 User_Security vars 	  	 ON 	 v.Group_Id = vars.Group_Id    
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = ' + CONVERT(VARCHAR(10), @UserId)
-- order clause
SET @OrderClause = ' ORDER BY v.Var_Desc ' 
-- SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
