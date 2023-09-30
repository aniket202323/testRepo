Create Procedure dbo.spWD_GetPreviousEndTime
@PU_Id int,
@SummaryStartTime datetime,
@PreviousEndTime datetime OUTPUT
AS
select @PreviousEndTime = Max(End_Time)
  From Timed_Event_Details WITH (NOLOCK)
  Where PU_Id = @PU_Id
  And End_Time < @SummaryStartTime
