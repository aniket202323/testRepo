Create Procedure dbo.[spServer_CmnAddScheduledTask_Bak_177]
@ActualId int,
@TableId int,
@PUId int = NULL,
@ActualTime Datetime = NULL,
@NewEventStatus int = NULL,
@TimeChanged int = NULL,
@OldEventStatus int = NULL,
@EventType 	 Int = Null,
@OldTime Datetime = NULL,
@AppliedProductChanged Int = Null
AS
-- ****************************************
--  Table Id's
--
--  1 Events
--  2 Production_Starts
--  3 Timed_Event_Details
--  4 Waste_Event_Details
--  5 PrdExec_Input_Event
--  6 PrdExec_Input_Event_History
--  7 Production_Plan
--  8 Production_Setup
--  9 Production_Setup_Detail
-- 10 Event_Components
-- 11 User_Defined_Events
-- 12 Production_Plan_Starts
-- 13 PrdExec_Paths
-- 14 Event_Details
-- 15 PrdExec_Input_Event_Transitions
-- 16 PrdExec_Output_Event_Transitions
-- ****************************************
Declare
  @@TaskId int,
  @Found int,
  @AddScheduledTask int,
  @AddAppliedProductTask int,
  @ETId 	 Int,
  @Misc nVarChar(100),
  @IsNoHistoryChange int
 	 Set @Misc = null
 	 Set @IsNoHistoryChange = 0
 	 
 	 SET @AppliedProductChanged = coalesce(@AppliedProductChanged,0)
 	 --select '@AppliedProductChanged',@AppliedProductChanged
If (@ActualTime Is NULL) Or (@PUId Is NULL)
  BEGIN
    If (@TableId = 1)
      BEGIN
        Select @ActualTime = TimeStamp, @PUId = PU_Id From Events WITH (NOLOCK) WHERE Event_Id = @ActualId
        If (@ActualTime Is NULL) Or (@PUId Is NULL)
          Return
      END
    If (@TableId = 2)
      BEGIN
        Select @ActualTime = Start_Time, @PUId = PU_Id From Production_Starts WITH (NOLOCK) WHERE Start_Id = @ActualId
        If (@ActualTime Is NULL) Or (@PUId Is NULL)
          Return
      END
    If (@TableId = 3)
      BEGIN
        Select @ActualTime = Start_Time, @PUId = PU_Id From Timed_Event_Details WITH (NOLOCK) WHERE TEDet_Id = @ActualId
        If (@ActualTime Is NULL) Or (@PUId Is NULL)
          Return
      END
    If (@TableId = 4)
      BEGIN
        Select @ActualTime = Timestamp, @PUId = PU_Id From Waste_Event_Details WITH (NOLOCK) WHERE WED_Id = @ActualId
        If (@ActualTime Is NULL) Or (@PUId Is NULL)
          Return
      END
    If (@TableId = 11)
      BEGIN
        Select @ActualTime = END_Time, @PUId = PU_Id From User_Defined_Events WITH (NOLOCK) WHERE UDE_Id = @ActualId
        If (@ActualTime Is NULL) Or (@PUId Is NULL)
          Return
      END
  END
Declare @NoOfMonths Int
Select @NoOfMonths = Value from Site_Parameters Where Parm_id = 611
SET @NoOfMonths = ISNULL(@NoOfMonths,6)
--N months older events can be triggered. Default value of N is 6
If (@TableId = 1)
  If (DateDiff(Month,@ActualTime,dbo.fnServer_CmnGetDate(GetUTCDate())) > @NoOfMonths)
    Return
Declare Task_Cursor INSENSITIVE CURSOR
  For Select TaskId,Et_Id From Tasks WITH (NOLOCK) WHERE (TableId = @TableId) And IsActive = 1
  For Read Only
  Open Task_Cursor  
