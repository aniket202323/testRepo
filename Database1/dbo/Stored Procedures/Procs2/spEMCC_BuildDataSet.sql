CREATE PROCEDURE dbo.spEMCC_BuildDataSet
  @ListType int, @CalcId int, @id1 int, @id2 int, @id3 int, @str1 nvarchar(255), @str2 nvarchar(255), @User_Id int
AS
  DECLARE @OldCalc_Id integer 
  DECLARE @str4 nvarchar(255)
  if @id1 is null
    select @id1 = 0
  if @id2 is null
    select @id2 = 0
  if @id3 is null
    select @id3 = 0
/*
  if @str1 is null
    select @str1 = '(null)'
  if @str2 is null
    select @str2 = '(null)'
*/
if @ListType = 38
  begin
  create table #mason2 (calculation_id int, calculation_dependency_id int, dependency_name nvarchar(50), var_desc nvarchar(50), pu_desc nvarchar(50), calc_dependency_scope_name nvarchar(50), calc_dependency_scope_id int, var_id int, pu_id int, result_var_id int, optional bit)
  insert into #mason2 (calculation_id, calculation_dependency_id, dependency_name, var_desc, pu_desc, calc_dependency_scope_name, calc_dependency_scope_id, var_id, pu_id, result_var_id, optional)
  select ca.calculation_id, ca.calc_dependency_id, ca.name, v.var_desc, p.pu_desc, cs.calc_dependency_scope_name, ca.calc_dependency_scope_id, cd.var_id, v.pu_id, cd.result_var_id, ca.optional from calculation_dependencies ca
    left outer join calculation_dependency_data cd on cd.calc_dependency_id = ca.calc_dependency_id and result_var_id = @id1
    left outer join calculation_dependency_scopes cs on cs.calc_dependency_scope_id = ca.calc_dependency_scope_id
    left outer join variables v on v.var_id = cd.var_id
    left outer join prod_units p on p.pu_id = v.pu_id
    where ca.calculation_id = @CalcId
    order by ca.name
  insert into #mason2 (calculation_id, calculation_dependency_id, dependency_name, var_desc, pu_desc, calc_dependency_scope_name, calc_dependency_scope_id, var_id, pu_id, result_var_id, optional)
  select @str1, 0, '<Additional Dependency>', vs.var_desc, pu.pu_desc, cs.calc_dependency_scope_name, ci.calc_dependency_scope_id, vs.var_id, pu.pu_id, @id1, 1 from calculation_instance_dependencies ci
    join calculation_dependency_scopes cs on cs.calc_dependency_scope_id = ci.calc_dependency_scope_id
    join variables vs on vs.var_id = ci.var_id
    join prod_units pu on pu.pu_id = vs.pu_id
    where ci.result_var_id = @id1
  update #mason2
    set result_var_id = @id1
    where result_var_id is null
  update #mason2
    set var_desc = '<none>', pu_desc = '<none>', var_id = 0, pu_id = 0
    where var_id is null
  delete from #mason2 where result_var_id <> @id1
  select * from #mason2
  drop table #mason2
  end
