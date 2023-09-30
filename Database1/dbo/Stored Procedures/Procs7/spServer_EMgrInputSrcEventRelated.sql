CREATE PROCEDURE dbo.spServer_EMgrInputSrcEventRelated
@Src_Event_Id int,
@PEI_Id int,
@Related int OUTPUT
AS
Select @Related = NULL
Select @Related = Event_Id
  From PrdExec_Input_Event
  Where (PEI_Id = @PEI_Id) And
        (Event_Id = @Src_Event_Id)
If (@Related Is Not NULL)
  Begin
    Select @Related = 1
    Return
  End
Select @Related = Event_Id
  From PrdExec_Input_Event_History
  Where (PEI_Id = @PEI_Id) And
        (Event_Id = @Src_Event_Id)
If (@Related Is Not NULL)
  Select @Related = 1
Else
  Select @Related = 0
