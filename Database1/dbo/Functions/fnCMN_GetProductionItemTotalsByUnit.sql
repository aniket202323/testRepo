CREATE FUNCTION dbo.fnCMN_GetProductionItemTotalsByUnit(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @FILTER_NP_TIME INT) 
     RETURNS @ProductionTotals Table (TotalProduction FLOAT, ActualTotalItems INT, ActualGoodItems INT, ActualBadItems INT, ActualConformanceItems INT, EventProduction FLOAT, VariableProduction FLOAT)
AS 
Begin
--*/
--------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------
     Declare @TotalProduction FLOAT
     Declare @ActualTotalItems int
     Declare @ActualGoodItems int
     Declare @ActualBadItems int
     Declare @ActualConformanceItems int
     Declare @ProductionVariable int
     Declare @EventBasedProduction FLOAT
     Declare @VariableBasedProduction FLOAT
 	 Declare @ProductionTable Table (
 	  	 Id int identity(1,1),
 	  	 TotalProduction FLOAT default 0,
 	  	 PR_TotalProduction FLOAT default 0,
 	  	 ActualTotalItems int default 0,
  	    	  PR_ActualTotalItems float default 0,
 	  	 ActualGoodItems int default 0,
  	    	  PR_ActualGoodItems float default 0,
 	  	 ActualBadItems int default 0,
  	    	  PR_ActualBadItems float default 0,
 	  	 ActualConformanceItems int default 0,
  	    	  PR_ActualConformanceItems float default 0,
 	  	 Event_Start_Time DateTime,
 	  	 Event_End_Time DateTime,
 	  	 Report_Start_Time DAteTime,
 	  	 Report_End_Time datetime, 	  	 
 	  	 Productive_Start_Time datetime,
 	  	 Productive_End_Time DateTime,
 	  	 Non_Productive_Seconds int default 0,
 	  	 Event_Gets_Credit int default 0
 	 )
 	 Declare @PrevEventEndTime datetime, @MinEndTime datetime
 	  -- Check for existance of Production Variable
     Select @ProductionVariable = Production_Variable From Prod_Units Where PU_Id = @Unit
 	 declare @NextEventTime datetime
 	  -- Initialize Local Variables
     Select @TotalProduction=0, @ActualTotalItems=0, @ActualGoodItems=0, @ActualBadItems=0, @ActualConformanceItems=0, @EventBasedProduction=0, @VariableBasedProduction=0
 	  -- Initialize NP Filter To False if Null Passed in
 	  If @Filter_NP_Time Is Null 
 	  	 Select @Filter_NP_Time = 0
 	  --------------------------------------------
 	  -- Get Productive Times
 	  --------------------------------------------
 	 Declare @RunTimes TABLE(Id int identity(1,1), Start_Time datetime, End_Time datetime)
 	  If @Filter_NP_TIME <> 0 
 	  	 Begin
 	  	  	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	  	  	 Select * from dbo.fnCMN_GetProductiveTimes(@Unit, @StartTime, @EndTime)
 	  	 End
 	  Else
 	  	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	  	 Values(@StartTime, @EndTime)
 	 -----------------------------------------------------------
 	 -- Event Based Production
 	 -----------------------------------------------------------
     If @ProductionVariable Is Null
          Begin
 	  	  	 Declare @ST datetime, @ET datetime, @Id int
 	  	  	 Declare MyCursor  CURSOR
 	  	  	  	 For ( Select Id, Start_Time, End_Time From @RunTimes )
 	  	  	  	 For Read Only
 	  	  	  	 Open MyCursor  
 	  	  	 Fetch Next From MyCursor Into @Id, @ST, @ET 
 	  	  	 While (@@Fetch_Status = 0)
 	  	  	  	 Begin
 	  	  	  	  	 Select @NextEventTime = min(Timestamp)  
 	  	  	  	  	 From Events 
 	  	  	  	  	 Where Timestamp  >= @ET 
 	  	  	  	  	  	 AND pu_id = @Unit 
 	  	  	  	  	  	 AND (Start_Time < @ET OR Start_Time IS NULL)
 	  	  	  	  	 If @NextEventTime Is Null
 	  	  	  	  	  	 select @NextEventTime = @ET
 	  	  	  	  	 -- Sum By Event Dimensions
 	  	  	  	  	 Insert Into @ProductionTable(TotalProduction, ActualTotalItems, ActualGoodItems, ActualBadItems, ActualConformanceItems, Event_Start_Time, Event_End_Time, Productive_Start_Time, Productive_End_Time, Non_Productive_Seconds, Report_Start_Time, Report_End_Time, Event_Gets_Credit)
 	  	  	  	  	  	 SELECT 
 	  	  	  	  	  	  	 ISNULL(CASE when s.count_for_production = 1 then ed.initial_dimension_x Else 0.0 End,0),
 	  	  	  	  	  	  	 e.Event_Id,
 	  	  	  	  	  	  	 CASE when s.count_for_production = 1 and s.status_valid_for_input = 1 then 1 else 0 end,
 	  	  	  	  	  	  	 CASE when s.count_for_production = 1 and s.status_valid_for_input = 0 then 1 else 0 end,
 	  	  	  	  	  	  	 CASE when e.conformance is null then 1 when e.conformance = 0 then 1 else 0 end,
 	  	  	  	  	  	  	 e.Start_Time, --Actual_Start_Time, 
 	  	  	  	  	  	  	 e.TimeStamp, 
 	  	  	  	  	  	  	 null, null, null,
 	  	  	  	  	  	  	 case when e.Start_Time < @ST then  @ST else e.Start_Time end,
 	  	  	  	  	  	  	 --e.Start_Time, --CASE when Actual_Start_Time < @ST Then @ST Else Actual_Start_Time End,
 	  	  	  	  	  	  	 CASE when e.TimeStamp > @ET then @ET Else e.Timestamp end,
 	  	  	  	  	  	  	 CASE When e.Timestamp > @ST and e.Timestamp <= @ET Then 1 Else 0 End
 	  	  	  	  	  	 From Events e
 	  	  	  	  	  	  	 JOIN event_details ed on ed.event_id = e.event_id
 	  	  	  	  	  	  	 JOIN production_status s on s.prodstatus_id = e.event_status
 	  	  	  	  	  	 WHERE e.pu_id = @Unit 
 	  	  	  	  	  	  	 AND e.Timestamp > @ST 
 	  	  	  	  	  	  	 AND e.Timestamp <= @NextEventTime 
 	  	  	  	  	  	  	 AND ed.initial_dimension_x is not null 
 	  	  	  	  	  	  	 Order By e.Timestamp
 	  	  	  	  	 -- The query above assumes Events.Start_Time has a value
 	  	  	  	  	 -- If not, then it must be calculated
 	  	  	  	  	 If (select Count(*) from @ProductionTable where Event_Start_Time Is Null) > 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- Startime will be the endtime of the previous event
 	  	  	  	  	  	 -- If none of the events have a start time, the query below will grab the end time of the previous event
 	  	  	  	  	  	 -- but leave the 1st row startime empty
 	  	  	  	  	  	 Update P1 SET
 	  	  	  	  	  	  	 P1.Event_Start_Time = P2.Event_End_Time,
 	  	  	  	  	  	  	 P1.Report_Start_Time = P2.Event_End_Time
 	  	  	  	  	  	  	 From @ProductionTable P2
 	  	  	  	  	  	  	 Join @ProductionTable P1 on P1.Id - 1 = P2.Id and p1.Event_Start_Time is null
 	  	  	  	  	  	 -- Find the lowest endtime of the events
 	  	  	  	  	  	 Select @MinEndTime = min(Event_End_Time) from @ProductionTable
 	 
 	  	  	  	  	  	 -- Get the end time of the next most recent event prior to the endtime of the event from the previous query
 	  	  	  	  	  	 select @PrevEventEndTime = max(Timestamp)
 	  	  	  	  	  	 From Events
 	  	  	  	  	  	 Where Timestamp < @MinEndTime
 	  	  	  	  	  	  	 And PU_ID = @Unit
 	  	  	  	  	  	 -- update the Event_Start_Time of the remaining null row
 	  	  	  	  	  	 update @ProductionTable Set Event_Start_Time = @PrevEventEndTime where Event_Start_Time Is Null
 	  	  	  	  	  	 -- truncate any start_times that occur prior to the report range
 	  	  	  	  	  	 update @ProductionTable Set Report_Start_Time = Case when @PrevEventEndTime < @ST Then @ST Else @PrevEventEndTime End Where Report_Start_Time Is Null
 	  	  	  	  	 End
 	  	  	  	  	 Fetch Next From MyCursor Into @Id, @ST, @ET 
 	  	  	  	 End 
 	  	  	 Close MyCursor
 	  	  	 Deallocate MyCursor
 	  	  	  	 
 	  	  	 Update @ProductionTable Set 
  	    	    	    	  PR_TotalProduction = (CAST(TotalProduction AS FLOAT) / CAST(DateDiff(s, Event_Start_Time, Event_End_Time) AS FLOAT)) * CAST(DateDiff(s, Report_Start_Time, Report_End_Time) AS FLOAT),
  	    	    	    	  PR_ActualTotalItems = (CAST(ActualTotalItems AS FLOAT) / CAST(DateDiff(s, Event_Start_Time, Event_End_Time) AS FLOAT)) * CAST(DateDiff(s, Report_Start_Time, Report_End_Time) AS FLOAT),
  	    	    	    	  PR_ActualGoodItems = case when ActualGoodItems=1 and Event_Gets_Credit=1 then 1 else (CAST(ActualGoodItems AS FLOAT) / CAST(DateDiff(s, Event_Start_Time, Event_End_Time) AS FLOAT)) * CAST(DateDiff(s, Report_Start_Time, Report_End_Time) AS FLOAT) end,
  	    	    	    	  PR_ActualBadItems = case when ActualBadItems=1 and Event_Gets_Credit=1 then 1 else (CAST(ActualGoodItems AS FLOAT) / CAST(DateDiff(s, Event_Start_Time, Event_End_Time) AS FLOAT)) * CAST(DateDiff(s, Report_Start_Time, Report_End_Time) AS FLOAT) end,
  	    	    	    	  PR_ActualConformanceItems = case when ActualConformanceItems=1 and Event_Gets_Credit=1 then 1 else (CAST(ActualGoodItems AS FLOAT) / CAST(DateDiff(s, Event_Start_Time, Event_End_Time) AS FLOAT)) * CAST(DateDiff(s, Report_Start_Time, Report_End_Time) AS FLOAT) end
 	  	  	 Where Event_Start_Time <> Event_End_Time
 	  	  	  	 -- Sum Production Values For Output
 	  	  	  	 Select @TotalProduction = Sum(PR_TotalProduction),
 	  	  	  	  	 @EventBasedProduction = Sum(PR_TotalProduction),
 	  	  	  	  	 @ActualTotalItems = Count(PR_ActualTotalItems),
 	  	  	  	  	 @ActualGoodItems = Sum(PR_ActualGoodItems),
 	  	  	  	  	 @ActualBadItems = Sum(PR_ActualBadItems),
 	  	  	  	  	 @ActualConformanceItems = Sum(PR_ActualConformanceItems)
 	  	  	  	 From @ProductionTable
 	  	  	  
 	  	  	  	 Select @ActualTotalItems = Sum(Event_Gets_Credit) From @ProductionTable
          End
 	 -----------------------------------------------------------
 	 -- Variable Based Production
 	 -----------------------------------------------------------
     Else
          Begin
 	  	  	    -- For Time Based Production and Non-Productive Time
 	  	  	    -- A Timestamp can be either IN or OUT.  There is no pro-rating 	  	  	  	 
               SELECT @TotalProduction = coalesce(sum(convert(FLOAT,result)),0)
               FROM Tests_NPT t
               WHERE t.var_id = @ProductionVariable 
 	  	  	  	  	 and t.result_on > @StartTime
 	  	  	  	  	 and t.result_on <= @EndTime 
 	  	  	  	  	 and t.result is not null
 	  	  	  	  	 and (@Filter_NP_Time = 0 or t.Is_Non_Productive = 0)
 	  	  	  	 Select @VariableBasedProduction = @TotalProduction     
          End
 	 -----------------------------------------------------------
 	 -- Return Production Output
 	 -----------------------------------------------------------
     insert Into @ProductionTotals(TotalProduction, ActualTotalItems, ActualGoodItems, ActualBadItems, ActualConformanceItems, EventProduction, VariableProduction)
     Values(Coalesce(@TotalProduction,0), Coalesce(@ActualTotalItems,0), Coalesce(@ActualGoodItems,0), Coalesce(@ActualBadItems,0), Coalesce(@ActualConformanceItems,0), Coalesce(@EventBasedProduction, 0), Coalesce(@VariableBasedProduction, 0))
 	 --select * from @ProductionTotals
--/*******
     RETURN
END
--******/
