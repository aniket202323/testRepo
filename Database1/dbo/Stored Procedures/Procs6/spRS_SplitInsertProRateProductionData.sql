CREATE procedure [dbo].[spRS_SplitInsertProRateProductionData]
AS
Create Table #LocalReport (
  Row_Id int NOT NULL IDENTITY (1, 1),
  Event_Id int,
  Event_Number varchar(25),
  Event_Status varchar(25) NULL,
  Prod_Id int NULL,
  Start_Time datetime NULL,
  End_Time datetime,
  Process_Order_Id int NULL,
  Production_Day datetime,
  Shift_Name varchar(10) NULL, 
  Crew_Name varchar(10) NULL, 
  Waste_Amount real NULL,
  Initial_Dimension_X real NULL,
  Final_Dimension_X real NULL,
  Color int NULL,
  Event_Downtime_Minutes real NULL,
  Event_Downtime_Count int NULL,
  Event_Duration int,
  Productive_Start_Time datetime,
  Productive_End_Time datetime,
  Non_Productive_Seconds int
)
Declare  @Row_Id int,
  @Event_Id int,
  @Event_Number varchar(25),
  @Event_Status varchar(25),
  @Prod_Id int,
  @Start_Time datetime,
  @End_Time datetime,
  @Process_Order_Id int,
  @Production_Day datetime,
  @Shift_Name varchar(10), 
  @Crew_Name varchar(10), 
  @Waste_Amount real,
  @Initial_Dimension_X real,
  @Final_Dimension_X real,
  @Color int,
  @Event_Downtime_Minutes real,
  @Event_Downtime_Count int,
  @Event_Duration int,
  @Productive_Start_Time datetime,
  @Productive_End_Time datetime,
  @Non_Productive_Seconds int
/*
was a production day split?
was a shift split?
was a crew split?
Start_Time              End_Time                Shift_Desc Crew_Desc  Shift_Duration
----------------------- ----------------------- ---------- ---------- --------------
2006-01-24 07:00:00.000 2006-01-24 15:00:00.000 Day        D          480
2006-01-24 15:00:00.000 2006-01-24 23:00:00.000 Evening    A          480
2006-01-24 23:00:00.000 2006-01-25 07:00:00.000 Night      B          480
*/
--  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
/*
Print '=== #Report BEFORE  ==='
Select 
Sum(Waste_Amount)[Waste_Amount],  Sum(Initial_Dimension_X)[Initial_Dimension_X],  Sum(Final_Dimension_X)[Final_Dimension_X], Sum(Event_Downtime_Minutes)[Event_Downtime_Minutes],  Sum(Event_Downtime_Count)[Event_Downtime_Count],  Sum(Event_Duration)[Event_Duration]
From #Report
*/
Declare @StartTimeProductionDay datetime, @EndTimeProductionDay datetime
Declare @FirstShiftName varchar(10), @SecondShiftName varchar(10)
Declare @FirstCrewName varchar(10), @SecondCrewName varchar(10)
Declare @FirstStartTime datetime, @FirstEndTime datetime
Declare @SecondStartTime datetime, @SecondEndTime datetime
Declare LocalProRateCursor INSENSITIVE CURSOR
 	 For ( 
 	 Select Row_Id, Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds 
 	 From #Report 
 	 )
  For Read Only
  Open LocalProRateCursor  
MyLoop1:
 	 Fetch Next From LocalProRateCursor Into @Row_Id, @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 -- Check for Production Day Split
 	  	  	 Select @StartTimeProductionDay = dbo.fnCMN_GetProductionDayByTimeStamp(@Start_Time), 
 	  	  	  	 @EndTimeProductionDay = dbo.fnCMN_GetProductionDayByTimeStamp(@End_Time)
 	  	  	 If @StartTimeProductionDay <> @EndTimeProductionDay 
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @EndTimeProductionDay,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @EndTimeProductionDay, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @EndTimeProductionDay, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @EndTimeProductionDay, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @EndTimeProductionDay, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @EndTimeProductionDay, @Event_Downtime_Count), 0),
 	  	  	  	  	  	  	 DateDiff(mi, @Start_Time, @EndTimeProductionDay),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @EndTimeProductionDay,  @End_Time,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @EndTimeProductionDay, @End_Time, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @EndTimeProductionDay, @End_Time, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @EndTimeProductionDay, @End_Time, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @EndTimeProductionDay, @End_Time, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @EndTimeProductionDay, @End_Time, @Event_Downtime_Count), 0),
 	  	  	  	  	  	  	 DateDiff(mi, @EndTimeProductionDay, @End_Time),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	   Goto MyLoop1
 	  	 End -- End Loop Here
Close LocalProRateCursor
Deallocate LocalProRateCursor
Truncate Table #report
insert Into #Report
Select Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds
from #LocalReport
Truncate Table #LocalReport
Declare LocalProRateShiftCursor INSENSITIVE CURSOR
 	 For ( 
 	 Select Row_Id, Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds 
 	 From #Report 
 	 )
  For Read Only
  Open LocalProRateShiftCursor  
