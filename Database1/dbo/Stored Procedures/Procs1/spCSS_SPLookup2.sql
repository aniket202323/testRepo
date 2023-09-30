CREATE PROCEDURE dbo.spCSS_SPLookup2
@SPName nvarchar(50), 
@CommandText nVarChar(255) OUTPUT, 
@StoredProc bit OUTPUT, 
@Prepared bit OUTPUT, 
@Input int OUTPUT,
@InputOutput int OUTPUT,
@Output int OUTPUT,
@ServerCursor Bit OUTPUT, 
@CursorType smallint OUTPUT, 
@LockType smallint OUTPUT,
@Timeout int OUTPUT, 
@MaxRetries int OUTPUT,
@VerifyType int OUTPUT,
@VerifyTimeout int OUTPUT
AS
Select @StoredProc = NULL, @Prepared = NULL, @CommandText = NULL, @Input = NULL, @InputOutput = NULL, @Output = NULL, @ServerCursor = 0 
Select 
  @CommandText = Command_Text, 
  @StoredProc = Stored_Proc,
  @Prepared = Prepare_SP,
  @Input = Input, 
  @InputOutput = Input_Output,
  @Output = Output, 
  @ServerCursor = Server_Cursor,
  @CursorType = CursorType_Value, 
  @LockType = LockType_Value, 
  @Timeout = Timeout, 
  @MaxRetries = MaxRetries,
  @VerifyType = Coalesce(VerifyType_Id, 0),
  @VerifyTimeout = Coalesce(VerifyTimeoutCount, 0)
    FROM Client_SP_Prototypes p WITH (NOLOCK)
    JOIN Client_SP_CursorTypes ct WITH (NOLOCK) on p.CursorType_Id = ct.CursorType_Id
    JOIN Client_SP_LockTypes lt WITH (NOLOCK) on p.LockType_Id = lt.LockType_Id
    WHERE SP_Name = @SPName
Return(@@ROWCOUNT)
