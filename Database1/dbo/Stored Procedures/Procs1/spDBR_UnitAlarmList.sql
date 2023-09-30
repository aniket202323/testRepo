CREATE Procedure dbo.spDBR_UnitAlarmList
@Unit int,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@PriorityFilter text = NULL,
@OpenFilter int = 0,
@FilterNonProductiveTime int = 0,
@ColumnVisibility text = NULL,
@InTimeZone 	  	 varchar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
@TimeOption 	  	 int = NULL
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
declare 
@Unit int,
@StartTime datetime,
@EndTime datetime,
@PriorityFilter int,
@OpenFilter int,
@ColumnVisibility varchar(2000)
Select @Unit = 2
Select @StartTime = '1-jul-2000'
Select @EndTime = '1-1-2004'
Select @PriorityFilter = null
Select @OpenFilter = 0
--*****************************************************/
--*****************************************************/
--Build List Of Variables
--*****************************************************/
Create Table #Variables (
  VariableName varchar(100) NULL,
  Item int
)
create table #Priorities (
  [Priority Description] varchar(100) null,
  [Priority ID] int
)
create table #ProductiveTimes
(
  StartTime datetime,
  EndTime   datetime
)
create table #AlarmData
(
  PriorityIcon int,
  Origin       varchar(50),
  Type         varchar(50),
  Message      varchar(1000),
  Value        varchar(25),
  Event        varchar(25),
  Product      varchar(25),
  StartTime    datetime,
  EndTime      datetime,
  Cause        varchar(1000),
  Action       varchar(1000),
  Comment      varchar(1000),
  AlarmId      int,
  VarId        int,
  EventId      int,
  UnitId       int,
  AlarmStartTime datetime,
  AlarmEndTime   datetime,
  Signoff1 	 varchar(50),
  Signoff2     varchar(50)
)
/*Time Options are also need to consider */
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 --SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 --SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 IF(@StartTime) IS NOT NULL AND (@EndTime) IS NOT NULL
BEGIN
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE IF (@TimeOption) IS NOT NULL
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions @TimeOption,@InTimeZone
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	  	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions 30,@InTimeZone -- Default to Today if no start time and end time is provided
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions 	 
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END 
Insert Into #Variables (Item)
  Select distinct v.var_id
    From variables v 
    join alarm_template_var_data vd on vd.var_id = v.var_id
    where pu_id in (Select pu_id from prod_units where pu_id = @Unit or master_unit = @Unit)
--*****************************************************/
  EXECUTE spDBR_GetColumns @ColumnVisibility
