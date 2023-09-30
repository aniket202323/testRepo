CREATE Procedure dbo.spDBR_AlarmCount
@VariableList text = NULL,
@StartTime1 datetime,
@EndTime1 datetime,
@StartTime2 datetime,
@EndTime2 datetime,
@StartTime3 datetime,
@EndTime3 datetime,
@FilterNonProductiveTime int = 0,
@InTimeZone varchar(200)=NULL
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Select @VariableList = '<Root></Root>'
Select @StartTime1 = '1-jul-2000'
Select @EndTime1 = '1-1-2002'
Select @StartTime2 = '1-1-2002'
Select @EndTime2 = '1-1-2004'
Select @StartTime3 = '1-1-2001'
Select @EndTime3 = '1-1-2005'
--*****************************************************/
--*****************************************************/
--Build List Of Variables
--*****************************************************/
Create Table #Variables (
  VariableName varchar(100) NULL,
  Item int
)
create table #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
create table #Units
(
   PU_Id int
)
--TODO: Create Index
if (not @VariableList like '%<Root></Root>%' and not @VariableList is NULL)
  begin
    if (not @VariableList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'Item;' + Convert(nvarchar(4000), @VariableList)
      Insert Into #Variables (Item) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
    insert into #Variables EXECUTE spDBR_Prepare_Table @VariableList
    end
  end
Else
  Begin
    Insert Into #Variables (Item) 
      Select distinct var_id From alarm_template_var_data     
  End
insert into #Units select distinct(pu_id) from Variables a, #Variables b where a.var_id = b.item
--*****************************************************/
Declare @HighCountIcon int 
Declare @HighCount1 int
Declare @HighCount2 int
Declare @HighCount3 int
Declare @MediumCountIcon int
Declare @MediumCount1 int
Declare @MediumCount2 int
Declare @MediumCount3 int
Declare @LowCountIcon int
Declare @LowCount1 int
Declare @LowCount2 int
Declare @LowCount3 int
Select @HighCount1 = 0
Select @HighCount2 = 0
Select @HighCount3 = 0
Select @MediumCount1 = 0
Select @MediumCount2 = 0
Select @MediumCount3 = 0
Select @LowCount1 = 0
Select @LowCount2 = 0
Select @LowCount3 = 0
create table #AlarmCount
(
  AlarmType int,
  StartTime datetime,  
  EndTime datetime,
  AlarmId int,
  VarId int,
  EventId int,
  UnitId int
)
declare @curPU_Id int
Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
 	 For (
 	 Select PU_Id From #Units
 	 )
 	  For Read Only
declare @curStartTime datetime, @curEndTime datetime
Declare TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select PU_Id, StartTime, EndTime From #ProductiveTimes
      )
  For Read Only
--Time Zone conversions
SELECT @StartTime1 = dbo.fnServer_CmnConvertToDBTime(@StartTime1,@InTimeZone)
SELECT @EndTime1 = dbo.fnServer_CmnConvertToDBTime(@EndTime1,@InTimeZone)
SELECT @StartTime2 = dbo.fnServer_CmnConvertToDBTime(@StartTime2,@InTimeZone)
SELECT @EndTime2 = dbo.fnServer_CmnConvertToDBTime(@EndTime2,@InTimeZone)
SELECT @StartTime3 = dbo.fnServer_CmnConvertToDBTime(@StartTime3,@InTimeZone)
SELECT @EndTime3 = dbo.fnServer_CmnConvertToDBTime(@EndTime3,@InTimeZone)
--*****************************************************/
--Get First Time Period Alarms
--*****************************************************/
/*if (@FilterNonProductiveTime = 1)
begin
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time >= @StartTime1 and end_time <= @EndTime1
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time < @StartTime1 and End_Time between @StartTime1 and @Endtime1
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime1 or End_Time is null) and Start_Time between @StartTime1 and @EndTime1
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime1 or End_Time is null) and @StartTime1 > Start_Time
end
else
begin
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select PU_ID, @StartTime1, @EndTime1 from #units
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
update #ProductiveTimes set StartTime = @StartTime1 where StartTime < @StartTime1
update #ProductiveTimes set EndTime = @Endtime1 where (EndTime > @EndTime1 or Endtime is null)
declare @LastEndTime datetime, @NextStartTime datetime, @NextEndTime datetime, @MaxEndTime datetime
select @MaxEndTime = max(Endtime) from #ProductiveTimes
select @LastEndTime = min(EndTime) from #ProductiveTimes
select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime
while (@LastEndTime < @MaxEndTime)
begin
 	 while @LastEndTime = @NextStartTime
 	 begin
 	  	 update #ProductiveTimes set EndTime = @NextEndTime where endtime = @LastEndTime
 	   delete from #ProductiveTimes where starttime = @NextStartTime and endtime = @NextEndTime
 	 
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
 	 end
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
end
*/
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR1:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime1, @EndTime1
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR1
 	 End
 	 Close PRODUCTIVETIME_CURSOR
