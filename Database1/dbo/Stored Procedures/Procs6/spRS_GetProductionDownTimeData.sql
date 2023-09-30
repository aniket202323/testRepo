CREATE procedure [dbo].[spRS_GetProductionDownTimeData]
     @StartTime DateTime,
     @EndTime DateTime,
     @Unit Int
AS
     Declare @ProductionDay datetime
     Declare @MillStartTime varchar(8)         -- SITE PARAMETER
     Declare @ShiftLength int                  -- SITE PARAMETER
     Declare @TodayMillStartTime datetime      -- CURRENT PRODUCTION DAY START TIME
     Declare @NextShiftStartTime datetime      -- CURRENT PRODUCTION DAY START TIME + 1 SHIFT INTERVAL
     Declare @YesterdayMillStartTime datetime  -- YESTERDAY'S PRODUCTION DAY START TIME
     Declare @DayBeforeStartTime datetime      -- PRODUCTION START TIME ON DAY PRIOR TO REPORT PERIOD
     Declare @DayAfterEndTime datetime         -- PRODUCTION START TIME ON DAY AFTER REPORT PERIOD
     -- CURSOR VARIABLES
     Declare @CurStartTime datetime
     Declare @CurEndTime datetime
     Declare @TEDet_Id int
     -- Contains Raw DownTime Info
     Create Table #TempDowntime(
          TEDet_Id int,
          Start_Time datetime,
          End_Time datetime
     )
     Create Table #ProcessOrderTimes(
          Process_Order_Id int,
          Order_Start_Time datetime,
          Order_End_Time datetime
     )
     Create Table #ProductRunTimes(
          prod_id int,
          Prod_Start_Time datetime,
          Prod_End_Time datetime
     )
     Create Table #ProductionDayDowntime(
          TEDet_Id int,
          ProductionDay datetime,
          Start_Time datetime,
          End_Time datetime,
          Duration int
     )
     -- Contains Shift and Crew Downtime Info
     Create Table #ShiftCrewDowntime(
          TEDet_Id int,
          Start_Time datetime,
          End_Time datetime,
          Duration int,
          Shift_Desc varchar(10),
          Crew_Desc varchar(10),
          Shift_Duration int
     )
     Create Table #ProcessOrderDownTime(
          TEDet_Id int,
          Start_Time datetime,
          End_Time datetime,
          Duration int,
          Process_Order_Id int,
          Process_Order_Duration int
     )
     Create Table #ProductDownTime(
          TEDet_Id int,
          Start_Time datetime,
          End_Time datetime,
          Duration int,
          Prod_Id int,
          Prod_Run_Duration int
     )
     --======================================================
     -- These tables should exist in the calling sp
     --======================================================
/*
     -- Crew Schedule Information
     Create Table #CrewSchedule(
          Start_Time datetime,
          End_Time datetime,
          Shift_Desc varchar(10),
          Crew_Desc varchar(10),
          Shift_Duration int
     )
--*/
     ------------------------------------------------------------
     -- GET CURRENT PRODUCTION DAY START TIME
     ------------------------------------------------------------
     Select @MillStartTime = dbo.fnRS_GetMillStartTime()
     Select @ProductionDay =
     Case 
          When @StartTime >= Convert(datetime, Convert(varchar(4),DatePart(yyyy, @StartTime)) + '-' + Convert(varchar(2), DatePart(mm, @StartTime)) + '-' + Convert(varchar(2), DatePart(dd, @StartTime)) + ' ' + @MillStartTime) 
          then Convert(datetime, Convert(varchar(4),DatePart(yyyy, @StartTime)) + '-' + Convert(varchar(2), DatePart(mm, @StartTime)) + '-' + Convert(varchar(2), DatePart(dd, @StartTime)) + ' ' + @MillStartTime) 
          Else Convert(datetime, Convert(varchar(4),DatePart(yyyy, dateadd(d, -1, @StartTime))) + '-' + Convert(varchar(2), DatePart(mm, dateadd(d, -1, @StartTime))) + '-' + Convert(varchar(2), DatePart(dd, dateadd(d, -1, @StartTime))) + ' ' + @MillStartTime) 
     End
     Select @DayBeforeStartTime = Convert(datetime, Convert(varchar(4),DatePart(yyyy, dateadd(d, -1, @StartTime))) + '-' + Convert(varchar(2), DatePart(mm, dateadd(d, -1, @StartTime))) + '-' + Convert(varchar(2), DatePart(dd, dateadd(d, -1, @StartTime))) + ' ' + @MillStartTime) 
     Select @DayAfterEndTime =  Convert(datetime, Convert(varchar(4),DatePart(yyyy, dateadd(d, 1, @EndTime))) + '-' + Convert(varchar(2), DatePart(mm, dateadd(d, 1, @EndTime))) + '-' + Convert(varchar(2), DatePart(dd, dateadd(d, 1, @EndTime))) + ' ' + @MillStartTime) 
     ------------------------------------------------------------
     -- Populate Crew Schedule Table
     ------------------------------------------------------------
