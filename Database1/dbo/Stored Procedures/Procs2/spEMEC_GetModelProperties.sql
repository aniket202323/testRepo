CREATE Procedure dbo.spEMEC_GetModelProperties
@ED_Model_Id int,
@EC_Id int,
@User_Id int
AS 
If @ED_Model_Id = 0 
  Select @ED_Model_Id  = NULL
If @EC_Id = 0 
  Select @EC_Id  = NULL
 Select f.ED_Model_Id, PU_Id=0, c.EC_Id, f.ed_field_id, f.ed_field_type_id, Property=f.field_desc, Type=t.field_type_desc, 
  Value = CASE 
    WHEN t.Prefix IS NULL THEN CONVERT(nvarchar(255),v.value)
    ELSE SUBSTRING(CONVERT(nvarchar(255),v.value),DATALENGTH(t.Prefix) + 1,255)
  END, f.comment_id, comment=CONVERT(nvarchar(255),co.comment_text), t.sp_lookup, t.Store_Id, f.max_instances, locked = coalesce(f.locked,0),Table_Id = 1,f.field_order
    from ed_fields f 
    join ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
    left join  event_configuration c on  ec_id = @ec_id
    left join event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
    left join event_configuration_values v on v.ecv_id = d.ecv_id 
    left join comments co on co.comment_id = f.comment_id 
    where f.ed_model_Id = @ed_model_id 
union
 Select f.ED_Model_Id, PU_Id=0, c.EC_Id, ed_field_id = f.ED_Field_Prop_Id, f.ED_Field_Type_Id, Property=f.field_desc, 
  	  Type=t.field_type_desc,  Value = CASE  WHEN ecp.value Is Null Then f.Default_Value
  	    	    	    	    	    	    	    	    	   Else ecp.value
    	    	    	    	    	    	    	    	    	  END  	  , 
  	  comment_id = null, comment = null, t.sp_lookup, t.Store_Id,max_instances = 1,  locked = coalesce(f.locked,0),Table_Id = 2, Field_Order = f.ED_Field_Prop_Id
    from ED_Field_Properties f 
    join ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
    left join  event_configuration c on  ec_id = @ec_id
  	  Left Join event_configuration_Properties ecp on ecp.ec_id = c.ec_id and ecp.ED_Field_Prop_Id = f.ED_Field_Prop_Id
    where f.ed_model_Id = @ed_model_id
order by Table_Id , field_order 
