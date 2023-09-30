CREATE PROCEDURE dbo.spServer_SchMgrCalcStats     
@PPId int,
@ParentPPId int OUTPUT
 AS 
/************************************************************
-- For Testing
--************************************************************
Declare
@PPId int,
@ParentPPId int
Select @PPId = 9364
--************************************************************/
Declare
  @PathId int,
  @ControlType int,
  @ForecastStartTime datetime,
  @ForecastEndTime datetime,
  @LateItems int,
  @PPStartId int,
  @StartTime datetime,
  @EndTime datetime,
  @PUId int,
  @PPSetupId int,
  @ProductionType int,
  @ProductionVariable int,
  @IsProductionPoint int,
  @MinStartTime datetime,
  @MaxEndTime datetime,
  @MinSetupStartTime datetime,
  @MaxSetupEndTime datetime,
  @CurrentTime datetime,
  @RunningTimeSeconds float,
  @DowntimeSeconds float,
  @GoodQuantity float,
  @BadQuantity float,
  @AlarmCount int,
  @GoodItems int,
  @BadItems int,
  @Repetitions int
Declare @Setups table (Id Int Identity(1,1), SetupId Int)
Declare @SetupCount Int
Declare @SetupIndex Int
Declare @DummyVarId int
Select @PathId = NULL
Select @ControlType = NULL
Select @ForecastStartTime = NULL
Select @ForecastEndTime = NULL
Select @ParentPPId = NULL
Select @CurrentTime = dbo.fnServer_CmnGetDate(GetUTCDate())
--**********************************************
-- Get This Process Order Details
--**********************************************
Select     	    @PathId = Path_Id, 
        @ControlType = Control_Type,
        @ForecastStartTime = Forecast_Start_Date,
        @ForecastEndTime = Forecast_End_Date,
        @ParentPPId = Parent_PP_Id
  From Production_Plan Where (PP_Id = @PPId)
If (@PathId Is NULL)
Begin
 	 Select @ParentPPId = NULL
 	 Return
End
If (@PPId = @ParentPPId)
  Begin
    Select @ParentPPId = NULL
  End
--**********************************************
-- Get Alarms, Late Items
--**********************************************
--alarms
Select @AlarmCount = NULL
Select @AlarmCount = Count(Key_Id) 
  From Alarms 
  Where Key_Id = @PPId and
        Alarm_Type_id = 3
If @AlarmCount Is Null
  Select @AlarmCount = 0
--late items
Select @LateItems = NULL
--TODO: This needs work, probably won't do here
--Execute spServer_SchMgrGetLateItems @PPId,@LateItems OUTPUT
If (@LateItems Is Null)
  Select @LateItems = 0
--**********************************************
-- Get Initial Statistics For Process Order 
--  And Setup / Sequences
--**********************************************
Declare @Stats Table(
  StatId int Identity(1,1) PRIMARY KEY CLUSTERED,
  StatType int,
  Id int, 
  PPStatusId int, 
  StartTime datetime NULL,
  EndTime datetime NULL,
  GoodItems int,
  BadItems int,
  RunningTime float,
  DownTime float,
  GoodQuantity float,
  BadQuantity float,
  PredictedTotalDuration float,
  PredictedRemainingDuration float,
  PredictedRemainingQuantity float,
  AlarmCount int NULL, 
  LateItems int NULL, 
  ActualTime float NULL, 
  ProdRate float NULL, 
  ForecastQty float NULL, 
  Repetitions int NULL
)
Insert Into @Stats(StatType,Id,PPStatusId,StartTime,EndTime,GoodItems,BadItems,RunningTime,DownTime,GoodQuantity,BadQuantity,PredictedTotalDuration,PredictedRemainingDuration,PredictedRemainingQuantity,AlarmCount,LateItems,ForecastQty,Repetitions)
  Select StatType = 1,
         Id = PP_Id,
         PPStatusId = PP_Status_Id,
         StartTime = NULL,
         EndTime = NULL,
         GoodItems = 0,
         BadItems = 0,
         RunningTime = 0.0,
         Downtime = 0.0,
         GoodQuantity = 0.0,
         BadQuantity = 0.0,
         PredictedTotalDuration = 0.0,
         PredictedReaminingDuration = 0.0,
         PredictedRemainingQuantity = 0.0,
         AlarmCount = @AlarmCount,
         LateItems = @LateItems,
         ForecastQty = Forecast_Quantity,
         Repetitions = 0
  From Production_Plan 
  Where PP_Id = @PPId
