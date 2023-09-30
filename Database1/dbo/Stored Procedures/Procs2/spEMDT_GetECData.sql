CREATE PROCEDURE  dbo.spEMDT_GetECData
 	 @EcId 	  	 Int,
 	 @PUId 	  	 Int,
 	 @User_Id 	 int
 AS
Select Alias , d.PU_Id, value = substring(convert(nvarchar(255),Value),4,LEN(convert(nvarchar(255),Value))),Attribute_Desc, ST_Desc, IsTrigger, Sampling_Offset, Input_Precision
  From ed_fields f 
  Join ed_fieldtypes t on f.ed_field_type_id = t.ed_field_type_id 
  Join event_configuration c on  ec_id = @EcId
  Join event_configuration_data d on d.ec_id = c.ec_id and d.ed_field_id = f.ed_field_id 
 	 Join event_configuration_values v on v.ecv_id = d.ecv_id
 	 Join ed_attributes a On d.ED_Attribute_Id = a.ED_Attribute_Id
 	 Join sampling_type s on s.ST_Id = d.St_Id
 	 Where c.EC_Id = @EcId and d.PU_Id = @PUId
  And f.ed_field_type_id = 3 	 --Tag
 	 Order by len(Alias),Alias
