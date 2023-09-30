Create Procedure dbo.spDS_GetTimedReasonInfo
@PUId int,
@EventFaultId int
AS
 Declare @DetailStartTime datetime
Select ER.Level1_Id, ER.Level2_Id, ER.Level3_Id, ER.Level4_Id  from Timed_Event_Fault TE
  Join Event_Reason_Tree_Data ER on ER.Event_Reason_Tree_Data_Id = TE.Event_Reason_Tree_Data_Id
  Where TE.PU_Id = @PUId and TE.TEFault_Id = @EventFaultId
