CREATE FUNCTION dbo.fnCMN_GetProductionWasteByUnit(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @FILTER_NP_TIME INT) 
     RETURNS @WasteTotals Table (TotalWaste FLOAT, TimeBasedWaste FLOAT, EventBasedWaste FLOAT)
AS 
Begin
--**************************************/
--------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------
     Declare @TotalWaste FLOAT, @TimeBasedWaste FLOAT, @EventBasedWaste FLOAT
 	  DECLARE @NPCategoryId Int, @NPTime Int
 	  DECLARE @NPT Table (StartTime DateTime, EndTime DateTime)
     Select @TotalWaste = 0, @TimeBasedWaste = 0, @EventBasedWaste = 0
 	 
 	  -- Initialize NP Filter To False if Null Passed in
 	  If @Filter_NP_Time Is Null Select @Filter_NP_Time = 0
     ------------------------------------------------
     -- Get Time Based Waste Amounts (not pro-rated)
     ------------------------------------------------
 	 If @FILTER_NP_TIME <> 0
 	  	 Begin
 	  	      Select @TimeBasedWaste = coalesce(sum(amount),0) 
 	  	        From Waste_Event_Details w
 	  	        Where PU_id = @Unit 
 	  	  	  	  	 and Timestamp > @StartTime 
 	  	  	  	  	 and Timestamp <= @EndTime 
 	  	  	  	  	 and Event_Id Is Null 
 	  	  	  	  	 and amount is not null  
 	 
 	  	 End
 	 Else
 	  	 Begin
 	  	      Select @TimeBasedWaste = coalesce(sum(amount),0) 
 	  	        From Waste_Event_Details_NPT w
 	  	        Where PU_id = @Unit 
 	  	  	  	  	 and Timestamp > @StartTime 
 	  	  	  	  	 and Timestamp <= @EndTime 
 	  	  	  	  	 and Event_Id Is Null 
 	  	  	  	  	 and amount is not null  
 	  	  	  	  	 and (@Filter_NP_Time = 0 or w.Is_Non_Productive = 0) 
 	 
 	  	 End
     ------------------------------------------------
     -- Get Event Based Waste Amounts (pro-rated)
     ------------------------------------------------
 	  Declare @EventTable TABLE (Id int identity(1,1), Event_Id int, Waste FLOAT, PR_Waste FLOAT, Event_Start_Time datetime, Event_End_Time datetime,
 	  	 PR_Start_Time datetime, PR_End_Time datetime,
 	  	 Productive_Start_Time datetime, Productive_End_Time datetime
 	  )
 	 
 	 
 	 --Get the timestamp of the event that immediately follows (or is equal to) the EndTime of the report
 	 declare @NextEventTime datetime
 	 Select @NextEventTime = min(Timestamp)  
 	 From Events 
 	 Where Timestamp  >= @endtime 
 	  	 AND pu_id = @Unit 
 	  	 AND (Start_Time < @endtime OR Start_Time IS NULL)
 	 If @NextEventTime Is Null
 	  	 select @NextEventTime = @EndTime
 	 -- Get all events that encompass our report range, including those that cross report borders
 	 Insert into @EventTable(Event_Id, Event_Start_Time, Event_End_Time, Waste, PR_Start_Time, PR_End_Time)
 	  	 SELECT 
 	  	  	 e.Event_Id,
 	  	  	 e.Actual_Start_Time, 
 	  	  	 e.TimeStamp,
 	  	  	 ISNULL(w.amount,0),
 	  	  	 case when Actual_Start_Time < @StartTime Then @StartTime Else Actual_Start_Time End [Actual_Start_time],
 	  	  	 case when e.TimeStamp > @EndTime then @EndTime Else e.Timestamp end [Actual_End_Time]
 	  	 From Events_With_Starttime e
 	  	  	 JOIN Waste_Event_Details w on w.Event_Id = e.Event_Id
 	  	 WHERE e.pu_id = @Unit and
 	  	    e.Timestamp > @StartTime and
 	  	    e.Timestamp <= @NextEventTime
 	  	 ORDER BY e.Timestamp
 	 -- Prorate Waste Based On Non-Productive Time
 	 If @FILTER_NP_TIME <> 0
 	  	 Begin
 	  	  	 -- Update NP StartTime
 	  	  	 Update @EventTable Set Productive_Start_Time = dbo.fnCmn_ModifyNPTimeRange(@Unit, PR_Start_Time, PR_End_Time, 1)
 	  	  	 -- Update NP EndTime
 	  	  	 Update @EventTable Set Productive_End_Time = dbo.fnCmn_ModifyNPTimeRange(@Unit, PR_Start_Time, PR_End_Time, 0)
 	  	  	 -- Remove Events where event duration is entirely within NP time
 	  	  	 Delete From @EventTable Where (Productive_Start_Time Is Null) and (Productive_End_Time Is Null)
 	  	  	 --Sum NPT that occurs within an event to remove
 	  	  	 SELECT @NPCategoryId = Non_Productive_Category
 	  	  	 FROM dbo.Prod_Units
 	  	  	 WHERE PU_Id = @Unit
 	  	  	 INSERT INTO @NPT(StartTime, EndTime)
 	  	  	 SELECT 	 StartTime 	 = CASE 	 WHEN np.Start_Time <et.Productive_Start_Time THEN et.Productive_Start_Time
 	  	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > et.Productive_End_Time THEN et.Productive_End_Time
 	  	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	  	 END
 	  	  	 FROM @EventTable et
 	  	  	  	 JOIN dbo.NonProductive_Detail np ON np.Start_Time > et.Productive_Start_Time AND np.End_Time < et.Productive_End_Time
 	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
 	  	  	 WHERE 	 np.PU_Id = 1
 	  	  	  	  	 AND np.Start_Time < et.Productive_End_Time
 	  	  	  	  	 AND np.End_Time > et.Productive_Start_Time
 	  	  	 SELECT @NPTime = ISNULL(SUM(datediff(s,StartTime,EndTime)),0) FROM @NPT
 	  	  	 Update @EventTable Set 
 	  	  	  	 PR_Waste = CASE WHEN DateDiff(s, Event_Start_Time, Event_End_Time) = 0 THEN 0
 	  	  	  	  	  	  	 ELSE Waste / DateDiff(s, Event_Start_Time, Event_End_Time) * (DateDiff(s, Productive_Start_Time, Productive_End_Time) - @NPTime)
 	  	  	  	  	  	    END
 	  	 End
 	 -- Pro-Rating based on report time
 	 Else
 	  	 Begin
 	  	  	 Update @EventTable Set 
 	  	  	  	 PR_Waste = Case When Event_Start_Time = Event_End_Time Then 0 
 	  	  	  	  	  	  	  	 Else (Waste / DateDiff(s, Event_Start_Time, Event_End_Time)) * DateDiff(s, PR_Start_Time, PR_End_Time) End
 	  	 End
 	 
 	 Select @EventBasedWaste = coalesce(sum(PR_Waste),0) From @EventTable
 	 Select @TotalWaste = @EventBasedWaste + @TimeBasedWaste
 	 insert Into @WasteTotals(TotalWaste, TimeBasedWaste, EventBasedWaste)
 	 Values(Coalesce(@TotalWaste,0), Coalesce(@TimeBasedWaste,0), Coalesce(@EventBasedWaste,0))
-- 	 select * from @WasteTotals
--/*
     RETURN
END
--*/