/*
     -- This should be populated by the calling stored procedure
     Insert Into #CrewSchedule(Start_Time, End_Time, Shift_Desc, Crew_Desc) select * from dbo.fnRS_wrGetCrewSchedule(@StartTime, @EndTime, @Unit)
     Update #CrewSchedule Set Shift_Duration = DateDiff(mi, Start_Time, End_Time)
*/     
     ------------------------------------------------------------
     -- Populate Product Run Times
     ------------------------------------------------------------
     Insert Into #ProductRunTimes(Prod_Id, Prod_Start_Time, Prod_End_Time)
     select ps.Prod_Id, ps.Start_Time, ps.End_Time
          from Production_Starts ps 
          Join Products p on p.Prod_Id = ps.Prod_Id
          where ps.PU_id = @Unit 
               and ps.Start_Time <= @EndTime
               and ((ps.End_Time > @StartTime) or (ps.End_Time Is Null))
          order by ps.Start_Time
     ------------------------------------------------------------
     -- Populate Process Order Table
     ------------------------------------------------------------
     Create Table #ProcessOrder(
          Event_id int,
          Timestamp datetime,
          ProcessOrderId int,
          ProcessOrderStartTime datetime,
          ProcessOrderEndTime datetime
     )
     insert into #ProcessOrder(Event_Id, Timestamp, ProcessOrderId)
       Select e.event_id, e.Timestamp, d.pp_id
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
     Update #ProcessOrder 
       Set ProcessOrderId = (Select min(ps.pp_id) 
                              From production_plan_starts ps 
                              where ps.pu_id = @Unit 
                              and ps.Start_Time <= #ProcessOrder.Timestamp 
                              and ((ps.End_Time > #ProcessOrder.Timestamp) or (ps.End_Time is Null)))
       Where ProcessOrderId Is Null          
     ------------------------------------------------------------------------
     update #ProcessOrder Set
          ProcessOrderStartTime = Actual_Start_Time,
          ProcessOrderEndTime = Actual_End_Time
          From Production_Plan pp
          where pp.pp_Id = #ProcessOrder.ProcessOrderId
     ------------------------------------------------------------------------     
     insert Into #ProcessOrderTimes(Process_Order_Id, Order_Start_Time, Order_End_Time)
          select distinct ProcessOrderId, ProcessOrderStartTime, ProcessOrderEndTime from #ProcessOrder where Processorderid is not null order by ProcessOrderStartTime
     Drop Table #ProcessOrder
     ------------------------------------------------------------
     -- Get All Downtime Info From StartTime to EndTime
     ------------------------------------------------------------
     insert into #TempDowntime
     Select TEDet_Id, Start_Time, End_Time
     From Timed_Event_Details
       Where PU_Id = @Unit
             and ((Start_Time < @EndTime) 
             and (End_Time > @StartTime or End_Time Is Null))
     Declare MyCursor INSENSITIVE CURSOR
       For (
             Select TEDet_Id, Start_Time, End_Time From #TempDownTime
           )
       For Read Only
       Open MyCursor  
     MyLoop1:
       Fetch Next From MyCursor Into @TEDet_Id, @CurStartTime, @CurEndTime 
       If (@@Fetch_Status = 0)
         Begin
               -- Get Production Day For Given Event StartTime
               Select @ProductionDay =
               Case 
                    When @CurStartTime >= Convert(datetime, Convert(varchar(4),DatePart(yyyy, @CurStartTime)) + '-' + Convert(varchar(2), DatePart(mm, @CurStartTime)) + '-' + Convert(varchar(2), DatePart(dd, @CurStartTime)) + ' ' + @MillStartTime) 
                    then Convert(datetime, Convert(varchar(4),DatePart(yyyy, @CurStartTime)) + '-' + Convert(varchar(2), DatePart(mm, @CurStartTime)) + '-' + Convert(varchar(2), DatePart(dd, @CurStartTime)) + ' ' + @MillStartTime) 
                    Else Convert(datetime, Convert(varchar(4),DatePart(yyyy, dateadd(d, -1, @CurStartTime))) + '-' + Convert(varchar(2), DatePart(mm, dateadd(d, -1, @CurStartTime))) + '-' + Convert(varchar(2), DatePart(dd, dateadd(d, -1, @CurStartTime))) + ' ' + @MillStartTime) 
               End
               ------------------------------------------------------------
               -- Get Downtime By Production Day
               ------------------------------------------------------------
               -- Does Event Range Cross Production Day Start Time?
               If (@CurStartTime < @ProductionDay) AND (@CurEndTime >= @ProductionDay)
                    Begin
                         -- insert 2 rows
                         Insert Into #ProductionDayDowntime(TEDet_Id, ProductionDay, Start_Time, End_Time, Duration)
                         Values(@TEDet_Id, @ProductionDay, @CurStartTime, @ProductionDay, DateDiff(mi, @CurStartTime, @ProductionDay)  )
                         Insert Into #ProductionDayDowntime(TEDet_Id, ProductionDay, Start_Time, End_Time, Duration)
                         Values(@TEDet_Id, @ProductionDay, @ProductionDay, @CurEndTime, DateDiff(mi, @ProductionDay, @CurEndTime)  )
                    End
               Else
                    Begin
                         -- insert 1 row
                         Insert Into #ProductionDayDowntime(TEDet_Id, ProductionDay, Start_Time, End_Time, Duration)
                         Values(@TEDet_Id, @ProductionDay, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, @CurEndTime)  )
                    End
               ------------------------------------------------------------
               -- Get Downtime By Shift and Crew
               ------------------------------------------------------------
               Insert Into #ShiftCrewDownTime(TEDet_Id, Start_Time, End_Time, Duration, Shift_Desc, Crew_Desc, Shift_Duration)
               Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, @CurEndTime), Shift_Desc, Crew_Desc, DateDiff(mi, cs.Start_Time, cs.End_Time)
               From #CrewSchedule cs
               Where (@CurStartTime between cs.Start_Time and cs.End_Time)
                     And (@CurEndTime Between cs.Start_Time and cs.End_Time)
               If @@RowCount = 0 
                    Begin
                         Insert Into #ShiftCrewDownTime(TEDet_Id, Start_Time, End_Time, Duration, Shift_Desc, Crew_Desc, Shift_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, cs.End_Time), Shift_Desc, Crew_Desc, DateDiff(mi, cs.Start_Time, cs.End_Time)
                         From #CrewSchedule cs
                         Where (@CurStartTime between cs.Start_Time and cs.End_Time)
                         If @@RowCount = 0
                              Print 'No Match On StartTime'
                         Insert Into #ShiftCrewDownTime(TEDet_Id, Start_Time, End_Time, Duration, Shift_Desc, Crew_Desc, Shift_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, cs.Start_Time, @CurEndTime), Shift_Desc, Crew_Desc, DateDiff(mi, cs.Start_Time, cs.End_Time)
                         From #CrewSchedule cs
                         Where (@CurEndTime between cs.Start_Time and cs.End_Time)
                         If @@RowCount = 0
                              Print 'No Match On EndTime'                    
                    End
               ------------------------------------------------------------
               -- Get Downtime By Process Order
               -- Did DownTime Cross Start/End of a Process Order          
               ------------------------------------------------------------
               Insert Into #ProcessOrderDowntime(TEDet_Id, Start_Time, End_Time, Duration, Process_Order_Id, Process_Order_Duration)
               Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, @CurEndTime), POT.Process_Order_Id, DateDiff(mi, POT.Order_Start_Time, POT.Order_End_Time)
               From #ProcessOrderTimes POT
               Where (@CurStartTime between POT.Order_Start_Time and POT.Order_End_Time)
                     And (@CurEndTime Between POT.Order_Start_Time and POT.Order_End_Time)
               If @@RowCount = 0 
                    Begin
                         Insert Into #ProcessOrderDowntime(TEDet_Id, Start_Time, End_Time, Duration, Process_Order_Id, Process_Order_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, POT.Order_End_Time), POT.Process_Order_Id, DateDiff(mi, POT.Order_Start_Time, POT.Order_End_Time)
                         From #ProcessOrderTimes POT
                         Where (@CurStartTime between POT.Order_Start_Time and POT.Order_End_Time)
                         Insert Into #ProcessOrderDowntime(TEDet_Id, Start_Time, End_Time, Duration, Process_Order_Id, Process_Order_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, POT.Order_Start_Time, @CurEndTime), POT.Process_Order_Id, DateDiff(mi, POT.Order_Start_Time, POT.Order_End_Time)
                         From #ProcessOrderTimes POT
                         Where (@CurEndTime between POT.Order_Start_Time and POT.Order_End_Time)
                    End
               ------------------------------------------------------------
               -- Get Downtime By Product Run
               -- Did DownTime Cross Start/End of a Product Run          
               ------------------------------------------------------------
               Insert Into #ProductDownTime(TEDet_Id, Start_Time, End_Time, Duration, Prod_Id, Prod_Run_Duration)
               Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, @CurEndTime), PRT.Prod_Id, DateDiff(mi, PRT.Prod_Start_Time, PRT.Prod_End_Time)
               From #ProductRunTimes PRT
               Where (@CurStartTime between PRT.Prod_Start_Time and PRT.Prod_End_Time)
                     And (@CurEndTime Between PRT.Prod_Start_Time and PRT.Prod_End_Time)
               if @@RowCount = 0
                    Begin
                         Insert Into #ProductDownTime(TEDet_Id, Start_Time, End_Time, Duration, Prod_Id, Prod_Run_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, @CurStartTime, PRT.Prod_End_Time), PRT.Prod_Id, DateDiff(mi, PRT.Prod_Start_Time, PRT.Prod_End_Time)
                         From #ProductRunTimes PRT
                         Where (@CurStartTime between PRT.Prod_Start_Time and PRT.Prod_End_Time)
                         Insert Into #ProductDownTime(TEDet_Id, Start_Time, End_Time, Duration, Prod_Id, Prod_Run_Duration)
                         Select @TEDet_Id, @CurStartTime, @CurEndTime, DateDiff(mi, PRT.Prod_Start_Time, @CurEndTime), PRT.Prod_Id, DateDiff(mi, PRT.Prod_Start_Time, PRT.Prod_End_Time)
                         From #ProductRunTimes PRT
                         Where (@CurEndTime between PRT.Prod_Start_Time and PRT.Prod_End_Time)
                    End
            Goto MyLoop1
         End 
     myEnd:
     Close MyCursor
     Deallocate MyCursor
     drop table #TempDowntime
     Drop Table #ProcessOrderTimes
     drop table #ProductRunTimes