--*****************************************************/
if (not @PriorityFilter like '%<Root></Root>%' and not @PriorityFilter is NULL)
  begin
    if (not @PriorityFilter like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'Priority;' + Convert(nvarchar(4000), @PriorityFilter)
      Insert Into #Priorities ([Priority ID]) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Priorities  Execute spDBR_Prepare_Table @PriorityFilter
    end
  end
else
begin
insert into #Priorities ([Priority ID]) values (1)
insert into #Priorities ([Priority ID]) values (2)
insert into #Priorities ([Priority ID]) values (3)
end
--*****************************************************/
/*
if (@FilterNonProductiveTime = 1)
begin
insert into #ProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from alarms_npt where Source_PU_Id = @Unit 
and Start_Time >= @StartTime and end_time <= @EndTime
insert into #ProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from alarms_npt where Source_PU_Id = @Unit 
and Start_Time < @StartTime and End_Time between @StartTime and @Endtime
insert into #ProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from alarms_npt where Source_PU_Id = @Unit 
and (End_Time > @EndTime or End_Time is null) and Start_Time between @StartTime and @EndTime
insert into #ProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from alarms_npt where Source_PU_Id = @Unit 
and (End_Time > @EndTime or End_Time is null) and @StartTime > Start_Time
end
else
begin
 	  	 insert into #ProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
update #ProductiveTimes set StartTime = @StartTime where StartTime < @StartTime
update #ProductiveTimes set EndTime = @Endtime where (EndTime > @EndTime or Endtime is null)
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
 	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @Unit, @StartTime, @EndTime
end
else
begin
 	 insert into #ProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
declare @curStartTime datetime, @curEndTime datetime
Declare TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select StartTime, EndTime From #ProductiveTimes
      )
  For Read Only
  Open TIME_CURSOR  
BEGIN_TIME_CURSOR:
Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
insert into #AlarmData
Select PriorityIcon =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
       Origin = v.var_desc,
       Type = Case 
                 When a.Alarm_Type_Id = 1 then dbo.fnDBTranslate(N'0', 38327, 'Limit') 
                 When a.Alarm_Type_Id = 2 then dbo.fnDBTranslate(N'0', 38328, 'SPC') 
                 When a.Alarm_Type_Id = 4 then dbo.fnDBTranslate(N'0', 38490, 'SPC Group') 
                 Else dbo.fnDBTranslate(N'0', 38329, 'Other') 
              End,
       Message = a.alarm_desc, 
       --Value = convert(decimal(10,1),a.start_result), Fix for the bug#31512
       Value = a.start_result,
       Event = e.Event_Num,
       Product = Case
                   When e.Applied_Product Is Not Null Then p2.Prod_Code
                   Else p1.Prod_Code
                 End,
 	 StartTime = a.start_time,
 	 EndTime = a.end_time,    
       Cause = coalesce(r1.event_reason_name,'<font color=red>' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '</font>')  + coalesce(', ' + r2.event_reason_name,'') + + coalesce(', ' + r3.event_reason_name,'') + + coalesce(', ' + r4.event_reason_name,''),   
       Action = coalesce(a1.event_reason_name,'<font color=red>' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified')+ '</font>')  + coalesce(', ' + a2.event_reason_name,'') + + coalesce(', ' + a3.event_reason_name,'') + + coalesce(', ' + a4.event_reason_name,''),
       Comment = convert(varchar(1000), c1.Comment_Text),
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End,
       a.Start_Time,
       a.End_Time,
       Signoff1 = user1.username,
       Signoff2 = user2.username
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2,4)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2,4)
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
  left outer join esignature esig on esig.signature_id = a.signature_id
  left outer join users user1 on user1.[user_id] = esig.perform_user_id
  left outer join users user2 on user2.[user_id] = esig.verify_user_id
  Where a.Start_Time Between @curStartTime and @curEndTime and
        (Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in(select [Priority ID] from #Priorities)) and (not a.alarm_id in (select alarmid from #AlarmData)) and
        ((@OpenFilter Is null) or (@OpenFilter = 0) or (@OpenFilter = 1 and a.end_time is null))
Union
Select PriorityIcon =  Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End,
       Origin = v.var_desc,
       Type = Case 
                 When a.Alarm_Type_Id = 1 then dbo.fnDBTranslate(N'0', 38327, 'Limit') 
                 When a.Alarm_Type_Id = 2 then dbo.fnDBTranslate(N'0', 38328, 'SPC') 
                 When a.Alarm_Type_Id = 4 then dbo.fnDBTranslate(N'0', 38490, 'SPC Group') 
                 Else dbo.fnDBTranslate(N'0', 38329, 'Other')
              End,
       Message = a.alarm_desc, 
       --Value = convert(decimal(10,1),a.start_result),Fix for the bug#31512
       Value = a.start_result,
       Event = e.Event_Num,
       Product = Case
                   When e.Applied_Product Is Not Null Then p2.Prod_Code
                   Else p1.Prod_Code
                 End,
 	 StartTime = a.start_time,
 	 EndTime = a.end_time,    
       Cause = coalesce(r1.event_reason_name,'<font color=red>' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '</font>')  + coalesce(', ' + r2.event_reason_name,'') + + coalesce(', ' + r3.event_reason_name,'') + + coalesce(', ' + r4.event_reason_name,''),   
       Action = coalesce(a1.event_reason_name,'<font color=red>' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '</font>')  + coalesce(', ' + a2.event_reason_name,'') + + coalesce(', ' + a3.event_reason_name,'') + + coalesce(', ' + a4.event_reason_name,''),
       Comment = convert(varchar(1000), c1.Comment_Text),
       AlarmId = a.Alarm_Id,
       VarId = a.Key_Id,
       EventId = e.Event_id,
       UnitId = Case When u.master_unit is null then u.pu_id else u.master_unit End,
       a.Start_Time,
       a.End_Time,
       Signoff1 = user1.username,
       Signoff2 = user2.username
  From Alarms a
  Join #Variables l on l.Item = a.Key_Id and a.Alarm_Type_Id in (1,2,4)
  Join Variables v on v.var_id = a.Key_id and a.Alarm_Type_Id in (1,2,4)
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
  left outer join esignature esig on esig.signature_id = a.signature_id
  left outer join users user1 on user1.[user_id] = esig.perform_user_id
  left outer join users user2 on user2.[user_id] = esig.verify_user_id
  Where a.Start_Time < @curStartTime and (a.End_Time > @curStartTime or a.End_Time Is Null) and
        (Case When r.ap_id is not null then r.ap_id Else vrd.ap_id End in (select [Priority ID] from #Priorities)) and (not a.alarm_id in (select alarmid from #AlarmData)) and
        ((@OpenFilter Is null) or (@OpenFilter = 0) or (@OpenFilter = 1 and a.end_time is null))
     GOTO BEGIN_TIME_CURSOR
End
Close TIME_CURSOR
Deallocate TIME_CURSOR
---23/08/2010 - Update datetime formate in UTC into #ProcessOrders table
Update #AlarmData Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	  	  	 EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone),
 	  	  	  	  	  	  	 AlarmStartTime = dbo.fnServer_CmnConvertFromDBTime(AlarmStartTime,@InTimeZone),
 	  	  	  	  	  	  	 AlarmEndTime = dbo.fnServer_CmnConvertFromDBTime(AlarmEndTime,@InTimeZone)
 	  	  	  	  	  	  	 
select * from #AlarmData
  order by PriorityIcon DESC, StartTime DESC   
Drop Table #Variables