Insert Into @Stats(StatType,Id,PPStatusId,StartTime,EndTime,GoodItems,BadItems,RunningTime,DownTime,GoodQuantity,BadQuantity,PredictedTotalDuration,PredictedRemainingDuration,PredictedRemainingQuantity,AlarmCount,LateItems,ForecastQty,Repetitions)
  Select StatType = 2,
         Id = PP_Setup_Id,
         PPStatusId = PP_Status_Id,
         StartTime = NULL,
         EndTime = NULL,
         GoodItems = 0,
         BadItems = 0,
         RunningTime = 0.0,
         Downtime = 0.0,
         GoodQuantity = 0.0,
         BadQuantity = 0.0,
         PredictedTotalDuration = 0.0,
         PredictedRemainingDuration = 0.0,
         PredictedRemainingQuantity = 0.0,
         AlarmCount = 0.0,
         LateItems = 0.0,
         ForecastQty = Forecast_Quantity,
         Repetitions = 0
  From Production_Setup 
  Where PP_Id = @PPId
Delete From @Stats 
  Where (StatType = 2) And 
        (Id In (Select Distinct(Parent_PP_Setup_Id) From Production_Setup Where (PP_Id = @PPId)))
--**************************************************************
-- Get all PPid set in details
--**************************************************************
Set @GoodQuantity = 0
Set @BadQuantity = 0
Set @GoodItems = 0
Set @BadItems = 0
If EXISTS
( 	  
    /*Select 
  	  1
  	  From Production_Plan pp
  	  Join Production_Plan_Starts pps on pp.PP_Id = pps.PP_Id
  	  Join Prod_Units_Base pu on pps.PU_Id = pu.PU_Id
  	  Where pp.PP_Id = @PPId and pps.Is_Production =1 and pu.Production_Variable iS NULL*/ -- IM: We should hook to path definition instead of expecting a start records to exist
 	  
 	  Select 1
  	  From Production_Plan pp
  	  Join PrdExec_Path_Units ppu on pp.Path_Id = ppu.Path_Id
  	  Join Prod_Units_Base pu on ppu.PU_Id = pu.PU_Id
  	  Where pp.PP_Id = @PPId and ppu.Is_Production_Point = 1 and pu.Production_Variable is NULL
)
Execute spServer_SchMgrGetGoodAndBad @PPId,Null,null,null,null,Null,@GoodQuantity OUTPUT,@BadQuantity OUTPUT,@GoodItems OUTPUT,@BadItems OUTPUT,1
Update @Stats Set 
   	  GoodQuantity = GoodQuantity + @GoodQuantity,
   	  BadQuantity = BadQuantity + @BadQuantity,
 	  GoodItems = GoodItems + @GoodItems,
 	  BadItems = BadItems + @BadItems,
   	  Repetitions = Repetitions + @GoodItems + @BadItems
 	 Where (StatType = 1) And (Id = @PPId)
--**************************************************************
-- Get all PPSetupid set in details
--**************************************************************
Insert into @Setups (SetupId)
Select Distinct a.pp_setup_id
 	    From Production_Plan_Starts a
 	    Join Prod_Units_Base b on a.PU_Id = b.PU_Id
 	    Where a.PP_Id = @PPId AND Is_Production = 1 AND a.pp_setup_id IS NOT NULL
Select @SetupCount = @@RowCount
Set @SetupIndex = 0
While (@SetupIndex < @SetupCount)
BEGIN
 	 Set @SetupIndex = @SetupIndex + 1
 	 Select @PPSetupId = SetupId from @Setups where Id = @SetupIndex
 	 Set @GoodQuantity = 0
 	 Set @BadQuantity = 0
 	 Set @GoodItems = 0
 	 Set @BadItems = 0
 	 Set @Repetitions = 0
 	 Execute spServer_SchMgrGetGoodAndBad @PPId,@PPSetupId,null,null,null,Null,@GoodQuantity OUTPUT,@BadQuantity OUTPUT,@GoodItems OUTPUT,@BadItems OUTPUT,1,@Repetitions OUTPUT
 	 Update @Stats Set 
 	  	  GoodQuantity = GoodQuantity + @GoodQuantity,
 	  	  BadQuantity = BadQuantity + @BadQuantity,
 	  	  GoodItems = GoodItems + @GoodItems,
 	  	  BadItems = BadItems + @BadItems,
 	  	  Repetitions = Repetitions + @Repetitions
 	  Where (StatType = 2) And (Id = @PPSetupId)
