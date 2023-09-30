Create Procedure dbo.spEMEC_GetWasteModels
@PU_Id int,
@User_Id int
AS
Create Table #Model
(theId int, theDesc nvarchar(255), user_defined tinyint, Model_Id int NULL, Comment_Id int NULL)
Insert into #Model 
  select ec_id, COALESCE(ec_desc,Model_desc), user_defined, c.ed_model_Id, coalesce(c.comment_id, m.comment_id)
  from event_configuration c
  join ed_models m on m.ed_model_id = c.ed_model_id
  and m.et_id = 3
  where pu_Id = @PU_Id
Insert into #Model
  select ed_model_id * -1 as ed_model_id, model_desc, user_defined, ed_model_id, comment_Id
  from ed_models
  where et_id = 3 and user_defined = 0 and ed_model_id not in (select model_Id from #model where user_defined = 0)
select * from #model
drop table #model
