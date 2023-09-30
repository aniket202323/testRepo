Create Procedure dbo.spEMEC_GetModelCommentId
@ED_Model_Id int,
@User_Id int,
@Comment_Id int OUTPUT
as
select @Comment_Id = Null
select @Comment_Id = comment_id
from ed_models
where ed_model_id = @ED_Model_Id