END
--**********************************************
-- Loop Through Production Plan Starts
--**********************************************
Select @MinStartTime = NULL
Select @MaxEndTime = NULL
Declare ProdPlanStarts_Cursor INSENSITIVE CURSOR 
  For Select 
    	    a.PP_Start_Id,
      	    a.Start_Time,
      	    a.End_Time,
      	    a.PU_Id,
      	    a.PP_Setup_Id,
      	    b.Production_Type,
      	    b.Production_Variable,
 	  	    a.Is_Production
    	    From Production_Plan_Starts a
    	    Join Prod_Units_Base b on b.PU_Id = a.PU_Id
    	    Where a.PP_Id = @PPId
    	    Order By a.Start_Time
  For Read Only
  Open ProdPlanStarts_Cursor  
ProdPlanStarts_Loop:
  Fetch Next From ProdPlanStarts_Cursor Into @PPStartId,@StartTime,@EndTime,@PUId,@PPSetupId,@ProductionType,@ProductionVariable,@IsProductionPoint
  If (@@Fetch_status = 0)
    Begin
      -- Set Up Overall Statistics
      If Not((@ProductionType = 1) And (@ProductionVariable Is Not NULL) And (@ProductionVariable > 0))
        Select @ProductionVariable = NULL
      If (@MinStartTime Is NULL) Or (@StartTime < @MinStartTime)
        Select @MinStartTime = @StartTime
      If (@EndTime Is NULL)
        Select @EndTime = @CurrentTime
      If (@MaxEndTime Is NULL) Or (@EndTime > @MaxEndTime)
        Select @MaxEndTime = @EndTime
      Select @GoodQuantity = 0
      Select @BadQuantity = 0
      Select @GoodItems = 0
      Select @BadItems = 0
      Select @DowntimeSeconds = 0
      -- Only Totalize Production / Downtime Stats If This Is Production Point
      If (@IsProductionPoint = 1)
      BEGIN
          Select @RunningTimeSeconds = DateDiff(Second,@StartTime,@EndTime)
          Execute spServer_CmnGetDowntime @PUId,@StartTime,@EndTime,@DowntimeSeconds OUTPUT
          Execute spServer_SchMgrGetGoodAndBad @PPId,Null,@PUId,@StartTime,@EndTime,@ProductionVariable,@GoodQuantity OUTPUT,@BadQuantity OUTPUT,@GoodItems OUTPUT,@BadItems OUTPUT,0
 	    	  Update @Stats Set 
  	    	    	    	  RunningTime = RunningTime + @RunningTimeSeconds,
  	    	    	    	  DownTime = DownTime + @DownTimeSeconds,
  	    	    	    	  GoodQuantity = GoodQuantity + @GoodQuantity,
  	    	    	    	  BadQuantity = BadQuantity + @BadQuantity,
  	    	    	    	  GoodItems = GoodItems + @GoodItems,
  	    	    	    	  BadItems = BadItems + @BadItems,
  	    	    	    	  Repetitions = Repetitions + @GoodItems + @BadItems
  	    	    	    	  Where (StatType = 1) And (Id = @PPId)
     If (@PPSetupId Is Not NULL) And (@PPSetupId > 0)
     BEGIN
          Select @MinSetupStartTime = NULL
          Select @MaxSetupEndTime = NULL
          Select @MinSetupStartTime = StartTime, @MaxSetupEndTime = EndTime From @Stats Where (StatType = 2) And (Id = @PPSetupId)
          If (@StartTime Is Not NULL)
            If (@MinSetupStartTime Is NULL) Or (@StartTime < @MinSetupStartTime)
              Select @MinSetupStartTime = @StartTime
 	  	  	   If (@EndTime Is NULL)
 	  	  	  	 Select @EndTime = @CurrentTime
          If (@MaxSetupEndTime Is NULL) Or (@EndTime > @MaxSetupEndTime)
            Select @MaxSetupEndTime = @EndTime
          -- Update statistics for this setup / sequence.  Only update production stats if this is production point
         Update @Stats 
            Set StartTime = @MinSetupStartTime, 
                EndTime = @MaxSetupEndTime,
 	  	  	  	  	 RunningTime = RunningTime + @RunningTimeSeconds,
 	  	  	  	  	 DownTime = DownTime + @DownTimeSeconds
            Where (StatType = 2) And (Id = @PPSetupId)
     END
  	   END
      Goto ProdPlanStarts_Loop
    End
