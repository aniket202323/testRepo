/*
set nocount on
exec spRS_GetEventsByECId '54,141,4,1'
*/
CREATE PROCEDURE dbo.spRS_GetEventsByECId
 	 @EC_ID varchar(1000)
AS
Declare @EC_Table table(Order_Id int, EC_ID int)
insert into @EC_Table select * from fnRS_MakeOrderedResultSet(@EC_ID)
select ec_Id, pu_desc + '->' + et.et_desc + case when et2.et_desc is not null then ' (' + et2.et_desc + ')' else '' end as [Event_Desc]
from event_configuration ec 
Left JOin Prod_Units pu on pu.pu_id = ec.pu_id
Left Join Event_Types et on et.et_id = ec.et_Id
Left Join Event_Types et2 on et2.et_Id = ec.event_subtype_Id
Left jOin ED_Models ed on ed.ed_model_Id = ec.ed_model_id
where ec.ec_id in (Select EC_ID From @EC_Table)
order by pu_desc, et.et_desc
