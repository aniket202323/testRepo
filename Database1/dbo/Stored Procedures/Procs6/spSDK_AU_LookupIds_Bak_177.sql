CREATE procedure [dbo].[spSDK_AU_LookupIds_Bak_177]
 	 @Department 	  	  	  	  	 varchar(200) = Null 	  	 OUTPUT,
 	 @DepartmentId 	  	  	  	 int 	  = Null 	  	  	  	  	  	 OUTPUT,
 	 @ProductionLine 	  	  	 VarChar(50) = Null 	  	 OUTPUT,
 	 @ProductionLineId 	  	 int = Null 	  	  	  	  	  	 OUTPUT,
 	 @ProductionUnit 	  	  	 VarChar(50) = Null 	  	 OUTPUT,
 	 @ProductionUnitId 	  	 int = Null 	  	  	  	  	  	 OUTPUT,
 	 @VariableGroup 	  	  	 VarChar(50) = Null 	  	 OUTPUT,
 	 @VariableGroupId 	  	 int = Null 	  	  	  	  	  	 OUTPUT,
 	 @Variable 	  	  	  	  	  	 VarChar(50) = Null 	  	 OUTPUT,
 	 @VariableId 	  	  	  	  	 int = Null
AS
If @VariableId IS Not Null
BEGIN
 	 SELECT 	 @Variable = Var_Desc,
 	  	  	  	  	 @VariableGroup = b.PUG_Desc,
 	  	  	  	  	 @VariableGroupId = b.PUG_Id,
 	  	  	  	  	 @ProductionUnit = c.PU_Desc,
 	  	  	  	  	 @ProductionUnitId = c.PU_Id,
 	  	  	  	  	 @ProductionLine = d.PL_Desc,
 	  	  	  	  	 @ProductionLineId = d.PL_Id,
 	  	  	  	  	 @Department = e.Dept_Desc,
 	  	  	  	  	 @DepartmentId = e.Dept_Id
 	  	 from Variables_Base as a
 	  	 JOIN PU_Groups b 	  	 ON b.PUG_Id = a.PUG_Id 
 	  	 JOIN Prod_Units_Base c 	  	 ON c.PU_Id = a.PU_Id 
 	  	 JOIN Prod_Lines_Base d 	  	 ON d.PL_Id = c.PL_Id
 	  	 JOIN Departments_Base e 	 ON e.Dept_Id = d.Dept_Id  
 	  	 WHERE Var_Id = @VariableId
END
ELSE
If @VariableGroupId IS Not Null
BEGIN
 	 SELECT 	 @VariableGroup = b.PUG_Desc,
 	  	  	  	  	 @ProductionUnit = c.PU_Desc,
 	  	  	  	  	 @ProductionUnitId = c.PU_Id,
 	  	  	  	  	 @ProductionLine = d.PL_Desc,
 	  	  	  	  	 @ProductionLineId = d.PL_Id,
 	  	  	  	  	 @Department = e.Dept_Desc,
 	  	  	  	  	 @DepartmentId = e.Dept_Id
 	  	 FROM  PU_Groups b 	 
 	  	 JOIN Prod_Units_Base c 	  	 ON c.PU_Id = b.PU_Id 
 	  	 JOIN Prod_Lines_Base d 	  	 ON d.PL_Id = c.PL_Id
 	  	 JOIN Departments_Base e 	 ON e.Dept_Id = d.Dept_Id  
 	  	 WHERE b.PUG_Id  = @VariableGroupId
END
ELSE
If @ProductionUnitId IS Not Null
BEGIN
 	 SELECT 	 @ProductionUnit = c.PU_Desc,
 	  	  	  	  	 @ProductionLine = d.PL_Desc,
 	  	  	  	  	 @ProductionLineId = d.PL_Id,
 	  	  	  	  	 @Department = e.Dept_Desc,
 	  	  	  	  	 @DepartmentId = e.Dept_Id
 	  	 FROM  Prod_Units_Base c
 	  	 JOIN Prod_Lines_Base d 	  	 ON d.PL_Id = c.PL_Id
 	  	 JOIN Departments_Base e 	 ON e.Dept_Id = d.Dept_Id  
 	  	 WHERE c.PU_Id  = @ProductionUnitId
END
ELSE
If @ProductionLineId IS Not Null
BEGIN
 	 SELECT 	 @ProductionLine = d.PL_Desc,
 	  	  	  	  	 @Department = e.Dept_Desc,
 	  	  	  	  	 @DepartmentId = e.Dept_Id
 	  	 FROM  Prod_Lines_Base d
 	  	 JOIN Departments_Base e 	 ON e.Dept_Id = d.Dept_Id  
 	  	 WHERE d.PL_Id  = @ProductionLineId
END
ELSE
If @DepartmentId IS Not Null
BEGIN
 	 SELECT 	 @Department = e.Dept_Desc
 	  	 FROM   Departments_Base e
 	  	 WHERE e.Dept_Id  = @DepartmentId
END
