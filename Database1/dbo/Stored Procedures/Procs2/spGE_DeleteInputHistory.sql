Create Procedure dbo.spGE_DeleteInputHistory
@InputHistoryId 	 int
 AS
Declare @NextTs  	 DateTime,
 	 @PEI_Id 	  	 Int,
 	 @OldTs 	  	 DateTime,
 	 @Now 	  	 DateTime,
 	 @NextHistId 	 Int,
 	 @Event_Id 	 Int
/* also need to remove completion of this event*/
select @Now = dbo.fnServer_CmnGetDate(GetUTCDate())
Select @Event_Id = Null
Select @PEI_Id = PEI_Id,@OldTs = TimeStamp 
  From Prdexec_Input_Event_History where Input_Event_History_Id = @InputHistoryId
Select @NextTs = Min(Timestamp)
 	 From  Prdexec_Input_Event_History
 	 Where PEI_Id = @PEI_Id and PEIP_Id = 1 and Unloaded = 0 and TimeStamp > @OldTs and TimeStamp < @Now
If @NextTs is not null
  Begin
    Select @Event_Id = Event_Id, @NextHistId = Input_Event_History_Id
 	 From  Prdexec_Input_Event_History
 	 Where PEI_Id = @PEI_Id and PEIP_Id = 1 and Unloaded = 0 and TimeStamp = @NextTs
    If @Event_Id Is Null 
      Delete from Prdexec_Input_Event_History where Input_Event_History_Id = @NextHistId
  End
Update Prdexec_Input_Event_History set Unloaded = 4 Where Input_Event_History_Id = @InputHistoryId