Insert Into #PivotDownTimeByProductionDay(Production_Day, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     SELECT ProductionDay, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         1440 - Sum(Duration) AS RunTimeMinutes,
         (Sum(Duration) * 100) / 1440  AS PercentUpTime
     FROM #ProductionDayDowntime
     GROUP BY ProductionDay
     Order By ProductionDay
Insert Into #PivotDownTimeByShift(Shift_Desc, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     SELECT Shift_Desc, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         SUM(Shift_Duration) - SUM(Duration) AS RunTimeMinutes,
         100 - ((SUM(Shift_Duration) - Sum(Duration)) * 100) / SUM(Shift_Duration)  AS PercentUpTime
     FROM #ShiftCrewDownTime
     GROUP BY Shift_Desc
     Order By Shift_Desc
Insert Into #PivotDownTimeByCrew(Crew_Desc, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     SELECT Crew_Desc, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         SUM(Shift_Duration) - SUM(Duration) AS RunTimeMinutes,
         100 - ((SUM(Shift_Duration) - Sum(Duration)) * 100) / SUM(Shift_Duration)  AS PercentUpTime
     FROM #ShiftCrewDownTime
     GROUP BY Crew_Desc
     Order By Crew_Desc
Insert Into #PivotDownTimeProcessOrder(Process_Order_id, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     Select Process_Order_Id,
          Count(*) AS DownTimeEvents,
          SUM(Duration) AS DownTimeMinutes,
          Sum(Process_Order_Duration) - Sum(Duration) AS RunTimeMinutes,
         100 - ((SUM(Process_Order_Duration) - Sum(Duration)) * 100) / SUM(Process_Order_Duration)  AS PercentUpTime
     From #ProcessOrderDownTime
     Group By Process_Order_Id
     Order By Process_Order_Id