end
else
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR2:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime1, @EndTime1
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR2
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 --Deallocate PRODUCTIVETIME_CURSOR
end
Open TIME_CURSOR  
BEGIN_TIME_CURSOR1:
Fetch Next From TIME_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
insert into #AlarmCount 
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = a.start_time
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time Between @curStartTime and @curEndTime and v.PU_Id = @curPU_Id  and (not a.alarm_id in (select alarmid from #AlarmCount))
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
Union
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = (select min(timestamp) from events where timestamp > a.start_time and timestamp < a.end_time)
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time < @curStartTime and (a.End_Time > @curStartTime or a.End_Time Is Null)  and v.PU_Id = @curPU_Id and (not a.alarm_id in (select alarmid from #AlarmCount))
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
    GOTO BEGIN_TIME_CURSOR1
End
Close TIME_CURSOR
select @HighCount1 = Count(AlarmType) from #AlarmCount where AlarmType =3
select @MediumCount1 = Count(AlarmType) from #AlarmCount where AlarmType =2
select @LowCount1 = Count(AlarmType) from #AlarmCount where AlarmType =1
delete from #AlarmCount
delete from #ProductiveTimes
--*****************************************************/
--Get Second Time Period Alarms
--*****************************************************/
/*if (@FilterNonProductiveTime = 1)
begin
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time >= @StartTime2 and end_time <= @EndTime2
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time < @StartTime2 and End_Time between @StartTime2 and @Endtime2
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime2 or End_Time is null) and Start_Time between @StartTime2 and @EndTime2
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime2 or End_Time is null) and @StartTime2 > Start_Time
end
else
begin
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select PU_ID, @StartTime2, @EndTime2 from #units
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
update #ProductiveTimes set StartTime = @StartTime2 where StartTime < @StartTime2
update #ProductiveTimes set EndTime = @Endtime2 where (EndTime > @EndTime2 or Endtime is null)
select @MaxEndTime = max(Endtime) from #ProductiveTimes
select @LastEndTime = min(EndTime) from #ProductiveTimes
select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime
while (@LastEndTime < @MaxEndTime)
begin
 	 while @LastEndTime = @NextStartTime
 	 begin
 	  	 update #ProductiveTimes set EndTime = @NextEndTime where endtime = @LastEndTime
 	   delete from #ProductiveTimes where starttime = @NextStartTime and endtime = @NextEndTime
 	 
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
 	 end
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
end
*/
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR3:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime2, @EndTime2
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR3
 	 End
 	 Close PRODUCTIVETIME_CURSOR
end
else
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR4:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime2, @EndTime2
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR4
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 --Deallocate PRODUCTIVETIME_CURSOR
end
Open TIME_CURSOR  
BEGIN_TIME_CURSOR2:
Fetch Next From TIME_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
insert into #AlarmCount 
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = a.start_time
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time Between @curStartTime and @curEndTime and v.PU_Id = @curPU_Id and (not a.alarm_id in (select alarmid from #AlarmCount)) 
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
Union
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = (select min(timestamp) from events where timestamp > a.start_time and timestamp < a.end_time)
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time < @curStartTime and (a.End_Time > @curStartTime or a.End_Time Is Null) and v.PU_Id = @curPU_Id and (not a.alarm_id in (select alarmid from #AlarmCount)) 
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
    GOTO BEGIN_TIME_CURSOR2
End
Close TIME_CURSOR
select @HighCount2 = Count(AlarmType) from #AlarmCount where AlarmType =3
select @MediumCount2 = Count(AlarmType) from #AlarmCount where AlarmType =2
select @LowCount2 = Count(AlarmType) from #AlarmCount where AlarmType =1
delete from #AlarmCount
delete from #ProductiveTimes
--*****************************************************/
--Get Third Time Period Alarms
--*****************************************************/
/*if (@FilterNonProductiveTime = 1)
begin
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time >= @StartTime3 and end_time <= @EndTime3
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and Start_Time < @StartTime3 and End_Time between @StartTime3 and @Endtime3
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime3 or End_Time is null) and Start_Time between @StartTime3 and @EndTime3
insert into #ProductiveTimes (StartTime, EndTime, PU_Id) select Productive_Start_Time, Productive_End_Time, Source_PU_Id from alarms_npt where Source_PU_Id in (select pu_id from #units) 
and (End_Time > @EndTime3 or End_Time is null) and @StartTime3 > Start_Time
end
else
begin
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select PU_ID, @StartTime3, @EndTime3 from #units
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
update #ProductiveTimes set StartTime = @StartTime3 where StartTime < @StartTime3
update #ProductiveTimes set EndTime = @Endtime3 where (EndTime > @EndTime3 or Endtime is null)
select @MaxEndTime = max(Endtime) from #ProductiveTimes
select @LastEndTime = min(EndTime) from #ProductiveTimes
select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime
while (@LastEndTime < @MaxEndTime)
begin
 	 while @LastEndTime = @NextStartTime
 	 begin
 	  	 update #ProductiveTimes set EndTime = @NextEndTime where endtime = @LastEndTime
 	   delete from #ProductiveTimes where starttime = @NextStartTime and endtime = @NextEndTime
 	 
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
 	 end
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
end
*/
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR5:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime3, @EndTime3
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR5
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
else
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR6:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime3, @EndTime3
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR6
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
Open TIME_CURSOR  
BEGIN_TIME_CURSOR3:
Fetch Next From TIME_CURSOR Into @curPU_Id, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
insert into #AlarmCount 
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = a.start_time
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time Between @curStartTime and @curEndTime and v.PU_Id = @curPU_Id and (not a.alarm_id in (select alarmid from #AlarmCount)) 
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
Union
  select AlarmType =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
  	 StartTime = a.start_time,
 	 EndTime = a.end_time,
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2)
  Join Prod_Units u on u.pu_id = a.source_pu_id
  join production_starts ps on ps.pu_id = a.source_pu_id and ps.start_time <= a.start_time and ((ps.end_time > a.start_time) or (ps.end_time is null))
  join products p1 on p1.prod_id = ps.prod_id
  left outer Join Events e on e.pu_id = a.source_pu_id and e.timestamp = (select min(timestamp) from events where timestamp > a.start_time and timestamp < a.end_time)
  Left Outer Join Event_Reasons r1 on r1.event_reason_id = a.cause1
  Left Outer Join Event_Reasons r2 on r2.event_reason_id = a.cause2
  Left Outer Join Event_Reasons r3 on r3.event_reason_id = a.cause3
  Left Outer Join Event_Reasons r4 on r4.event_reason_id = a.cause4
  Left Outer Join Event_Reasons a1 on a1.event_reason_id = a.action1
  Left Outer Join Event_Reasons a2 on a2.event_reason_id = a.action2
  Left Outer Join Event_Reasons a3 on a3.event_reason_id = a.action3
  Left Outer Join Event_Reasons a4 on a4.event_reason_id = a.action4
  left outer join products p2 on p2.prod_id = e.applied_product 
  left outer Join Alarm_Template_Var_Data vd on vd.atd_id = a.atd_id
  left outer Join Alarm_Templates t on t.at_id = vd.at_id
  Left Outer Join Alarm_Template_SPC_Rule_Data r on r.atsrd_id = a.atsrd_id  
  Left Outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.atvrd_id = a.atvrd_id  
  Left outer join comments c1 on c1.comment_id = a.cause_comment_id
  left outer join users p on p.user_id = a.ack_by
  Where a.Start_Time < @curStartTime and (a.End_Time > @curStartTime or a.End_Time Is Null) and v.PU_Id = @curPU_Id and (not a.alarm_id in (select alarmid from #AlarmCount)) 
       and Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (1,2,3)
    GOTO BEGIN_TIME_CURSOR3
End
Close TIME_CURSOR
Deallocate TIME_CURSOR
select @HighCount3 = Count(AlarmType) from #AlarmCount where AlarmType =3
select @MediumCount3 = Count(AlarmType) from #AlarmCount where AlarmType =2
select @LowCount3 = Count(AlarmType) from #AlarmCount where AlarmType =1
delete from #AlarmCount
--*****************************************************/
--Determine Trends And Associated Icons
--*****************************************************/
-- 1 = Bad
-- 2 = Good
-- 3 = Nuetral
If @HighCount1 > @HighCount2 
  Select @HighCountIcon = 1
Else If @HighCount1 < @HighCount2 
  Select @HighCountIcon = 2
Else
  Select @HighCountIcon = 3
If @MediumCount1 > @MediumCount2 
  Select @MediumCountIcon = 1
Else If @MediumCount1 < @MediumCount2 
  Select @MediumCountIcon = 2
Else
  Select @MediumCountIcon = 3
If @LowCount1 > @LowCount2 
  Select @LowCountIcon = 1
Else If @LowCount1 < @LowCount2 
  Select @LowCountIcon = 2
Else
  Select @LowCountIcon = 3
--*****************************************************/
--Return Resultset With Data
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 ColumnValue varchar(50)
)
insert into #Columns (ColumnName, ColumnValue) values('HighCountIcon',@HighCountIcon)
insert into #Columns (ColumnName, ColumnValue) values('HighCount1',@HighCount1)
insert into #Columns (ColumnName, ColumnValue) values('HighCount2',@HighCount2)
insert into #Columns (ColumnName, ColumnValue) values('HighCount3',@HighCount3)
insert into #Columns (ColumnName, ColumnValue) values('MediumCountIcon',@MediumCountIcon)
insert into #Columns (ColumnName, ColumnValue) values('MediumCount1',@MediumCount1)
insert into #Columns (ColumnName, ColumnValue) values('MediumCount2',@MediumCount2)
insert into #Columns (ColumnName, ColumnValue) values('MediumCount3',@MediumCount3)
insert into #Columns (ColumnName, ColumnValue) values('LowCountIcon',@LowCountIcon)
insert into #Columns (ColumnName, ColumnValue) values('LowCount1',@LowCount1)
insert into #Columns (ColumnName, ColumnValue) values('LowCount2',@LowCount2)
insert into #Columns (ColumnName, ColumnValue) values('LowCount3',@LowCount3)
select * from #Columns
drop table #Columns
Drop Table #Variables
