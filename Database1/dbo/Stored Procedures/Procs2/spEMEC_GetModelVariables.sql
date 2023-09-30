Create Procedure dbo.spEMEC_GetModelVariables
@ED_Model_Id int,
@EC_Id int,
@User_Id int
as
If @EC_Id = 0 
  Select @EC_Id  = NULL
If @ED_Model_Id = 0
BEGIN
  Select @ED_Model_Id  = NULL
  Select @ED_Model_Id  = ed_model_Id From Event_Configuration WHERE ec_id = @EC_Id
END
 Select d.Alias, d.PU_Id, Convert(nvarchar(255), v.value) as value, a.Attribute_Desc, s.ST_Desc, d.IsTrigger, d.Sampling_Offset, d.Input_Precision,
        pl.pl_desc, pu.pu_desc, pg.pug_desc, var.var_desc, ds.ds_desc
    From ed_fields f 
    Join ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
    Join event_configuration c on  ec_id = @ec_id
    Join event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
    Join event_configuration_values v on v.ecv_id = d.ecv_id
    Join variables var on var.var_id = Convert(nvarchar(255), v.value)
    Join prod_units pu on pu.pu_id = var.pu_id
    Join prod_lines pl on pl.pl_id = pu.pl_id
    Join pu_groups pg on pg.pug_id = var.pug_id
    Join data_source ds on ds.ds_id = var.ds_id
   	 Left Join ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
   	 Left Join sampling_type s on s.ST_Id = d.St_Id
    Where f.ed_model_Id = @ed_model_id
    And f.ed_field_type_id = 10 	 --Variable
   	 Order By len(Alias), Alias, var.var_desc
