Create Procedure dbo.spEMEC_GetMasterEventList
@User_Id int
as
Declare @Insert_Id int
create table #MasterEventList(
  ET_Id int,
  Event_Subtype_Id int,
  EventType nvarchar(255),
  Name nvarchar(255),
  UserDefined nVarChar(10),
  Subtype nVarChar(10),
  Models nVarChar(10),
  Comment_Id int,
  Comment nvarchar(255),
  SubTypes_Apply tinyint
)
insert into #MasterEventList (ET_Id,Event_Subtype_Id,EventType,Name,UserDefined,Subtype,Models,Comment_Id,Comment,SubTypes_Apply)
select et.et_id, es.event_subtype_id, et.et_desc, coalesce(es.event_subtype_desc,''), 
 UserDefined = CASE 
   WHEN et.user_configured = 1 THEN 'Yes'
   ELSE 'No'
 END,
 Subtype = CASE 
   WHEN et.subtypes_apply = 1 THEN 'Yes'
   ELSE 'No'
 END,
 Models = CASE 
   WHEN et.event_models = 1 THEN 'Yes'
   ELSE 'No'
 END,
es.comment_id, coalesce(Substring(c.comment_text,1,255),et.et_desc), et.subtypes_apply
from event_types et
left join event_subtypes es on es.et_id = et.et_id
Left Join comments c on c.comment_Id = es.comment_Id
where et.event_models > 0 and SubTypes_Apply = 1
delete from #MasterEventList where SubTypes_Apply = 1 and Event_Subtype_Id is NULL
select * from #MasterEventList
order by EventType, Name
drop table #MasterEventList
