CREATE FUNCTION dbo.fnCMN_GetOutsideAreaTimeByUnit(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @FILTER_NP_TIME INT) 
     RETURNS @OutsideAreaTime Table (TotalSeconds FLOAT, DowntimeSeconds FLOAT, RunningSeconds FLOAT, LoadingSeconds FLOAT, OutsideAreaSeconds FLOAT, UnavailableSeconds FLOAT, PerformanceDowntimeSeconds FLOAT, NonProductiveSeconds FLOAT, DowntimeCount INT)
AS 
Begin
--******************************************************/
     --------------------------------------------------------------
     -- Local Variables
     --------------------------------------------------------------
     DECLARE @Downtime_External_Category int
     DECLARE @Downtime_Scheduled_Category int
     DECLARE @Performance_Downtime_Category int
     DECLARE @TotalOutsideAreaSeconds FLOAT
     DECLARE @TotalUnavailableTimeSeconds FLOAT
     DECLARE @ActualLoadingTimeSeconds FLOAT
     DECLARE @PerformanceDowntimeSeconds FLOAT
     DECLARE @TotalDowntimeSeconds FLOAT
     DECLARE @ActualDowntimeSeconds FLOAT
 	 DECLARE @ScheduledDowntimeSeconds FLOAT
     DECLARE @TotalSeconds FLOAT
     DECLARE @RunningSeconds FLOAT
     DECLARE @LoadingSeconds FLOAT
     DECLARE @NonProductiveSeconds FLOAT
     DECLARE @DTCount INT
 	 DECLARE @UnplannedDowntime FLOAT 	 
 	 DECLARE @RunTimes TABLE(Id int identity(1,1), Start_Time datetime, End_Time datetime)
 	 DECLARE @ST datetime, @ET datetime, @Id int
 	  --------------------------------------------
 	  -- Default is DO NOT FILTER
 	  --------------------------------------------
     If @FILTER_NP_TIME Is Null 
 	  	 Select @FILTER_NP_TIME = 0
 	   Select @NonProductiveSeconds = 0
 	  --------------------------------------------
 	  -- Get Downtime Categories
 	  --------------------------------------------
     Select 
 	  	 @Downtime_Scheduled_Category = Coalesce(Downtime_Scheduled_Category, 0), 
 	  	 @Downtime_External_Category = Coalesce(Downtime_External_Category, 0),
 	  	 @Performance_Downtime_Category = Coalesce(Performance_Downtime_Category, 0)
 	    From Prod_Units Where PU_Id = @Unit
 	  --------------------------------------------
 	  -- Get Productive Times
 	  --------------------------------------------
 	  If @Filter_NP_TIME <> 0 
 	  	 Begin
 	  	  	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	  	  	 Select * from dbo.fnCMN_GetProductiveTimes(@Unit, @StartTime, @EndTime)
 	  	  	 --Select @NonProductiveSeconds = dbo.fnCmn_SecondsNPTime(@Unit, @StartTime, @EndTime)
 	  	  	 Select @NonProductiveSeconds = DateDiff(second, @StartTime, @EndTime) - (Select Sum(DateDiff(s, Start_Time, End_Time)) From @RunTimes)
 	  	 End
 	  Else
 	  	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	  	 Values(@StartTime, @EndTime)
 	 --------------------------------------------------------------------
 	 -- NEW Get All Downtime Events That Occurred During Running Periods
 	 --------------------------------------------------------------------
 	 DECLARE @TempDowntimeData TABLE(TEDet_Id int, ERC_ID int, Start_Time datetime, End_Time datetime, Count_Event int, Actual_DT_Start datetime, Actual_DT_End datetime)
 	 DECLARE MyCursor  CURSOR
 	   For ( Select Id, Start_Time, End_Time From @RunTimes )
 	   For Read Only
 	   Open MyCursor  
 	 
 	   Fetch Next From MyCursor Into @Id, @ST, @ET 
 	   While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	  Insert Into @TempDowntimeData(TEDet_Id, ERC_ID, Start_Time, End_Time, Count_Event, Actual_DT_Start, Actual_DT_End)
 	  	  	  Select
 	  	  	  	 d.TEDet_Id,
 	  	  	  	 c.ERC_ID, 
 	  	  	  	 CASE WHEN d.Start_Time < @ST THEN @ST ELSE d.Start_Time END,
 	  	  	  	 CASE WHEN d.End_Time IS NULL THEN @ET
 	  	  	  	  	  WHEN d.End_Time > @ET THEN @ET
 	  	  	  	  	  ELSE d.End_Time
 	  	  	  	 END,
 	  	  	  	 CASE WHEN d.Start_Time >= @ST Then 1 ELSE 0 END,
 	  	  	  	 d.Start_Time,
 	  	  	  	 d.End_Time
 	  	  	  FROM Timed_Event_Details d
 	  	  	  	   LEFT OUTER JOIN Event_Reason_Category_data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id
 	  	  	  WHERE d.PU_Id = @Unit
 	  	  	  	   AND d.Start_Time < @ET and ((d.End_Time > @ST) or (d.End_Time Is NULL))
 	  	  	 /*
 	  	  	  	 JOIN only gets downtime events that have a category
 	  	  	  	 LEFT OUTER JOIN gets all dowtime events with a category or not
 	  	  	 */
 	  	  	 Fetch Next From MyCursor Into @Id, @ST, @ET 
 	  	 End 
 	 
 	 Close MyCursor
 	 Deallocate MyCursor
 	 -- A Single Downtime Event Can Have Multiple Categories But Can Only Be Counted Once
 	 Declare @DistinctDowntime Table (TEDet_Id int, Start_Time datetime, End_Time datetime, DT int, Count_Event int)
 	 Insert into @DistinctDowntime
 	  	 Select distinct TEDet_Id, Start_Time, End_Time, datediff(second, Start_Time, End_Time), Case When Start_Time >= @StartTime Then 1 Else 0 End from @TEmpDowntimeData
 	 -- All downtime seconds are counted for a given reporting period
 	 -- But the occurence of the downtime event is only counted if it began during the reporting period
 	 --   This avoids double counting an individual DT event when summarizing by shift, crew, day...
 	 Select @TotalDowntimeSeconds = IsNull(sum(DT), 0), @DTCount = IsNull(Sum(Count_Event), 0) from @DistinctDowntime
 	 Select @TotalSeconds = IsNULL(Sum(DateDiff(s, Start_Time, End_Time)),0) From @RunTimes
 	 Select 	 @TotalUnavailableTimeSeconds=IsNULL(Sum(CASE When ERC_Id = @Downtime_Scheduled_Category THEN DATEDIFF(second,Start_Time, End_Time)ELSE 0 END),0) , 
 	  	  	 @TotalOutsideAreaSeconds=IsNULL(Sum(CASE When ERC_Id = @Downtime_External_Category THEN DATEDIFF(second,Start_Time, End_Time)ELSE 0 END),0),
 	  	  	 @PerformanceDowntimeSeconds=IsNULL(Sum(CASE When ERC_Id = @Performance_Downtime_Category THEN DATEDIFF(second,Start_Time, End_Time)ELSE 0 END),0)
 	 From @TempDowntimeData 
 	 Where ERC_Id in (@Downtime_Scheduled_Category, @Downtime_External_Category,@Performance_Downtime_Category)
 	 Select @LoadingSeconds = @TotalSeconds - (@TotalUnavailableTimeSeconds + @TotalOutsideAreaSeconds)
 	 Select @UnplannedDowntime = @TotalDowntimeSeconds - (@TotalUnavailableTimeSeconds + @TotalOutsideAreaSeconds + @PerformanceDowntimeSeconds)
 	 Insert Into @OutsideAreaTime(TotalSeconds,  DowntimeSeconds,    RunningSeconds,  LoadingSeconds,  OutsideAreaSeconds,       UnavailableSeconds,           PerformanceDowntimeSeconds,  NonProductiveSeconds,  DowntimeCount)
 	  	 Select @TotalSeconds, 
 	  	  	 @UnplannedDowntime, 
 	  	  	 @LoadingSeconds - @UnplannedDowntime, 
 	  	  	 @LoadingSeconds, 
 	  	  	 @TotalOutsideAreaSeconds, 
 	  	  	 @TotalUnavailableTimeSeconds, 
 	  	  	 @PerformanceDowntimeSeconds, 
 	  	  	 IsNULL(@NonProductiveSeconds,0), 
 	  	  	 @DTCount
    /*
 	 RunningSeconds is also called Equipment Operating Time or (LoadingTime - Downtime)
 	 Downtime has 3 major time categories that we can excuse for the purposes of reporting.
        Meaning, we don't want this time to count against our performance.
 	 1. Planned Downtime (TotalUnavailableTimeSeconds)
 	 2. Outside Area     (TotalOutsideAreaSeconds)
 	 3. Performance      (PerformanceDowntimeSeconds)
 	 Any additional downtime besides these 3 categories is considered "True" downtime.
 	 The correct method of calculating running seconds (or Operating Time) is as follows:
        LoadingTime - "True" Downtime
        Where "True" Downtime is
           TotalDowntime - UnavailableTime - OutsideAreaTime - PerformanceDowntime
 	 
    */
--select * from @OutsideAreaTime
--/*********************************************
     RETURN
END
--********************************************/
