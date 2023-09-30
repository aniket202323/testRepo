CREATE Procedure dbo.spEMEC_GetCustomModels
@PU_Id int,
@ETId int
AS
  select theId = ec_id, theDesc = Left('[' + Convert(nVarChar(10), m.model_num) + '] - '  + COALESCE(ec_desc,Model_desc),300),
 	  	  user_defined, Model_Id = c.ed_model_Id, Comment_Id = coalesce(c.comment_id, m.comment_id)
  from event_configuration c
  join ed_models m on m.ed_model_id = c.ed_model_id and m.et_id = @ETId and (m.model_num in (304,210,211,212) or m.derived_from in (304,210,211,212))
  where pu_Id = @PU_Id
