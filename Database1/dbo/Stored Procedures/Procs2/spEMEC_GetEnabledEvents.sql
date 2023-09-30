Create Procedure dbo.spEMEC_GetEnabledEvents
@PU_Id int,
@User_Id int
as
create table #EventsEnabled(
  ET_Desc nvarchar(255),
  Name nvarchar(50),
  Description nvarchar(255),
  Model_Num int,
  Active nVarChar(10),
  Comment_Id int,
  EC_Id int,
  User_Configured Int,
  Event_Subtype_Id int,
  ET_Id int,
  ED_Model_Id int,
  Comment nvarchar(255),
  Derived_From int,
  Allow_Query Int,
  GenealogyModel Int,
  Priority 	 Int,
  Debug 	  	 Int
)
insert into #EventsEnabled
Select ET_Desc, 
 Name = CASE 
   WHEN c.Event_Subtype_Id IS NOT NULL THEN s.Event_Subtype_Desc
   ELSE ''
 END,
 Description = CASE 
   WHEN c.ED_Model_Id IS NOT NULL and m.User_Defined = 0 THEN m.Model_Desc 
   ELSE COALESCE(EC_Desc, '')
 END,
 Model_Num, 
 Active = CASE
   WHEN c.Is_Active = 1 THEN 'Yes'
   ELSE 'No'
 END, 
 Comment_Id = CASE
   WHEN c.ED_Model_Id IS NOT NULL and m.User_Defined = 0 THEN isnull(c.Comment_Id,m.Comment_Id) 
   ELSE c.Comment_Id
 END,
 c.EC_Id,
 t.User_Configured,
 c.Event_Subtype_Id, 
 c.ET_Id, 
 c.ED_Model_Id,
 Null,
 m.Derived_From,
 Allow_Query = Case When t.AllowDataView is null Then 0 Else  t.AllowDataView End,
 GenealogyModel = Case When t.Single_Event_Configuration is null Then 0 Else  t.Single_Event_Configuration End,
 c.Priority,
 Debug = Coalesce(Debug,0)
  From Event_Configuration c
  Join Event_Types t on c.ET_Id = t.ET_Id -- and Event_Models > 0 allow change to genealogy models (for priority)
  left outer Join Event_SubTypes s on c.Event_Subtype_Id = s.Event_Subtype_Id
  left outer Join ED_Models m on c.ed_model_id = m.ed_model_Id
  Where c.PU_Id = @PU_Id
update #EventsEnabled set #EventsEnabled.Comment = Coalesce(SubString(c.Comment_Text, 1, 255), '')
from #EventsEnabled
left outer join comments c on c.comment_id = #EventsEnabled.Comment_Id 
select * from #EventsEnabled
order by Priority,Model_Num
drop table #EventsEnabled