MyLoop2:
 	 Fetch Next From LocalProRateShiftCursor Into @Row_Id, @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 -- Check for Shift Split
 	  	  	 -- Check for Shift and Crew split
 	  	  	 Select 
 	  	  	  	 @FirstShiftName=Shift_Desc, 
 	  	  	  	 @FirstCrewName=Crew_Desc, 
 	  	  	  	 @FirstStartTime=Start_Time,
 	  	  	  	 @FirstEndTime=End_Time
 	  	  	 From #CrewSchedule Where @Start_Time > Start_Time and @Start_Time <= End_Time
 	  	  	 Select 
 	  	  	  	 @SecondShiftName=Shift_Desc, 
 	  	  	  	 @SecondCrewName=Crew_Desc, 
 	  	  	  	 @SecondStartTime=Start_Time,
 	  	  	  	 @SecondEndTime=End_Time
 	  	  	 From #CrewSchedule Where @End_Time > Start_Time and @End_Time <= End_Time
 	  	  	 If @FirstShiftName <> @SecondShiftName 
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @FirstEndTime,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Event_Downtime_Count), 0),
 	  	  	  	  	  	  	 DateDiff(mi, @Start_Time, @FirstEndTime),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @FirstEndTime,  @End_Time,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Event_Downtime_Count), 0),
 	  	  	  	  	  	  	 DateDiff(mi, @FirstEndTime, @End_Time),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	   Goto MyLoop2
 	  	 End -- End Loop Here
Close LocalProRateShiftCursor
Deallocate LocalProRateShiftCursor
Truncate Table #report
insert Into #Report
Select Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds
from #LocalReport
Truncate Table #LocalReport
Declare LocalProRateCrewCursor INSENSITIVE CURSOR
 	 For ( 
 	 Select Row_Id, Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds 
 	 From #Report 
 	 )
  For Read Only
  Open LocalProRateCrewCursor  
MyLoop3:
 	 Fetch Next From LocalProRateCrewCursor Into @Row_Id, @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 -- Check for Shift Split
 	  	  	 -- Check for Shift and Crew split
 	  	  	 Select 
 	  	  	  	 @FirstShiftName=Shift_Desc, 
 	  	  	  	 @FirstCrewName=Crew_Desc, 
 	  	  	  	 @FirstStartTime=Start_Time,
 	  	  	  	 @FirstEndTime=End_Time
 	  	  	 From #CrewSchedule Where @Start_Time > Start_Time and @Start_Time <= End_Time
 	  	  	 Select 
 	  	  	  	 @SecondShiftName=Shift_Desc, 
 	  	  	  	 @SecondCrewName=Crew_Desc, 
 	  	  	  	 @SecondStartTime=Start_Time,
 	  	  	  	 @SecondEndTime=End_Time
 	  	  	 From #CrewSchedule Where @End_Time > Start_Time and @End_Time <= End_Time
 	  	  	 If @FirstCrewName <> @SecondCrewName 
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @FirstEndTime,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @Start_Time, @FirstEndTime, @Event_Downtime_Count),0),
 	  	  	  	  	  	  	 DateDiff(mi, @Start_Time, @FirstEndTime),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @FirstEndTime,  @End_Time,  @Process_Order_Id,  @StartTimeProductionDay,  @Shift_Name,  @Crew_Name,   
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Waste_Amount),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Initial_Dimension_X),
 	  	  	  	  	  	  	 dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Final_Dimension_X),
 	  	  	  	  	  	  	 @Color,  
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Event_Downtime_Minutes),0),
 	  	  	  	  	  	  	 Round(dbo.fnCMN_GetProRatedProduction(@Start_Time, @End_Time, @FirstEndTime, @End_Time, @Event_Downtime_Count),0),
 	  	  	  	  	  	  	 DateDiff(mi, @FirstEndTime, @End_Time),
 	  	  	  	  	  	  	 @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #LocalReport
 	  	  	  	  	  	 Select  @Event_Id,  @Event_Number,  @Event_Status,  @Prod_Id,  @Start_Time,  @End_Time,  @Process_Order_Id,  @Production_Day,  @Shift_Name,  @Crew_Name,   @Waste_Amount,  @Initial_Dimension_X,  @Final_Dimension_X,  @Color,  @Event_Downtime_Minutes,  @Event_Downtime_Count,  @Event_Duration,  @Productive_Start_Time,  @Productive_End_Time,  @Non_Productive_Seconds
 	  	  	  	 End
 	  	   Goto MyLoop3
 	  	 End -- End Loop Here
Close LocalProRateCrewCursor
Deallocate LocalProRateCrewCursor
Truncate Table #report
insert Into #Report
Select Event_Id, Event_Number, Event_Status, Prod_Id, Start_Time, End_Time, Process_Order_Id, Production_Day, Shift_Name, Crew_Name, Waste_Amount, Initial_Dimension_X, Final_Dimension_X, Color, Event_Downtime_Minutes, Event_Downtime_Count, Event_Duration, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds
from #LocalReport
Truncate Table #LocalReport
/*
Print '=== #Report AFTER ==='
Select 
Sum(Waste_Amount)[Waste_Amount],  Sum(Initial_Dimension_X)[Initial_Dimension_X],  Sum(Final_Dimension_X)[Final_Dimension_X], Sum(Event_Downtime_Minutes)[Event_Downtime_Minutes],  Sum(Event_Downtime_Count)[Event_Downtime_Count],  Sum(Event_Duration)[Event_Duration]
From #Report
*/
Drop Table #LocalReport