Insert Into #PivotDownTimeByProduct(Prod_id, Downtime_Events, Downtime_Minutes, Runtime_Minutes, Percent_DownTime)
     Select Prod_id,
          Count(*) AS DownTimeEvents,
          SUM(Duration) AS DownTimeMinutes,
          Sum(Prod_Run_Duration) - Sum(Duration) AS RunTimeMinutes,
         100 - ((SUM(Prod_Run_Duration) - Sum(Duration)) * 100) / SUM(Prod_Run_Duration)  AS PercentUpTime
     From #ProductDownTime
     Group By Prod_id
     Order By Prod_id
-- Comment out after this     
/*
     SELECT ProductionDay, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         1440 - Sum(Duration) AS RunTimeMinutes,
         ((1440 - Sum(Duration)) * 100) / 1440  AS PercentUpTime
     FROM #ProductionDayDowntime
     GROUP BY ProductionDay
     Order By ProductionDay
     SELECT Shift_Desc, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         SUM(Shift_Duration) - SUM(Duration) AS RunTimeMinutes,
         ((SUM(Shift_Duration) - Sum(Duration)) * 100) / SUM(Shift_Duration)  AS PercentUpTime
     FROM #ShiftCrewDownTime
     GROUP BY Shift_Desc
     Order By Shift_Desc
     SELECT Crew_Desc, 
         Count(*) AS DownTimeEvents,
         SUM(Duration) AS DownTimeMinutes,
         SUM(Shift_Duration) - SUM(Duration) AS RunTimeMinutes,
         ((SUM(Shift_Duration) - Sum(Duration)) * 100) / SUM(Shift_Duration)  AS PercentUpTime
     FROM #ShiftCrewDownTime
     GROUP BY Crew_Desc
     Order By Crew_Desc
     Select Process_Order_Id,
          Count(*) AS DownTimeEvents,
          SUM(Duration) AS DownTimeMinutes,
          Sum(Process_Order_Duration) - Sum(Duration) AS RunTimeMinutes,
         ((SUM(Process_Order_Duration) - Sum(Duration)) * 100) / SUM(Process_Order_Duration)  AS PercentUpTime
     From #ProcessOrderDownTime
     Group By Process_Order_Id
     Order By Process_Order_Id
     Select Prod_Id,
          Count(*) AS DownTimeEvents,
          Sum(Duration) AS DownTimeMinutes,
          Sum(Prod_Run_Duration) - Sum(Duration) AS RunTimeMinutes,
         ((SUM(Prod_Run_Duration) - Sum(Duration)) * 100) / SUM(Prod_Run_Duration)  AS PercentUpTime
     From #ProductDownTime
     Group By Prod_Id
     Order By Prod_Id
     -- Downtime By Status is handled in the parent procedure
     -- downtime by Event is handled in the parent procedure
     drop table #CrewSchedule
     drop table #ProductionDayDowntime
     drop table #ShiftCrewDowntime
     drop table #ProcessOrderDownTime
     drop table #ProductDownTime
--*/     
     drop table #ProductionDayDowntime
     drop table #ShiftCrewDowntime
     drop table #ProcessOrderDownTime
     drop table #ProductDownTime
