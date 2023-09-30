CREATE PROCEDURE dbo.spSDK_QueryVariables
 	 @LineMask 	 nvarchar(50) 	 = NULL,
 	 @UnitMask 	 nvarchar(50) 	 = NULL,
 	 @VarMask 	  	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	 INT 	  	  	  	 = NULL,
 	 @DeptMask 	 nvarchar(50) 	 = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @VarMask = 	 REPLACE(COALESCE(@VarMask, '*'), '*', '%')
SELECT 	 @VarMask = 	 REPLACE(REPLACE(@VarMask, '?', '_'), '[', '[[]')
SELECT 	 @DeptMask = REPLACE(COALESCE(@DeptMask, '*'), '*', '%')
SELECT 	 @DeptMask = REPLACE(REPLACE(@DeptMask, '?', '_'), '[', '[[]')
SELECT 	 VariableId 	  	  	 = v.Var_Id,
 	  	  	 DepartmentName 	  	 = d.Dept_Desc,
 	  	  	 LineName  	  	  	 = pl.PL_Desc, 
 	  	  	 UnitName  	  	  	 = pu.PU_Desc, 
 	  	  	 UnitGroupName  	  	 = pug.PUG_Desc,
 	  	  	 VariableName  	  	 = v.Var_Desc, 
 	  	  	 EngineeringUnits 	 = v.Eng_Units, 
 	  	  	 TestName 	  	  	  	 = v.Test_Name,
 	  	  	 DataSource 	  	  	 = ds.DS_Desc,
 	  	  	 Calculation 	  	  	 = calc.Calculation_Name,     
 	  	  	 EventType 	  	  	 = et.ET_Desc,
 	  	  	 EventSubType 	  	 = est.Event_SubType_Desc,
 	  	  	 DataType 	  	  	  	 = dt.Data_Type_Desc,
 	  	  	 CommentId = v.Comment_Id,
 	  	  	 ExtendedInfo = v.Extended_Info,
 	  	  	 InputTag = v.Input_Tag,
 	  	  	 OutputTag = v.Output_Tag,
 	  	  	 LELTag = v.LEL_Tag,
 	  	  	 LRLTag = v.LRL_Tag,
 	  	  	 LULTag = v.LUL_Tag,
 	  	  	 LWLTag = v.LWL_Tag,
 	  	  	 UELTag = v.UEL_Tag,
 	  	  	 URLTag = v.URL_Tag,
 	  	  	 UULTag = v.UUL_Tag,
 	  	  	 UWLTag = v.UWL_Tag,
 	  	  	 TargetTag = v.Target_Tag,
 	  	  	 WriteGroupDSId = v.Write_Group_DS_Id
 	 FROM 	  	  	  	 Departments d
 	  	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON  	 pl.Dept_Id = d.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON  	 pu.PL_Id = pl.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.pu_desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.pu_id > 0
 	  	 JOIN 	  	  	 PU_Groups pug 	  	  	 ON 	  	 pu.PU_Id = pug.PU_Id
 	  	 JOIN 	  	  	 Variables v  	  	  	 ON 	  	 v.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.PUG_Id = pug.PUG_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (v.System Is Null Or v.System = 0)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.var_desc LIKE @VarMask
 	  	 JOIN 	  	  	 Data_Source ds 	  	  	 ON 	  	 ds.DS_Id = v.DS_Id
 	  	 JOIN 	  	  	 Event_Types 	 et 	  	  	 ON 	  	 et.ET_Id = v.Event_Type
 	  	 JOIN 	  	  	 Data_Type dt 	  	  	 ON 	  	 dt.Data_Type_Id = v.Data_Type_Id
 	  	 LEFT JOIN 	 Event_SubTypes est 	 ON 	  	 est.Event_Subtype_Id = v.Event_SubType_Id
 	  	 LEFT JOIN 	 Calculations calc 	  	 ON 	  	 calc.Calculation_Id = v.Calculation_Id   
 	  	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pls.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	  	 LEFT JOIN 	 User_Security vars 	 ON 	  	 pu.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE 	 COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2
 	 ORDER BY pl.PL_Desc, pu.PU_Order, pug.PUG_Order, v.PUG_Order
