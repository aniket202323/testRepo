CREATE Procedure dbo.spEMEPC_GetProdModels
@ET_Id int,
@PU_Id int,
@User_Id int,
@PEI_Id int = NULL
as
select ed_model_id, model_desc,is_Derived = case when Derived_From is null then 0 else 1 end
from ed_models
where ed_models.et_id = @ET_Id
order by model_desc
select ec_id, ed_model_id, Is_Active
from event_configuration
where et_id = @ET_Id
and pu_id = @PU_Id
and pei_id = @PEI_Id
