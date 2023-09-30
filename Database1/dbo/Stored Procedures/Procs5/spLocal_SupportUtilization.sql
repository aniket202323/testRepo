    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE   procedure dbo.spLocal_SupportUtilization  
  
--Declare  
 @StartTime as datetime,  
 @EndTime as datetime  
  
 As  
SET NOCOUNT ON  
  
Declare  
 @strOpen as varchar(25),  
 @strNoDeviation as VarChar(25),  
 @IntTotalStops as float,  
 @IntEditStops as float,  
 @LngEditStopsPer as float  
  
  
  
--select @StartTime = '2005-09-01 07:30:00'  
--select @EndTime = '2005-09-07 07:30:00'  
  
  
Select @strOpen = 'Open'  
--lpt.Translated_Text from local_PG_Translations lpt  
--Join Local_PG_Languages lpl on lpl.Language_ID = lpt.Language_ID  
--where lpt.Global_Text = 'Open'  
--and lpl.Is_Active = 1  
  
Select @strNoDeviation = 'No Deviation'  
--lpt.Translated_Text from local_PG_Translations lpt  
--Join Local_PG_Languages lpl on lpl.Language_ID = lpt.Language_ID  
--where lpt.Global_Text = 'No Deviation'  
--and lpl.Is_Active = 1  
  
  
DECLARE @OutputData TABLE(TypeDesc varchar(50), TypeCount int)  
DECLARE @Dt TABLE(tedet_id int, Reason_Level1 int, Reason_Level2 int, Reason_Level3 int, Reason_Level4 int, Edited varchar(3))  
  
Insert into @OutputData (TypeDesc,TypeCount) --values ('Total Alarms',0)  
select 'Total Alarms', count(*) from [dbo].Tests t  
Join [dbo].Variables v on v.Var_ID = t.Var_ID  
where t.result_on > @StartTime  
and t.result_on < @EndTime  
and v.extended_info in ('RPT=OOSSTAT','RPT=STATReEvA','RPT=STATREEVV')  
  
Insert into @OutputData (TypeDesc,TypeCount) --values ('Open Alarms',0)  
select 'Open Alarms',count(*)  from [dbo].Tests t  
Join [dbo].Variables v on v.Var_ID = t.Var_ID  
where t.result_on > @StartTime  
and t.result_on < @EndTime  
and v.extended_info in ('RPT=OOSSTAT','RPT=STATReEvA','RPT=STATREEVV')  
and t.result = @strOpen  
  
Insert into @OutputData (TypeDesc,TypeCount) --values ('Closed Alarms',0)  
select 'Closed Alarms',count(*) from [dbo].Tests t  
Join [dbo].Variables v on v.Var_ID = t.Var_ID  
where t.result_on > @StartTime  
and t.result_on < @EndTime  
and v.extended_info in ('RPT=OOSSTAT','RPT=STATReEvA','RPT=STATREEVV')  
and t.result <> @strNoDeviation and t.result <> @strOpen  
  
Insert into @OutputData (TypeDesc,TypeCount) --values ('Closed by Typo',0)  
select 'Closed by Typo',count(*)  from [dbo].Tests t  
Join [dbo].Variables v on v.Var_ID = t.Var_ID  
where t.result_on > @StartTime  
and t.result_on < @EndTime  
and v.extended_info in ('RPT=OOSSTAT','RPT=STATReEvA','RPT=STATREEVV')  
and t.result = @strNoDeviation  
  
Insert into @OutputData (TypeDesc,TypeCount) --values ('RTT Open Alarms',0)  
select 'RTT Open Alarms',count(*)  from [dbo].alarms a  
join [dbo].variables v on v.var_id = a.key_id  
join [dbo].prod_units pu on pu.pu_id = v.pu_id  
where pu.pu_desc like '%RTT%'  
and a.end_time is null  
--and a.start_time > @StartTime  
  
Insert into @OutputData (TypeDesc,TypeCount) values ('RTT Compliance (Not done)',0)  
select @IntTotalStops = count(*) from [dbo].timed_Event_Details ted  
Join [dbo].Prod_units pu on pu.pu_id = ted.source_pu_id  
where ted.start_time > @StartTime  
and ted.end_time < @EndTime  
and pu.pu_desc not like '%Packer%'  
--need to join location/and the associated reason tree.    
--Then look at the last level of the tree to see if they edit the tree  
  
insert into @Dt(tedet_id, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Edited)   
select tedet_id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,'Yes'    
From [dbo].timed_Event_Details ted  
Join [dbo].Prod_units pu on pu.pu_id = ted.source_pu_id  
where ted.start_time > @StartTime  
and ted.end_time < @EndTime  
and pu.pu_desc not like '%Packer%'  
  
Update @Dt  
        set Edited = 'No'  
Where Reason_Level1 Is Null  
  
Update @Dt  
        set Edited = 'No'  
From @Dt dt   
Join [dbo].Event_Reason_Tree_Data ertd on dt.Reason_Level1 = ertd.parent_event_reason_id  
Where event_reason_level = 2 and Reason_Level2 Is Null  
  
Update @Dt  
        set Edited = 'No'  
From @Dt dt   
Join [dbo].Event_Reason_Tree_Data ertd on dt.Reason_Level2 = ertd.parent_event_reason_id  
Where event_reason_level = 3 and Reason_Level3 Is Null  
  
Update @Dt  
        set Edited = 'No'  
From @Dt dt   
Join [dbo].Event_Reason_Tree_Data ertd on dt.Reason_Level3 = ertd.parent_event_reason_id  
Where event_reason_level = 4 and Reason_Level4 Is Null  
  
select @IntTotalStops = count(*) from @Dt  
select @IntEditStops = count(*) from @Dt where Edited = 'Yes'  
  
/*select @IntEditStops = count(*) from timed_Event_Details ted  
Join Prod_units pu on pu.pu_id = ted.source_pu_id  
where ted.start_time > @StartTime  
and ted.end_time < @EndTime  
and pu.pu_desc not like '%Packer%'  
and ted.Reason_Level4 is not null  
*/  
  
IF @IntTotalStops <> 0  
Begin  
 Insert into @OutputData (TypeDesc,TypeCount)  
 Select 'RE % Edits', @IntEditStops / @IntTotalStops * 100  
END  
ELSE  
BEGIN  
 Insert into @OutputData (TypeDesc,TypeCount)  
 Select 'RE % Edits', 0  
End  
  
Insert into @OutputData (TypeDesc,TypeCount)  
Select 'Reports Runs', count(*) from [dbo].Report_Runs  
where Start_Time >= @StartTime  
and End_Time <= @EndTime  
  
Insert into @OutputData (TypeDesc,TypeCount)  
Select 'Reports Hits',count(*) from [dbo].Report_Hits  
where HitTime >= @StartTime  
and HitTime <= @EndTime   
  
Select TypeDesc, TypeCount from @OutputData  
  
SET NOCOUNT OFF  
  
  
