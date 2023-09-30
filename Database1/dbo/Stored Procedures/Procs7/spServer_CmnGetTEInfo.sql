CREATE PROCEDURE dbo.spServer_CmnGetTEInfo
@TEDet_Id int,
@PU_Id int OUTPUT,
@Duration real OUTPUT,
@Source_PU_Id int OUTPUT,
@Reason_Level1 int OUTPUT,
@Reason_Level2 int OUTPUT,
@Reason_Level3 int OUTPUT,
@Reason_Level4 int OUTPUT,
@Production_Rate real OUTPUT,
@TEStatus_Id int OUTPUT,
@TEFault_Id int OUTPUT,
@User_Id int OUTPUT,
@StartTime datetime OUTPUT,
@Endtime datetime OUTPUT,
@MasterUnit int OUTPUT,
@PrevStartTime datetime OUTPUT,
@PrevEndTime datetime OUTPUT
AS
Select @PrevStartTime = NULL
Select @PrevEndTime = NULL
Select @StartTime = NULL
Select @EndTime = NULL
Select @MasterUnit = NULL
Select @StartTime = Start_Time,
       @EndTime = End_Time,
       @PU_Id = PU_Id,
       @Duration = COALESCE(Duration,0),
       @Source_PU_Id = COALESCE(Source_PU_Id,0),
       @Reason_Level1 = COALESCE(Reason_Level1,0),
       @Reason_Level2 = COALESCE(Reason_Level2,0),
       @Reason_Level3 = COALESCE(Reason_Level3,0),
       @Reason_Level4 = COALESCE(Reason_Level4,0),
       @TEStatus_Id = COALESCE(TEStatus_Id,0),
       @TEFault_Id = COALESCE(TEFault_Id,0),
       @User_Id = COALESCE(User_Id,0)
  From Timed_Event_Details
  Where (TEDet_Id = @TEDet_Id)
If (@StartTime Is NULL)
  Return
Select @MasterUnit = Master_Unit From Prod_Units_Base Where (PU_Id = @PU_Id)
Select @PrevStartTime = Max(Start_Time) From Timed_Event_Details Where (PU_Id = @PU_Id) And (Start_Time < @StartTime)
If (@PrevStartTime Is Not NULL)
  Select @PrevEndTime = End_Time From Timed_Event_Details Where (PU_Id = @PU_Id) And (Start_Time = @PrevStartTime)
