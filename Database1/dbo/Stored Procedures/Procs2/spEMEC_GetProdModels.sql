Create Procedure dbo.spEMEC_GetProdModels
@ET_Id int,
@PU_Id int,
@User_Id int
as
select ed_model_id, model_desc
from ed_models
where ed_models.et_id = @ET_Id
order by model_desc
select ec_id, ed_model_id
from event_configuration
where et_id = @ET_Id
and pu_id = @PU_Id