Close ProdPlanStarts_Cursor 
Deallocate ProdPlanStarts_Cursor
--**********************************************
-- Do Final Calculations On Statistics
--**********************************************
-- update max start and end time of process order
Update @Stats 
  Set StartTime = @MinStartTime, 
      EndTime = @MaxEndTime 
  Where (StatType = 1) And (Id = @PPId)
-- update duration and net good production rates (in seconds)
Update @Stats 
  Set ActualTime = DateDiff(second,StartTime,EndTime),
      ProdRate = Case When RunningTime > 0.0 Then GoodQuantity / RunningTime Else 0.0 End
-- Adjust running time by downtime
Update @Stats 
  Set RunningTime = RunningTime - Downtime
-- update time and quantity statistics based on control type
If (@ControlType = 1) -- Control By Scheduled Duration
  Begin
    	      -- calculate remaining quantity by remaining time and current net production rate
    -- only remaining duration can go negative when over produced   
    	      Update @Stats 
    	        Set PredictedTotalDuration = Case 
                                     when ActualTime > datediff(second,@ForecastStartTime, @ForecastEndTime) then
                                        ActualTime
                                     else 
                                        datediff(second,@ForecastStartTime, @ForecastEndTime)
                                   End,
    	            PredictedRemainingDuration = datediff(second,@ForecastStartTime, @ForecastEndTime) - ActualTime,
    	            PredictedRemainingQuantity =  Case 
      	                                        when ActualTime > datediff(second,@ForecastStartTime, @ForecastEndTime) then
      	                                          0.0
 	  	                                          when ProdRate = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  ForecastQty - GoodQuantity
    	                                          else 
    	                                            (datediff(second,@ForecastStartTime, @ForecastEndTime) - ActualTime) * ProdRate
    	                                          End
  End
Else If (@ControlType = 2) -- Control By Scheduled Quantity
  Begin
    -- calculate remaining duration by remaining quanity and net production rates
    -- only remaining quantity can go negative when over produced
    	      Update @Stats 
    	        Set PredictedTotalDuration = ActualTime + Case 
                                                  when GoodQuantity >= ForecastQty or ProdRate = 0 Then 
                                                    0.0 
                                                  Else 
                                                    (ForecastQty - GoodQuantity) / ProdRate 
                                                  End,
    	            PredictedRemainingDuration = Case 
                                         when GoodQuantity >= ForecastQty Then 
                                           0.0 
                                         when ProdRate = 0 Then 
                                           datediff(second,@ForecastStartTime, @ForecastEndTime) 
                                         Else 
                                           (ForecastQty - GoodQuantity) / ProdRate 
                                        End,
    	            PredictedRemainingQuantity =  (ForecastQty - GoodQuantity) 
    	    
  End
Else If (@ControlType = 3) -- Controlled By Scheduled End Time
  Begin
    -- calculate remaining duration by scheduled end time
    -- only remaining duration can go negative when over produced   
    	      Update @Stats 
    	        Set PredictedTotalDuration = ActualTime + Case 
    	        	        	        	        	        	                                         when EndTime >= @ForecastEndTime Then 
    	        	        	        	        	        	                                           0.0 
    	        	        	        	        	        	                                         Else 
    	        	        	        	        	        	                                           datediff(second,EndTime, @ForecastEndTime) 
    	        	        	        	        	        	                                        End,
    	            PredictedRemainingDuration = datediff(second,EndTime, @ForecastEndTime), 
    	            PredictedRemainingQuantity =  Case  
                                          when EndTime >= @ForecastEndTime Then 
                                            0.0 
                                         when ProdRate = 0 Then 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  ForecastQty - GoodQuantity
                                         Else 
                                            datediff(second,EndTime, @ForecastEndTime) * ProdRate 
                                        End 
  End
Update @Stats Set EndTime = NULL Where PPStatusId = 3
Select 19,1,2,0,@PathId,StatType,Id,StartTime,EndTime,GoodItems,BadItems,RunningMinutes = RunningTime / 60.0,DownMinutes = DownTime / 60.0,GoodQuantity,BadQuantity,PredictedTotalDuration = PredictedTotalDuration / 60.0 ,PredictedRemainingDuration = PredictedRemainingDuration / 60.0,PredictedRemainingQuantity,AlarmCount,LateItems,Repetitions
  From @Stats
  Order By StatId
