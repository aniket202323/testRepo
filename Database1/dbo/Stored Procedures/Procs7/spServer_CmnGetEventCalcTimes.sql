CREATE PROCEDURE dbo.spServer_CmnGetEventCalcTimes
@EventId int,
@EventType int OUTPUT, -- This parm needs to be initialized by caller, it could get changed by this sp
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@PrevEndTime datetime OUTPUT,
@OverallStartTime datetime OUTPUT,
@OverallEndTime datetime OUTPUT,
@PUId int OUTPUT, -- This parm needs to be initialize by caller. It can be initialized to zero
@EventSubType int OUTPUT,
@EventKeys nVarChar(1000) OUTPUT,
@Found int OUTPUT,
@IsNoHistoryStatus int = null OUTPUT
AS
Declare
 	 @TmpI1 int,
 	 @TmpI2 int,
 	 @TmpI3 int,
 	 @TmpI4 int,
 	 @TmpI5 int,
 	 @TmpI6 int,
 	 @TmpI7 int,
 	 @TmpI8 int,
 	 @TmpI9 int,
 	 @TmpVC1 nvarchar(200),
 	 @TmpR1 real,
 	 @TmpR2 real,
 	 @TmpR3 real,
 	 @PrevStartTime datetime,
 	 @MasterUnit int,
 	 @ErrorMsg nvarchar(200),
 	 @ExpectedPUId int
Select @ExpectedPUId 	  	  	  = @PUId
Select @Found 	  	  	  	  	  	  	  = 0 
Select @StartTime 	  	  	  	  	  = NULL
Select @EndTime 	  	  	  	  	  	  = NULL
Select @PrevEndTime 	  	  	  	  = NULL
Select @OverallStartTime 	  = NULL
Select @OverallEndTime 	  	  = NULL
Select @PUId 	  	  	  	  	  	  	  = NULL
Select @EventSubType 	  	  	  = NULL
Select @EventKeys 	  	  	  	  	  = NULL
Select @IsNoHistoryStatus 	  = NULL
 	 
-- Production Event / Production Event ByTime
If (@EventType = 1) Or (@EventType = 26)
 	 Begin
 	  	 Execute spServer_CmnGetEventInfo @EventId,0,@PUId OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@TmpI1 OUTPUT,@TmpI1 OUTPUT,@TmpVC1 OUTPUT,@TmpI1 OUTPUT,@TmpI1 OUTPUT,@TmpI1 OUTPUT,@Found OUTPUT,@IsNoHistoryStatus OUTPUT
 	  	 If (@Found = 1)
 	  	  	 Begin
 	  	  	  	 If (@ExpectedPUId Is Not NULL) And (@ExpectedPUId <> 0) And (@ExpectedPUId <> @PUId)
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @Found = 0
 	  	  	  	  	  	 Select @StartTime = NULL
 	  	  	  	  	  	 Select @EndTime = NULL
 	  	  	  	  	  	 Select @StartTime = Start_Time, @EndTime = End_Time From Event_PU_Transitions Where (Event_Id = @EventId) And (PU_Id = @ExpectedPUId)
 	  	  	  	  	  	 If (@EndTime Is Not NULL)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Select @Found = 1
 	  	  	  	  	  	  	  	 Select @PUId = @ExpectedPUId
 	  	  	  	  	  	  	  	 If (@StartTime Is NULL)
 	  	  	  	  	  	  	  	  	 Select @StartTime = Max(End_Time) From Event_PU_Transitions Where (PU_Id = @ExpectedPUId) And (End_Time < @EndTime)
 	  	  	  	  	  	  	  	 If (@StartTime Is NULL)
 	  	  	  	  	  	  	  	  	 Select @StartTime = @EndTime
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 If (@Found = 1)
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	  	  	 End
 	  	  	 End
 	 End
 	 
-- ProductChange / ProductChange ByTime
Else If (@EventType = 4) Or (@EventType = 5)
 	 Begin
 	  	 Execute spServer_CmnGetProdStartInfo @EventId,@PUId OUTPUT,@TmpI1 OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@TmpI1 OUTPUT,@Found OUTPUT
 	  	 If (@Found = 1)
 	  	  	 Begin
 	  	  	  	 If (@EndTime Is NULL)
 	  	  	  	  	 Select @EndTime = @StartTime
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
 	 
-- Waste
Else If (@EventType = 3)
 	 Begin
 	  	 Execute spServer_CmnGetWEInfo @EventId,@PUId OUTPUT,@TmpI1 OUTPUT,@TmpI2 OUTPUT,@TmpI3 OUTPUT,@TmpR1 OUTPUT,@TmpI4 OUTPUT,@TmpI5 OUTPUT,@TmpI6 OUTPUT,@TmpI7 OUTPUT,@TmpI8 OUTPUT,@TmpR2 OUTPUT,@TmpR3 OUTPUT,@TmpI9 OUTPUT,@EndTime OUTPUT,@MasterUnit OUTPUT,@StartTime OUTPUT
 	  	 If ((@PUId Is Not NULL) And (@PUId <> 0)) And ((@MasterUnit Is NULL) Or (@MasterUnit = 0))
 	  	  	 Begin
 	  	  	  	 Select @Found = 1
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
 	 
