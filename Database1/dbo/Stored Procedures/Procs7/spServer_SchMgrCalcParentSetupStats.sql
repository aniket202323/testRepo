﻿CREATE PROCEDURE dbo.spServer_SchMgrCalcParentSetupStats     
@SetupId int
AS
Declare
  @PPId int,
  @PathId int,
  @ActualStartTime datetime, 	  	 
  @ActualEndTime datetime, 	  	 
  @ActualGoodItems int, 	  	 
  @ActualBadItems int, 	  	 
  @ActualRunningTime decimal(10,4), 	  	 
  @ActualDownTime decimal(10,4), 	  	 
  @ActualGoodQuantity decimal(10,4), 	  	 
  @ActualBadQuantity decimal(10,4), 	  	 
  @PredictedTotalDuration decimal(10,4), 	 
  @PredictedRemainingDuration decimal(10,4), 	 
  @PredictedRemainingQuantity decimal(10,4), 	 
  @Repetitions int,
  @AlarmCount int,
  @LateItems int,
  @@ActualStartTime datetime, 	  	 
  @@ActualEndTime datetime, 	  	 
  @@ActualGoodItems int, 	  	 
  @@ActualBadItems int, 	  	 
  @@ActualRunningTime decimal(10,4), 	  	 
  @@ActualDownTime decimal(10,4), 	  	 
  @@ActualGoodQuantity decimal(10,4), 	  	 
  @@ActualBadQuantity decimal(10,4), 	  	 
  @@PredictedTotalDuration decimal(10,4), 	 
  @@PredictedRemainingDuration decimal(10,4), 	 
  @@PredictedRemainingQuantity decimal(10,4), 	 
  @@Repetitions int,
  @@AlarmCount int,
  @@LateItems int
  Select @ActualStartTime = NULL 	  	 
  Select @ActualEndTime = NULL 	  	 
  Select @ActualGoodItems = 0 	  	 
  Select @ActualBadItems = 0 	  	 
  Select @ActualRunningTime = 0.0 	  	 
  Select @ActualDownTime = 0.0 	  	 
  Select @ActualGoodQuantity = 0.0 	  	 
  Select @ActualBadQuantity = 0.0 	  	 
  Select @PredictedTotalDuration = 0.0 	 
  Select @PredictedRemainingDuration = 0.0 	 
  Select @PredictedRemainingQuantity = 0.0 	 
  Select @AlarmCount = 0
  Select @LateItems = 0
  Select @Repetitions = 0
Select @PPId = NULL
Select @PPId = PP_Id From Production_Setup Where PP_Setup_Id = @SetupId
Select @PathId = NULL
Select @PathId = Path_Id From Production_Plan Where PP_Id = @PPId
Declare ProdPlanSetup_Cursor INSENSITIVE CURSOR 
  For Select Actual_Start_Time,Actual_End_Time,Actual_Good_Items,Actual_Bad_Items,Actual_Running_Time,Actual_Down_Time,Actual_Good_Quantity,Actual_Bad_Quantity,Predicted_Total_Duration,Predicted_Remaining_Duration,Predicted_Remaining_Quantity,Alarm_Count,Late_Items,Actual_Repetitions From Production_Setup Where Parent_PP_Setup_Id = @SetupId
  For Read Only
  Open ProdPlanSetup_Cursor  
ProdPlanSetup_Loop:
  Fetch Next From ProdPlanSetup_Cursor Into @@ActualStartTime,@@ActualEndTime,@@ActualGoodItems,@@ActualBadItems,@@ActualRunningTime,@@ActualDownTime,@@ActualGoodQuantity,@@ActualBadQuantity,@@PredictedTotalDuration,@@PredictedRemainingDuration,@@PredictedRemainingQuantity,@@AlarmCount,@@LateItems,@@Repetitions
  If (@@Fetch_Status = 0)
    Begin
      If (@ActualStartTime Is NULL) Or ((@@ActualStartTime Is Not NULL) And (@@ActualStartTime < @ActualStartTime))
        Select @ActualStartTime = @@ActualStartTime
      If (@ActualEndTime Is NULL) Or ((@@ActualEndTime Is Not NULL) And (@@ActualEndTime > @ActualEndTime))
        Select @ActualEndTime = @@ActualEndTime
      If (@@ActualGoodItems Is Not NULL)
        Select @ActualGoodItems = @ActualGoodItems + coalesce(@@ActualGoodItems,0)
      If (@@ActualBadItems Is Not NULL)
        Select @ActualBadItems = @ActualBadItems + coalesce(@@ActualBadItems,0)
      If (@@ActualRunningTime Is Not NULL)
        Select @ActualRunningTime = @ActualRunningTime + coalesce(@@ActualRunningTime,0)
      If (@@ActualDownTime Is Not NULL)
        Select @ActualDownTime = @ActualDownTime + coalesce(@@ActualDownTime,0)
      If (@@ActualGoodQuantity Is Not NULL)
        Select @ActualGoodQuantity = @ActualGoodQuantity + coalesce(@@ActualGoodQuantity,0)
      If (@@ActualBadQuantity Is Not NULL)
        Select @ActualBadQuantity = @ActualBadQuantity + coalesce(@@ActualBadQuantity,0)
      If (@@PredictedTotalDuration Is Not NULL)
        Select @PredictedTotalDuration = @PredictedTotalDuration + coalesce(@@PredictedTotalDuration,0)
      If (@@PredictedRemainingDuration Is Not NULL)
        Select @PredictedRemainingDuration = @PredictedRemainingDuration + coalesce(@@PredictedRemainingDuration,0)
      If (@@PredictedRemainingQuantity Is Not NULL)
        Select @PredictedRemainingQuantity = @PredictedRemainingQuantity + coalesce(@@PredictedRemainingQuantity,0)
      If (@@AlarmCount Is Not NULL)
        Select @AlarmCount = @AlarmCount + @@AlarmCount
      If (@@LateItems Is Not NULL)
        Select @LateItems = @LateItems + @@LateItems
      If (@@Repetitions Is Not NULL)
        Select @Repetitions = @Repetitions + @@Repetitions
      Goto ProdPlanSetup_Loop
    End
Close ProdPlanSetup_Cursor 
Deallocate ProdPlanSetup_Cursor
Select  	 19,
 	 1,
 	 2,
 	 0,
 	 @PathId,
 	 2,
 	 @SetupId,
 	 @ActualStartTime, 	  	 
 	 @ActualEndTime, 	  	 
 	 @ActualGoodItems, 	  	 
 	 @ActualBadItems, 	  	 
 	 @ActualRunningTime, 	  	 
 	 @ActualDownTime, 	  	 
 	 @ActualGoodQuantity, 	  	 
 	 @ActualBadQuantity, 	  	 
 	 @PredictedTotalDuration, 	 
 	 @PredictedRemainingDuration, 	 
 	 @PredictedRemainingQuantity, 	 
 	 @AlarmCount,
 	 @LateItems,
        @Repetitions
