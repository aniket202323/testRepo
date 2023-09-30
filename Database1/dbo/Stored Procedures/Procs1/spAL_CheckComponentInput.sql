CREATE PROCEDURE dbo.spAL_CheckComponentInput 
  @EventId int,
  @PEIId int
AS
  Declare @Cnt int
 	 Select @Cnt = Count(event_id) FROM PrdExec_Input_Event_History
       WHERE Event_Id = @EventId and PEI_Id = @PEIId
  If @Cnt <> 0
    Return(0)
Return(1)
