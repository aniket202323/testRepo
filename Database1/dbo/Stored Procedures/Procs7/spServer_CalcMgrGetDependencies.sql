CREATE PROCEDURE dbo.spServer_CalcMgrGetDependencies
AS
Declare @CMGetDependecies Table(Calculation_id int NULL, Name nvarchar(50) COLLATE DATABASE_DEFAULT NULL, Calc_Dependency_scope_id int null,
 	  	  	 Optional tinyint null, Var_id int null, Result_var_id int null)
insert @CMGetDependecies(Calculation_id, Name, Calc_Dependency_scope_id, Optional, Var_id, Result_var_id)
Select  	 de.calculation_id, 
 	 de.name,
 	 de.calc_dependency_scope_id, 
 	 de.optional, 
 	 d.var_id,
 	 Result_Var_Id=v.var_id
from calculation_dependencies de 
join calculations c on c.calculation_id = de.calculation_id
join variables_base v on c.calculation_id = v.calculation_id
left outer join calculation_dependency_data d on d.calc_dependency_id  = de.calc_dependency_id and d.result_var_id=v.var_id
where v.is_active = 1
Order by de.calculation_id, Result_Var_Id
insert @CMGetDependecies(Calculation_id, Name, Calc_Dependency_scope_id, Optional, Var_id, Result_var_id)
select v.calculation_id, name='Instance Dependency',c.calc_dependency_scope_id,optional=0,c.var_id,c.result_var_id from 
Variables_Base v
join calculation_instance_dependencies c on result_var_id=v.var_id
where v.is_active = 1
delete from @CMGetDependecies where Calculation_id is null
select Calculation_id, Name, Calc_Dependency_scope_id, Optional, Var_id, Result_var_id from @CMGetDependecies
