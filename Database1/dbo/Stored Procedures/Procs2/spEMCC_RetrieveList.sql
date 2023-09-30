CREATE PROCEDURE dbo.spEMCC_RetrieveList
  @ListType int, @User_Id int
AS
if @ListType = 10
  select ca.calculation_id, ca.calculation_name, ca.calculation_desc, ca.equation, ca.script, 
            ca.stored_procedure_name, VersionNum = ca.version, LockedInfo = ca.locked, 
            cmt_id = ca.comment_id, ca.trigger_type_id, calc_type_id = ca.calculation_type_id, ct.calculation_type_desc
    from calculations ca
    join calculation_types ct on ca.calculation_type_id = ct.calculation_type_id
    order by calculation_name desc
else if @ListType = 20
  select Calculation_Type_Id, Calculation_Type_Desc from calculation_types order by calculation_type_id
else if @ListType = 21
  begin
     create table #mason9 (calc_input_entity_id int, entity_name nvarchar(50), ordering int,Trigger_Type_Mask TinyInt)
     insert into #mason9 (calc_input_entity_id, entity_name,Trigger_Type_Mask)
       select calc_input_entity_id, entity_name,Trigger_Type_Mask from calculation_input_entities where user_interface = 1
     update #mason9
       set ordering = 1
          where entity_name like 'Other Variable'
     update #mason9
       set ordering = 0
          where ordering is null
     select * from #mason9 order by ordering desc,entity_name asc
     drop table #mason9
  end
else if @ListType = 22
  select cd.Calc_Input_Attribute_Id, cd.Calc_Input_Entity_Id, ca.Calc_Input_Attribute_Id, ca.Attribute_Name, 
            ce.Calc_Input_Entity_Id, ce.Entity_Name, ce.User_Interface, ce.Show_On_Input_Variables, ce.Locked 
    from calculation_input_entity_attribute_data cd
    join calculation_input_attributes ca on ca.calc_input_attribute_id = cd.calc_input_attribute_id
    join calculation_input_entities ce on ce.calc_input_entity_id = cd.calc_input_entity_id
    Order by ca.Attribute_Name
else if @ListType = 25
  select Calc_Dependency_Scope_Id, Calc_Dependency_Scope_Name from calculation_dependency_scopes
else if @ListType = 26 --add new input
  select Entity = e.entity_name, Attribute = a.attribute_name, Optional = 0, Def = "", Input_Id = 0, 
 	  	  Entity_Id = e.calc_input_entity_id, Attribute_Id = a.calc_input_attribute_id,Non_Triggering = 0
 	 from calculation_input_entities e
    join calculation_input_entity_attribute_data ea on ea.calc_input_entity_id = e.calc_input_entity_id
    join calculation_input_attributes a on a.calc_input_attribute_id = ea.calc_input_attribute_id
    where ea.calc_input_attribute_id = 7 and ea.calc_input_entity_id = 3 -- att_id = 7 revised 12/29
    Order by Attribute
else if @ListType = 79 -- list of triggers, default trigger must be 1st row in recordset
  select name, trigger_type_id from calculation_trigger_types order by trigger_type_id 
else if @ListType = 90
  select sp_name = substring(name,9,246) 
   from sysobjects 
   where name like 'spLocal_%' 
   Order By sp_name
else if @ListType = 91
  select var_desc, var_id 
 	 from Variables 
 	 Where PU_Id <> 0
 	 order by var_desc
else if @ListType = 99
  select calculation_name from calculations 
else
  select Error = 'Error!!!'