else if @ListType = 82
  begin
    DECLARE @CalcInputs table  (alias nvarchar(50), input_name nvarchar(50), entity_name nvarchar(50), entity_id int, 
 	  	  	  	  	  	  	  	 attribute_name nvarchar(50), attribute_id int, optional bit, var_id int, result_var_id int, 
 	  	  	  	  	  	  	  	 calc_input_id int, default_value nvarchar(255) null, var_desc nvarchar(50), 
 	  	  	  	  	  	  	  	 constvaroth int Null, showcolumn tinyint, pu_id int Null, Equipment_Type nvarchar(255) Null,
 	  	  	  	  	  	  	  	 member_var_id Int Null,Non_Triggering bit,PU_Desc nvarchar(50))
    insert into @CalcInputs (alias, input_name, entity_name, entity_id, attribute_name, 
 	  	  	  	  	  	  	 attribute_id, optional, var_id, calc_input_id, default_value,
 	  	  	  	  	  	  	  var_desc,  result_var_id, showcolumn, pu_id,member_var_id,
 	  	  	  	  	  	  	 Non_Triggering,PU_Desc)
      select i.alias, i.input_name, e.entity_name, e.calc_input_entity_id, a.attribute_name, 
 	  	  	  a.calc_input_attribute_id, i.optional, v.var_id, i.calc_input_id, coalesce(d.default_value,i.default_Value),
 	  	  	  v.var_desc, d.result_var_id, e.show_on_input_variables, d.PU_Id,d.member_var_id,
 	  	  	  i.Non_Triggering,pu.PU_Desc
 	   from calculation_inputs i
        left outer join calculation_input_data d on (d.calc_input_id = i.calc_input_id) and (d.result_var_id = @id1)
        left outer join variables v on d.member_var_id = v.var_id
        left outer join calculation_input_entities e on (e.calc_input_entity_id = i.calc_input_entity_id) -- and (Show_On_Input_Variables = 1)
        left outer join calculation_input_attributes a on a.calc_input_attribute_id = i.calc_input_attribute_id
 	  	 Left Join prod_Units pu On pu.PU_Id = d.PU_Id
          where (i.calculation_id = @CalcId)
          order by i.Calc_Input_Order
    update @CalcInputs
       set constvaroth = 0
       where entity_id = 1 ---CONSTANT
    update @CalcInputs
       set constvaroth = 1 
       where (entity_id = 3) or (entity_id = 6) ----OTHER VARIABLE
    update @CalcInputs
       set constvaroth = 3,
 	     	    Var_Desc = Case When (Select coalesce(Alias_Name,'') 
 	  	  	  	  	  	  	  	  From calculation_input_data where calc_input_id = ci.calc_input_id and member_var_id = ci.member_var_id and Result_Var_Id =@id1 ) <> '' 
 	  	  	  	  	  	  	 Then Var_Desc + '[' + (Select coalesce(Alias_Name,'') 
 	  	  	  	  	  	  	 From calculation_input_data where calc_input_id = ci.calc_input_id 
 	  	  	  	  	  	  	  	  and member_var_id = ci.member_var_id and Result_Var_Id =@id1 ) + ']' Else '' End
 	  	 FROM @CalcInputs ci
       where entity_id = 7  ---- Genealogy Variable Alias
    update @CalcInputs
       set constvaroth = 4,
         Equipment_Type = PU_Desc
 	  	 FROM @CalcInputs ci
       where entity_id = 8  ---- Genealogy Event 
    update @CalcInputs
       set constvaroth = 4,
--         Equipment_Type = (Select coalesce(Alias_Name,'') From calculation_input_data where calc_input_id = ci.calc_input_id)
 	  	  	 Equipment_Type 	 = Case When (Select coalesce(Alias_Name,'') 
 	  	  	  	  	  	  	  	  From calculation_input_data where calc_input_id = ci.calc_input_id and PU_Id = ci.PU_Id and Result_Var_Id =@id1 ) <> '' 
 	  	  	  	  	  	  	 Then coalesce(PU_Desc,'') + '[' + (Select coalesce(Alias_Name,'') 
 	  	  	  	  	  	  	 From calculation_input_data cid
 	  	  	  	  	  	  	  where calc_input_id = ci.calc_input_id 
 	  	  	  	  	  	  	  	  and PU_Id = ci.PU_Id and Result_Var_Id =@id1 ) + ']' Else '' End
 	  	 FROM @CalcInputs ci
       where entity_id = 9 ---- Genealogy Event Alias
    update @CalcInputs
      set constvaroth= 2 -- was a 2 'rev mpr 1/4 
      where constvaroth is null
    delete from @CalcInputs
      where showcolumn = 0
  select * from @CalcInputs
  end
else if @ListType = 99
  begin
    Select Calc_Input_Id,Alias,Default_Value = isnull(Default_Value,'') from Calculation_Inputs Where Calculation_Id = @CalcId
      Order by Calc_Input_Order
  end
else
  select Error = 'Error!!!'