-- User Defined
Else If (@EventType = 14)
 	 Begin
 	  	  Execute spServer_CmnGetUDEInfo @EventId,@PUId OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@EventSubType OUTPUT
 	  	 If (@PUId Is Not NULL) And (@PUId <> 0)
 	  	  	 Begin
 	  	  	  	 Select @Found = 1
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
-- Segment Response
Else If (@EventType = 31)
 	 Begin
 	  	 Execute spServer_CmnGetSegmentResponseInfo @EventId,@Found OUTPUT,@PUId OUTPUT,@EventKeys OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@ErrorMsg OUTPUT
 	  	 If (@Found = 1)
 	  	  	 Begin
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
-- Work Response
Else If (@EventType = 32)
 	 Begin
 	  	 Execute spServer_CmnGetWorkResponseInfo @EventId,@Found OUTPUT,@PUId OUTPUT,@EventKeys OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@ErrorMsg OUTPUT
 	  	 If (@Found = 1)
 	  	  	 Begin
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
-- Input Genealogy
Else If (@EventType = 17)
 	 Begin
 	  	 -- We are intentionally returning the Event PEI_Id as the subtype.  For Input Genealogy events we group the variables by PEI_Id.  We also do this in the load Vars. (Marty, 8/28/12)
 	  	 Execute spServer_CmnGetInputGenealogyInfo @EventId,@PUId OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@EventSubType OUTPUT
 	  	 If (@PUId Is Not NULL) And (@PUId <> 0)
 	  	  	 Begin
 	  	  	  	 Select @Found = 1
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
 	 
-- Uptime
Else If (@EventType = 22)
 	 Begin
 	  	 Execute spServer_CmnGetTEInfo @EventId,@PUId OUTPUT,@TmpR1 OUTPUT,@TmpI1 OUTPUT,@TmpI2 OUTPUT,@TmpI3 OUTPUT,@TmpI4 OUTPUT,@TmpI5 OUTPUT,@TmpR2 OUTPUT,@TmpI6 OUTPUT,@TmpI7 OUTPUT,@TmpI8 OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@MasterUnit OUTPUT,@PrevStartTime OUTPUT,@PrevEndTime OUTPUT
 	  	 If (@StartTime Is Not NULL)
 	  	  	 Begin
 	  	  	  	 If (@EndTime is NULL)
 	  	  	  	  	 Select @Endtime = @StartTime
 	  	  	  	 If (@PrevStartTime is NULL)
 	  	  	  	  	 Select @PrevStartTime = @StartTime
 	  	  	  	 If (@PrevEndTime is NULL)
 	  	  	  	  	 Select @PrevEndTime = @StartTime 	  	  	 
 	  	  	  	 If ((@MasterUnit Is NULL) Or (@MasterUnit = 0)) And (@PrevEndTime Is Not NULL) And (@PrevEndTime < @StartTime)
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @Found = 1
 	  	  	  	  	  	 Select @EndTime = @StartTime
 	  	  	  	  	  	 Select @StartTime = @PrevEndTime
 	  	  	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	  	  	 End 	 
 	  	  	 End
 	 End
 	 
-- Downtime
Else If (@EventType = 2)
 	 Begin
 	  	 Execute spServer_CmnGetTEInfo @EventId,@PUId OUTPUT,@TmpR1 OUTPUT,@TmpI1 OUTPUT,@TmpI2 OUTPUT,@TmpI3 OUTPUT,@TmpI4 OUTPUT,@TmpI5 OUTPUT,@TmpR2 OUTPUT,@TmpI6 OUTPUT,@TmpI7 OUTPUT,@TmpI8 OUTPUT,@StartTime OUTPUT,@EndTime OUTPUT,@MasterUnit OUTPUT,@PrevStartTime OUTPUT,@PrevEndTime OUTPUT
 	  	 If (@StartTime Is Not NULL) And ((@MasterUnit Is NULL) Or (@MasterUnit = 0))
 	  	  	 Begin
 	  	  	  	 If (@EndTime is NULL)
 	  	  	  	  	 Select @Endtime = @StartTime
 	  	  	  	 If (@PrevStartTime is NULL)
 	  	  	  	  	 Select @PrevStartTime = @StartTime
 	  	  	  	 If (@PrevEndTime is NULL)
 	  	  	  	  	 Select @PrevEndTime = @StartTime
 	  	  	  	 If (@PrevEndTime = @StartTime)
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@StartTime <> @EndTime)
 	  	  	  	  	  	  	 Select @Found = 1
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@StartTime = @EndTime)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Select @EventType = 22 -- Uptime
 	  	  	  	  	  	  	  	 Select @EndTime = @StartTime
 	  	  	  	  	  	  	  	 Select @StartTime = @PrevEndTime
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Select @EventType = -1 -- Downtime And Uptime
 	  	  	  	  	  	 Select @Found = 1
 	  	  	  	  	 End
 	  	  	  	 Select @OverallStartTime = @StartTime
 	  	  	  	 Select @OverallEndTime = @EndTime
 	  	  	 End 	 
 	 End
-- Process Order / Process Order ByTime
Else If (@EventType = 19) Or (@EventType = 28)
 	 Begin
 	  	 Select @Found = 0
 	  	 -- Process Order / Process Order ByTime (19,28)
 	  	 -- This function does not support the above Event Type. Call the specific sp for this event type !
 	 End
 	 
