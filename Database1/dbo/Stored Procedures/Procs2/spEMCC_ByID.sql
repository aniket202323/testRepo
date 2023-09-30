CREATE PROCEDURE dbo.spEMCC_ByID
  @ListType int, 
  @id int, 
  @User_Id int,
  @IsAlias  	  	 Int = 0
AS
  if @id is null
    select @id = 0
Select @IsAlias = Coalesce(@IsAlias,0)
if @ListType = 1
    select v.var_desc, p.pu_desc from variables v
      join prod_units p on p.pu_id = v.pu_id where var_id = @id
else if @ListType = 24
  begin  --mpr 1/4 start
     create table #mason987 (calc_input_attribute_id int, attribute_name nvarchar(50), ordering int)
     insert into #mason987 (calc_input_attribute_id, attribute_name)
       select distinct ca.calc_input_attribute_id, ca.attribute_name from calculation_input_attributes ca --where user_interface = 1
          join calculation_input_entity_attribute_data ci on ci.Calc_Input_Attribute_Id = ca.Calc_Input_Attribute_Id
           where ci.Calc_Input_entity_Id = @id
     update #mason987
       set ordering = 1
          where attribute_name like 'This Value'
     update #mason987
       set ordering = 0
          where ordering is null
     select * from #mason987 order by ordering desc,attribute_name asc
     drop table #mason987
  end --mpr 1/4 end
else if @ListType = 39
    select v.var_desc, v.var_id,i.result_var_id,d.result_var_id from variables v
      left outer join calculation_dependency_data d on d.var_id = v.var_id
      left outer join calculation_instance_dependencies i on i.var_id = v.var_id
      where (d.result_var_id  <> @id or d.result_var_id is null) 
         and (i.result_var_id <> @id or i.result_var_id is null)
 	  and PU_Id <> 0
      order by v.var_desc
else if @ListType = 85
  select p.pu_desc, p.pu_id from prod_units p 
    where p.pu_id = (select v.pu_id from variables v where v.var_id = @id)
else if @ListType = 95
  select calculation_id from variables where var_id = @id
else if @ListType = 100
  begin
    declare @tmpInt int, @tmpStr nvarchar(255)
    select @tmpStr = ''
 	 If @IsAlias = 1
     	 select @tmpStr = Coalesce(Test_Name,Var_Desc), @tmpInt = pug_id from variables where var_id = @id
 	 Else
     	 select @tmpStr = Var_Desc, @tmpInt = pug_id from variables where var_id = @id
    select @tmpStr = PUG_Desc + '\' + @tmpStr, @tmpInt = PU_Id from PU_Groups where PUG_Id = @tmpInt
    select @tmpStr = PU_Desc + '\' + @tmpStr, @tmpInt = PL_Id from Prod_Units where PU_Id = @tmpInt
    select @tmpStr = PL_Desc + '\' + @tmpStr from Prod_Lines where PL_Id = @tmpInt
    select var_path = @tmpStr
  end
else
  select Error = 'Error!!!'
