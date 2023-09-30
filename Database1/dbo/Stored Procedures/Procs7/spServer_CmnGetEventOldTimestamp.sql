CREATE PROCEDURE dbo.spServer_CmnGetEventOldTimestamp
@EventId int,
@OldTimestamp datetime OUTPUT
AS
Declare
  @CurrentTimestamp datetime,
  @@Timestamp datetime
Select @OldTimestamp = NULL
Select @CurrentTimestamp = NULL
Select @CurrentTimestamp = Timestamp From Events Where Event_Id = @EventId
If (@CurrentTimestamp Is NULL)
  Return
Declare History_Cursor INSENSITIVE CURSOR
  For Select Timestamp From Event_History Where (Event_Id = @EventId) Order By Entry_On Desc
  For Read Only
  Open History_Cursor  
Fetch_Loop:
  Fetch Next From History_Cursor Into @@Timestamp
  If (@@Fetch_Status = 0)
    Begin
      If (@@Timestamp <> @CurrentTimestamp)
        Select @OldTimestamp = @@Timestamp
      Else
        Goto Fetch_Loop
    End
Close History_Cursor 
Deallocate History_Cursor
