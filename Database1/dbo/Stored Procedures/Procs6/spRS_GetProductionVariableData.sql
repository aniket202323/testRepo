CREATE procedure [dbo].[spRS_GetProductionVariableData]
     @StartTime DateTime,
     @EndTime DateTime,
     @Unit Int,
     @InputVariableIds VarChar(1000)
AS
--*/
----------------------------------------------------------
-- Procedure Body
----------------------------------------------------------
-- Local Declarations
Declare @MillStartTime varchar(8)
Create Table #InputVariableIds(Id_Order int, Var_Id int)
-- Raw Variable Data
Create Table #RawVariableData(
     Result_On datetime,
     Event_Id int,
     Var_id int,
     Result Varchar(25),
     Var_Desc Varchar(50),
     Production_Day datetime,
     Shift varchar(10),
     Crew varchar(10),
     Process_Order int,
     Prod_Id int,
     Event_Status varchar(25)
)
Create Table #ProcessOrderTimes(
     Process_Order_Id int,
     Order_Start_Time datetime,
     Order_End_Time datetime,
     Event_Status varchar(25)
)
Create Table #ProductRunTimes(
     prod_id int,
     Prod_Start_Time datetime,
     Prod_End_Time datetime
)
/*
-- Crew Schedule Table should already be created
Create Table #CrewSchedule(
     Start_Time datetime,
     End_Time datetime,
     Shift_Desc varchar(10),
     Crew_Desc varchar(10)
)
*/
----------------------------------------------------------
-- Get the mill start time 7:00:00
----------------------------------------------------------
Select @MillStartTime = dbo.fnRS_GetMillStartTime()
----------------------------------------------------------
-- Put the variables into a result set to be joined against
----------------------------------------------------------
Insert Into #InputVariableIds select * from dbo.fnRS_MakeOrderedResultSet(@InputVariableIds)
----------------------------------------------------------
-- Get Crew Schedule
----------------------------------------------------------
--insert into #CrewSchedule select * from dbo.fnRS_wrGetCrewSchedule(@StartTime, @EndTime, @Unit)
------------------------------------------------------------
-- Populate Product Run Times
------------------------------------------------------------
DECLARE @Production_Starts TABLE (id int identity, Start_Time datetime, End_Time datetime, PU_ID int, Prod_Id int)
DECLARE @Production_Starts_Temp TABLE (id int identity, Start_Time datetime, End_Time datetime, PU_ID int, Prod_Id int)
DECLARE @Flag int
-----------------------------------------------
-- Get Data From Production Starts
-----------------------------------------------
insert into @Production_Starts_Temp(Start_Time, End_Time, PU_ID, Prod_Id)
 	 select Start_time, End_Time, PU_ID, Prod_Id 
 	 from Production_starts 
 	 where pu_id = @unit
 	 and start_time < @EndTime and End_Time >= @StartTime
 	 order by start_time
-----------------------------------------------
-- Get Applied Products From Events
-----------------------------------------------
Insert Into @Production_Starts_Temp(End_Time, PU_Id, Prod_Id)
 	 select timestamp, pu_id, Applied_Product 
 	 from events where pu_id = @unit
 	 and timestamp < @EndTime and timestamp >= @StartTime
 	 and Applied_Product Is Not Null
Select @Flag = @@RowCount 
-----------------------------------------------
-- Insert and Order Production Start Times
-----------------------------------------------
Insert Into @Production_Starts(Start_Time, End_Time, PU_Id, Prod_Id)
 	 Select Start_Time, End_Time, PU_ID, Prod_Id
 	 From @Production_Starts_Temp
 	 Order By End_Time
-----------------------------------------------
-- Reconcile Start_Times
-----------------------------------------------
if @Flag > 0 
 	 Begin
 	  	 Update  d1
 	  	  	 Set d1.Start_Time = d2.End_Time
 	  	  	 From @Production_Starts d2
 	  	  	 Join @Production_Starts d1 on d1.id = (d2.id + 1)
 	  	 
 	  	 Update @Production_Starts Set
 	  	  	 Start_Time = @StartTime
 	  	  	 Where Start_Time Is Null
 	 End
-----
--/*
Insert Into #ProductRunTimes(Prod_Id, Prod_Start_Time, Prod_End_Time)
Select Prod_Id, Start_Time, End_Time from @Production_Starts order by start_time
--*/
/*
Insert Into #ProductRunTimes(Prod_Id, Prod_Start_Time, Prod_End_Time)
select ps.Prod_Id, ps.Start_Time, IsNull(ps.End_Time, @EndTime)
     from Production_Starts ps 
     Join Products p on p.Prod_Id = ps.Prod_Id
     where ps.PU_id = @Unit 
          and ps.Start_Time <= @EndTime
          and ((ps.End_Time > @StartTime) or (ps.End_Time Is Null))
     order by ps.Start_Time
--*/
------------------------------------------------------------
-- Populate Process Order Table
------------------------------------------------------------
Create Table #RawEventProduction(
     Event_id int,
     Timestamp datetime,
     Event_Status varchar(25),
     Process_Order_Id int,
     ProcessOrderStartTime datetime,
     ProcessOrderEndTime datetime
)
insert into #RawEventProduction(Event_Id, Timestamp, Event_Status, Process_Order_Id)
  Select e.event_id, e.Timestamp, s.ProdStatus_Desc, d.pp_id
    From Events e
    Join Production_Starts ps on ps.PU_id = @Unit 
         and ps.Start_Time <= e.Timestamp
         and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
    Join Production_Status s on s.ProdStatus_id = e.Event_Status 
         and s.count_for_production = 1
    Left Outer Join Event_Details d on d.event_id = e.event_id
    Where e.PU_id = @Unit and
          e.Timestamp > @StartTime and 
          e.Timestamp <= @EndTime 
