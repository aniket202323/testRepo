/*
*/
CREATE FUNCTION dbo.fnServer_CalcMgrGetVarCalcVarsAffected(
@varid int,
@resultvarid int,
@id int
) 
     RETURNS @CMGCTResults TABLE (entityId int, attributeId int, varid int)
AS 
BEGIN -- Function
 	 -- Put info about the parameters to the calc so we look at them
 	 insert into @CMGCTResults(entityId, attributeId, varid)
 	 select i.Calc_Input_Entity_Id, i.Calc_Input_attribute_Id, d.member_var_id from 
 	 calculation_inputs i
 	 join calculation_input_data d on d.calc_input_id = i.calc_input_id
 	 where i.calculation_id = @id and d.result_var_id=@resultvarid --and d.member_var_id <> @varid
 	 -- Insert any dependencies into the table (translate scope into an equivalent attribute id
 	 insert into @CMGCTResults(entityId, attributeId, varid)
 	 select 3, 
 	   	  ScopeId = 
 	   	     CASE
 	   	       WHEN c.Calc_dependency_scope_Id = 1 THEN 8
 	   	       WHEN c.Calc_dependency_scope_Id = 3 THEN 9
 	   	       ELSE 7
 	   	     END,
 	 d.var_id from 
 	 calculation_dependencies c
 	 join calculation_dependency_data d on d.calc_dependency_id = c.calc_dependency_id 
 	 where d.result_var_id=@resultvarid and d.var_id = @varid
 	 -- Insert any instance dependencies into the table (translate scope into an equivalent attribute id
 	 insert into @CMGCTResults(entityId, attributeId, varid)
 	 select 3, 
 	   	  ScopeId = 
 	   	     CASE
 	   	       WHEN Calc_dependency_scope_Id = 1 THEN 8
 	   	       WHEN Calc_dependency_scope_Id = 3 THEN 9
 	   	       ELSE 7
 	   	     END,
 	 var_id from 
 	 calculation_instance_dependencies
 	 where result_var_id=@resultvarid and var_id = @varid
 	 
 	 RETURN
END
