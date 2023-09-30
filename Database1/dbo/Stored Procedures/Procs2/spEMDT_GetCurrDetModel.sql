Create Procedure dbo.spEMDT_GetCurrDetModel
@EC_Id int,
@User_Id int
AS
select Model_desc = COALESCE(c.EC_Desc, m.Model_Desc), edf.ED_Field_Id, 
  m.model_num, c.is_active, 
  Comment_Id = 
   CASE 
     WHEN m.User_Defined = 1 THEN c.comment_Id
     ELSE m.Comment_Id
   END, m.user_defined, c.ed_model_Id,
   Fault_Mode_Id = isnull(ecv.Value,'0')
from ed_models m
join event_configuration c on c.ed_model_id = m.ed_model_id
Join ed_fields edf on m.ed_model_id = edf.ed_model_id and ED_Field_Type_Id = 62
left join event_configuration_data ecd on ecd.ec_id = @EC_Id and ecd.ed_field_id = edf.ED_Field_Id
left join event_configuration_values ecv on ecv.ecv_Id = ecd.ecv_Id
where c.ec_id = @EC_Id
