Create Procedure dbo.spEMEC_GetAvailableEvents
@PU_Id int,
@User_Id int
as
declare @ET_Id as int,
@Count as int,
@Event_Models int
create table #EventsAvailable(
  ET_Id int,
  Event_Type nvarchar(50),
  Name nvarchar(50),
  Multiple nVarChar(10),
  Models_Apply nVarChar(10),
  Comment nvarchar(255),
  Event_Subtype_Id int,
  SubTypes_Apply tinyint,
  Module_Id int,
  GenealogyModel Int
)
insert into #EventsAvailable
select t.et_id, et_desc, event_subtype_desc, 'No', 
event_models = CASE
WHEN event_models > 0 THEN 'Yes'
ELSE 'No'
END, 
comment_text = coalesce(substring(c.comment_text,1,255),et_desc) ,
event_subtype_id,
subtypes_apply,
module_id,
GenealogyModel = Case When t.Single_Event_Configuration is null Then 0 Else  t.Single_Event_Configuration End
from event_types t
left join event_subtypes s on t.et_id = s.et_id
left join comments c on s.comment_id = c.comment_id
where t.event_models > 0
update #EventsAvailable set #EventsAvailable.Multiple = 'Yes'
from #EventsAvailable
join event_types on event_types.et_id = #EventsAvailable.et_id
where event_types.event_models > 1
Declare ECCursor Cursor For
  Select ET_Id from #EventsAvailable for read only
Open ECCursor
While (0=0) Begin
  Fetch Next
    From ECCursor
    Into @ET_Id
  If (@@Fetch_Status <> 0) Break
  select @Event_Models = event_models
  from event_types
  where et_id = @ET_Id
  select @Count = count(*) --, ec_desc, e.ed_model_id, m.et_id
  from event_configuration e
  left outer join ed_models m on m.ed_model_id = e.ed_model_id
  where pu_id = @PU_Id
  and e.et_id = @ET_Id
  if @Count > 0 and @Event_Models < 2
    Begin
      delete from #EventsAvailable
      where ET_Id = @ET_Id
    End
End
Close ECCursor
Deallocate ECCursor
delete from #EventsAvailable
where SubTypes_Apply = 1 and Event_Subtype_Id is NULL
select * from #EventsAvailable
order by ET_Id
drop table #EventsAvailable