Task_Loop:
  Fetch Next From Task_Cursor Into @@TaskId,@ETId
  If (@@Fetch_Status = 0)
  BEGIN
    Select @AddScheduledTask = 1
 	 SET @AddAppliedProductTask = 0
    If (@TableId = 1) And ((@@TaskId = 1) Or (@@TaskId = 9) Or (@@TaskId = 24) or (@@TaskId = 44))
    BEGIN 
      If (@NewEventStatus Is Not NULL) And (@NewEventStatus < 5)
        Select @AddScheduledTask = 0
      Else
        If (@TimeChanged Is Not NULL) And (@TimeChanged = 0)
          Select @AddScheduledTask = 0
      If (@NewEventStatus Is Not NULL) And (@OldEventStatus Is Not NULL)
      BEGIN
        If @NewEventStatus >= 5 and @OldEventStatus < 5
          Select @AddScheduledTask = 1
      END
      IF (@@TaskId = 44)
      BEGIN
        Select @AddScheduledTask = @AppliedProductChanged
        -- If EventType (Used for prev prod ID) is null, then get the original prod from production_starts
        if (@EventType is null)
        Begin
            Select @EventType = Prod_Id from Production_Starts where PU_Id = @PUId and Start_Time < @ActualTime and (End_Time >= @ActualTime or End_Time is null)
        End
        if (@EventType is not null)
            Select @Misc = CONVERT(nVarChar(100), @EventType)
      END
      IF ((@@TaskId = 1) AND (@AddScheduledTask = 0)) -- SummaryMgr Collect Data
      BEGIN
        If (@NewEventStatus Is Not NULL) And (@OldEventStatus Is Not NULL) And (@OldEventStatus <> @NewEventStatus)
        BEGIN
          Select @IsNoHistoryChange = Case When os.NoHistory <> ns.NoHistory Then 1 Else 0 End
            from Production_Status os
            join Production_Status ns on ns.ProdStatus_Id = @NewEventStatus
            where os.ProdStatus_Id = @OldEventStatus
        END
        IF (@IsNoHistoryChange = 1)
          Select @AddScheduledTask = 1
      END
    END
    If (@TableId = 10) And (@@TaskId = 29)
    BEGIN 
      If (@TimeChanged Is Not NULL) And (@TimeChanged = 0)
        Select @AddScheduledTask = 0
    END
    If (@TableId = 55) and (@EventType <> @ETId)
    BEGIN 
      Select @AddScheduledTask = 0
    END 
    If (@AddScheduledTask = 1) 
    BEGIN
      Select @Found = NULL
      If (@Misc Is Not Null) and (@PUId Is Not Null)
        Select @Found = ActualId From PendingTasks WITH (NOLOCK) WHERE (ActualId = @ActualId) And (TaskId = @@TaskId) And (WorkStarted = 0) and (PU_Id = @PUId) and (Misc = @Misc)
      If (@OldTime Is Not Null) and (@PUId Is Not Null)
        Select @Found = ActualId From PendingTasks WITH (NOLOCK) WHERE (ActualId = @ActualId) And (TaskId = @@TaskId) And (WorkStarted = 0) and (PU_Id = @PUId) and (OldTimestamp = @OldTime)
      Else If (@OldTime Is Not Null)
        Select @Found = ActualId From PendingTasks WITH (NOLOCK) WHERE (ActualId = @ActualId) And (TaskId = @@TaskId) And (WorkStarted = 0) and (OldTimestamp = @OldTime)
      Else If (@PUId Is Not Null)
        Select @Found = ActualId From PendingTasks WITH (NOLOCK) WHERE (ActualId = @ActualId) And (TaskId = @@TaskId) And (WorkStarted = 0) and (PU_Id = @PUId)
      Else
        Select @Found = ActualId From PendingTasks WITH (NOLOCK) WHERE (ActualId = @ActualId) And (TaskId = @@TaskId) And (WorkStarted = 0)
      If (@Found Is NULL)    
        Insert Into PendingTasks (ActualId,TaskId,PU_Id,Timestamp,OldTimestamp,Misc) Values (@ActualId,@@TaskId,@PUId,@ActualTime,@OldTime,@Misc)
    END
    Goto Task_Loop
  END
Close Task_Cursor 
Deallocate Task_Cursor
