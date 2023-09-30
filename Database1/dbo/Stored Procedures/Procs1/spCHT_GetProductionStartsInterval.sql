/**********************************************/
/****** Called from ProfRVW also **************/
/**********************************************/
Create Procedure dbo.spCHT_GetProductionStartsInterval
@PUId int,
@StartTime datetime
As
Declare
 @PreviousStartTime as datetime,
 @NextEndTime as datetime,
 @NextStartTime as datetime
 Select @PreviousStartTime  = @StartTime
 Select @NextSTartTime = Min(Start_Time) 
  From Production_Starts
   Where PU_Id = @PUId 
    And Start_Time > @StartTime
 Select @NextEndTime = End_Time
  From Production_Starts
   Where PU_Id = @PUId
    And Start_Time = @NextStartTime
 Select @PreviousStartTime = Max(Start_Time)
  From Production_Starts
   Where PU_Id = @PUId
    And Start_Time < @StartTime
 Select @PreviousStartTime as PreviousStartTime, 
        @NextEndTime as NextEndTime