------------------------------------------------------------------------     
Update #RawEventProduction 
  Set Process_Order_Id = (Select min(ps.pp_id) 
                         From production_plan_starts ps 
                         where ps.pu_id = @Unit 
                         and ps.Start_Time <= #RawEventProduction.Timestamp 
                         and ((ps.End_Time > #RawEventProduction.Timestamp) or (ps.End_Time is Null)))
  Where Process_Order_Id Is Null          
------------------------------------------------------------------------
update #RawEventProduction Set
     ProcessOrderStartTime = Actual_Start_Time,
     ProcessOrderEndTime = Actual_End_Time
     From Production_Plan pp
     where pp.pp_Id = #RawEventProduction.Process_Order_Id
------------------------------------------------------------------------     
insert Into #ProcessOrderTimes(Process_Order_Id, Order_Start_Time, Order_End_Time, Event_Status)
     select Process_Order_Id, ProcessOrderStartTime, ProcessOrderEndTime, Event_Status from #RawEventProduction where Process_Order_Id is not null order by ProcessOrderStartTime
--     select distinct ProcessOrderId, ProcessOrderStartTime, ProcessOrderEndTime from #ProcessOrder where Processorderid is not null order by ProcessOrderStartTime
----------------------------------------------------------
-- Get Raw Variable Data
----------------------------------------------------------
Insert Into #RawVariableData(Result_On, Event_Id, Var_Id, Result, Var_Desc)
Select t.Result_On, t.Event_Id, t.Var_Id, t.Result, v.var_desc
From Tests t
Join #InputVariableIds i on i.var_id = t.var_id
Join Variables v on t.var_Id = v.var_Id 
Join Events e on e.Timestamp = t.Result_On and e.Timestamp > @StartTime and e.TimeStamp <= @EndTime and e.pu_id = @Unit
Where IsNumeric(t.Result) = 1
and t.Event_Id Is Not Null
-- Update RAW Variable Data Crew Shift Production Day
Update #RawVariableData SET
     #RawVariableData.Shift = CS.Shift_Desc,
     #RawVariableData.Crew = CS.Crew_Desc
From #RawVariableData
     Join #CrewSchedule CS on #RawVariableData.Result_On Between CS.Start_Time and CS.End_Time
-- Update RAW Variable Data Production Day
Update #RawVariableData Set Production_Day = 
Case 
     When Result_On >= Convert(datetime, Convert(varchar(4),DatePart(yyyy, Result_On)) + '-' + Convert(varchar(2), DatePart(mm, Result_On)) + '-' + Convert(varchar(2), DatePart(dd, Result_On)) + ' ' + @MillStartTime) 
     then Convert(datetime, Convert(varchar(4),DatePart(yyyy, Result_On)) + '-' + Convert(varchar(2), DatePart(mm, Result_On)) + '-' + Convert(varchar(2), DatePart(dd, Result_On)) + ' ' + @MillStartTime) 
     Else Convert(datetime, Convert(varchar(4),DatePart(yyyy, dateadd(d, -1, Result_On))) + '-' + Convert(varchar(2), DatePart(mm, dateadd(d, -1, Result_On))) + '-' + Convert(varchar(2), DatePart(dd, dateadd(d, -1, Result_On))) + ' ' + @MillStartTime) 
End
-- Update Product Id
Update #RawVariableData 
     Set Prod_Id = (Select PRT.Prod_Id
          From #ProductRunTimes PRT
          Where PRT.Prod_Start_Time <= #RawVariableData.Result_On 
          and PRT.Prod_End_Time > #RawVariableData.Result_On)
Update #RawVariableData 
     Set Process_Order = (Select REP.Process_Order_Id
          From #RawEventProduction REP
          Where REP.Timestamp = #RawVariableData.Result_On)
Update #RawVariableData 
     Set Event_Status = (Select REP.Event_Status
          From #RawEventProduction REP
          Where REP.Timestamp = #RawVariableData.Result_On)
Select Result_On, Event_Id, Var_id, Result, Var_Desc, Production_Day, Shift, Crew, Process_Order, Prod_Id, Event_Status From #RawVariableData
-- This is what should be done with the data afterward
/*
-- By Production Day
exec spLocal_CrossTab 
     'Select Production_Day From #RawVariableData Group By Production_Day', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
-- By Shift
exec spLocal_CrossTab 
     'Select Shift From #RawVariableData Group By Shift', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
--By Crew
exec spLocal_CrossTab 
     'Select Crew From #RawVariableData Group By Crew', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
-- By Process Order
exec spLocal_CrossTab 
     'Select Process_Order From #RawVariableData where Process_Order Is Not Null Group By Process_Order', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
-- By Product
exec spLocal_CrossTab 
     'Select Prod_Id From #RawVariableData Group By Prod_Id', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
-- By Status
exec spLocal_CrossTab 
     'Select Event_Status From #RawVariableData Group By Event_Status', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
-- By Event Timestamp
exec spLocal_CrossTab 
     'Select Result_On From #RawVariableData Group By Result_On', 
     'sum(convert(decimal(10,2), Result))', 
     'var_desc', 
     '#RawVariableData'
--*/
drop table #RawVariableData
drop table #InputVariableIds
--drop table #CrewSchedule
Drop Table #ProcessOrderTimes
Drop Table #ProductRunTimes
Drop Table #RawEventProduction
--/*
