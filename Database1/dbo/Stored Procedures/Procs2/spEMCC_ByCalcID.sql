CREATE PROCEDURE dbo.spEMCC_ByCalcID
  @ListType int, @CalcID int, @User_Id int
AS
  if @CalcId is null
    select @CalcId = 0
if @ListType = 9 -- find variables affected by this calc
   select v.var_id, v.var_desc,  g.pug_desc, p.pu_desc, l.pl_desc
       From variables v
       left outer join pu_groups g on g.PUG_Id= v.PUG_Id
       left outer join prod_units p on p.pu_id = v.pu_id
       left outer join prod_lines l on l.pl_id = p.pl_id
          Where calculation_id like @CalcID
else if @ListType = 15
  select stored_procedure_name,[Lag_Time] = Coalesce(lag_Time,0),equation, [Max_Run_Time] = Coalesce(Max_Run_Time, 0) from calculations where calculation_id = @CalcID
else if @ListType = 23 --calculation inputs
  select Alias, input_name, entity_name, attribute_name, Optional, default_value = Coalesce(default_value,''),
 	  calc_input_id, calculation_id, ci.calc_input_entity_id, ci.calc_input_attribute_id,Non_Triggering
 	  from calculation_inputs ci
    join calculation_input_entities ce on ce.calc_input_entity_id = ci.calc_input_entity_id
    join calculation_input_attributes ca on ca.calc_input_attribute_id = ci.calc_input_attribute_id
    where ci.calculation_id = @CalcID
    order by ci.calc_input_order
else if @ListType = 30 -- NEW_GUID ***
    select cd.Calc_Dependency_Id, cd.Calculation_ID, cd.Name, cd.Calc_Dependency_Scope_Id, 
           cd.Optional, cs.Calc_Dependency_Scope_Id, cs.Calc_Dependency_Scope_Name 
      from calculation_dependencies cd
      join calculation_dependency_scopes cs on cs.calc_dependency_scope_id = cd.calc_dependency_scope_id
        where calculation_id = @CalcID
        order by name desc
else if @ListType = 92 -- NEW_GUID ***
  select  Equation, Stored_Procedure_Name,[Lag_Time] = coalesce(Lag_Time,0), [Max_Run_Time] = Coalesce(Max_Run_Time, 0)
   From calculations 
   Where calculation_id = @CalcID
else
  select Error = 'Error!!!'
