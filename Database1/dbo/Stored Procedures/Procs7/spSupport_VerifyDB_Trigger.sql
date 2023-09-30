create procedure dbo.spSupport_VerifyDB_Trigger
@Triggername varchar(100)
AS
Declare
  @TriggerId int,
  @Msg varchar(255)
Select @TriggerId = NULL
SELECT @Triggername = 'dbo.' + @Triggername
Select @TriggerId = object_id(@Triggername)
If (@TriggerId Is NULL)
  Begin
    Select @Msg = '-- Warning: Missing Trigger [' + @Triggername + ']'
    Print @Msg
    Return
  End
