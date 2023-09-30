Create Procedure dbo.spEMEC_GetAvailableModels
@ET_Id int,
@ED_Model_Id int = Null,
@User_Id int
as
if @ED_Model_Id is Null
 select @ED_Model_Id = 0
create table #AvailableModels(
  ED_Model_Id int,
  ModelNum int,
  ModelDesc nvarchar(255),
  User_Defined nVarChar(10),
  Override_Module_Id tinyint
)
insert into #AvailableModels
select ed_model_id, model_num, model_desc,
User_Defined = CASE
WHEN user_defined > 0 THEN 'Yes'
ELSE 'No'
END,
override_module_id
from ed_models
where (ed_models.et_id = @ET_Id or (Derived_From  Between 600 and 607 and  @ET_Id = 14)) --UDE = 14, Generic = 15 (Defect #20738) (changed for ticket 27263 to only allow derived)
and ED_Model_Id <> 49000
order by Model_Num
select * from #AvailableModels
drop table #AvailableModels
