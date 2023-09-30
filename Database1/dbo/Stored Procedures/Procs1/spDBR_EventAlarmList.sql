CREATE Procedure dbo.spDBR_EventAlarmList
@Unit 	  	  	  	  	  	 int = 0,
@StartTime 	  	  	  	  	 datetime = null,
@EndTime 	  	  	  	  	 datetime = null,
@FilterNonProductiveTime 	 int = 0,
@InTimeZone 	  	  	  	  	 varchar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
@Products 	  	  	  	  	 varchar(1000) = NULL
AS
--********************************************************/
SET ANSI_WARNINGS off
Declare @ProdCount int
select @Products = REPLACE(@Products, ',0', '')
select @Products = REPLACE(@Products, ';', ',')
Declare @ProdTable TABLE(Id_Order int, Prod_Id int)
insert into @ProdTable
 	 select * from dbo.fnRS_MakeOrderedResultSet(@Products)
-- -1 means Any Product
delete from @ProdTable where Prod_Id = -1
select @ProdCount = count(*) from @ProdTable
-- Event Status List By Units  Alarms High AlarmCount will link to this report
Declare @EventName varchar(50)
Declare @BadCount int
Declare @BadProduction real
DEclare @TotalProduction real
select @EventName = s.event_subtype_desc
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
--*********************************************************************************
-- Build List Of Events
--*********************************************************************************
Create Table #EventList (
  EventId int,
  EventNum varchar(50),
  StartTime datetime NULL,
  EndTime datetime,
  EventStatus varchar(50),
  EventStatusID int NULL,
  BadFlag int default(0),
  Amount real NULL,
  HighCount int NULL,
  MediumCount int NULL,
  LowCount int NULL,
  EventAppliedProduct int NULL
)
create table #ProductiveTimes
(
  StartTime datetime,
  EndTime   datetime
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
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
Insert Into #EventList (EventId,EventNum,StartTime,EndTime,EventStatus,EventStatusID,BadFlag,Amount,EventAppliedProduct)
  Select EventId = e.Event_Id,
         EventNum = e.Event_Num,
         StartTime = e.Start_Time,
         EndTime = e.Timestamp,
         EventStatus = s.ProdStatus_Desc,
 	  	  EventStatusID = s.ProdStatus_ID,
         BadFlag = Case When s.status_valid_for_input > 0 then 0 else 1 End,
         Amount = d.initial_dimension_x,
 	  	  EventAppliedProduct = IsNull(e.Applied_Product, ps.Prod_Id)
    From events e
    left outer Join event_details d on d.event_id = e.event_id
    Join production_status s on s.prodstatus_id = e.event_status 
    Join Production_Starts ps on e.PU_Id = ps.PU_Id
 	  	 AND 	 ps.Start_Time <= e.Timestamp
 	  	 AND 	 (ps.End_Time > e.Timestamp OR ps.End_Time IS NULL)
    Where e.PU_Id = @Unit  
          AND e.Timestamp  > @curStartTime
 	  	   AND e.Timestamp <= @curEndTime 
 	 update #EventList set StartTime = @curStartTime where EndTime = (select min(EndTime) from #EventList where EndTime > @curStartTime)
    GOTO BEGIN_TIME_CURSOR
End
Close TIME_CURSOR
Deallocate TIME_CURSOR
-- Remove any products not in the Filter List
if @ProdCount > 0 
 	 delete from #EventList where EventAppliedProduct not in (select Prod_Id from @ProdTable)
--*********************************************************************************
-- Calculate Header Information
--*********************************************************************************
Select @BadCount = sum(BadFlag), 
       @BadProduction = sum(Case When BadFlag = 1 Then coalesce(Amount,0.0) Else 0.0 End), 
       @TotalProduction = sum(coalesce(Amount,0.0))
    From #EventList
--*********************************************************************************
-- Cursor Through Events 
--*********************************************************************************
Declare @@EventId int
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @LastEnd datetime
Declare @HighCount int
Declare @MediumCount int
Declare @LowCount int
Select @LastEnd = NULL
Declare Event_Cursor Insensitive Cursor 
  For Select EventId, StartTime, EndTime From #EventList Order By EndTime 
  For Read Only
Open Event_Cursor
Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime
While @@Fetch_Status = 0
  Begin
    Select @@StartTime = coalesce(@@StartTime, @LastEnd) 
    If @@StartTime Is Null
      Select @@StartTime = max(Timestamp)
        From Events
        Where PU_Id = @Unit and
              Timestamp < @StartTime
    Select @HighCount = 0
    Select @MediumCount = 0
    Select @LowCount = 0
 	  	 execute spCMN_GetUnitAlarmCounts
 	  	  	 @Unit,
 	  	  	 --@@StartTime, 
 	  	  	 @@EndTime,
 	  	  	 @@EndTime,
 	  	  	 @HighCount OUTPUT,
 	  	  	 @MediumCount OUTPUT,
 	  	  	 @LowCount OUTPUT
    Update #EventList
      Set HighCount = @HighCount,
          MediumCount = @MediumCount,
          LowCount = @LowCount
      Where EventId = @@EventId  
    Select @LastEnd = @@EndTime
 	  	 Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime
  End
Close Event_Cursor
Deallocate Event_Cursor  
--*********************************************************************************
-- Return Resultset #1 - Title Information
--*********************************************************************************
create table #UserColumns
(
 	 Prompt varchar(50),
 	 ColumnName varchar(50)
)
insert into #UserColumns values ('0', '0')
insert into #UserColumns values (@EventName, 'Event_Num')
insert into #UserColumns values (dbo.fnDBTranslate(N'0', 38405, '#High'), 'CountHigh')
insert into #UserColumns values (dbo.fnDBTranslate(N'0', 38406, '#Med'), 'CountMedium')
insert into #UserColumns values (dbo.fnDBTranslate(N'0', 38407, '#Low'), 'CountLow')
select * from #UserColumns
drop table #UserColumns
--*********************************************************************************
-- Return Resultset #2 - More Title Information
--*********************************************************************************
Select EventName = @EventName, 
       TotalProduction = @TotalProduction, 
       NumberRejected = @BadCount, PercentRejected = convert(decimal(10,2), Case When @TotalProduction > 0 Then @BadProduction / @TotalProduction * 100.0 Else 0.0 End)
--*********************************************************************************
-- Return Resultset #3 - Data
--*********************************************************************************
Select Event_Num = EventNum, 
       Event_Status = EventStatus,
       Event_Status_ID = EventStatusID,
       CountHigh = HighCount, 
       CountMedium = MediumCount, 
       CountLow = LowCount
  From #EventList
  Order By EventNum ASC
Drop Table #EventList
Drop Table #ProductiveTimes
