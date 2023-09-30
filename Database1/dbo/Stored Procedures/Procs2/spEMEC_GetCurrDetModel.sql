Create Procedure dbo.spEMEC_GetCurrDetModel
@EC_Id int,
@User_Id int
AS
select Model_desc = COALESCE(c.EC_Desc, m.Model_Desc), 
  m.model_num, c.is_active, 
  Comment_Id = 
   CASE 
     WHEN m.User_Defined = 1 THEN c.comment_Id
     ELSE m.Comment_Id
   END, m.user_defined, c.ed_model_Id
from ed_models m
join event_configuration c on c.ed_model_id = m.ed_model_id
where ec_id = @EC_Id
