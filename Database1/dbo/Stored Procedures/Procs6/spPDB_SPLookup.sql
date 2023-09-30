/********************************************************************
** <summar>Looks up information about a procedure alias.<summary>
********************************************************************/
CREATE PROCEDURE dbo.spPDB_SPLookup
@SPName nVarchar(50), /** The alias name of the procedure to lookup. */
@CommandText nvarchar(255) OUTPUT, /** The stored procedure name or the command text to be executed. */
@StoredProc bit OUTPUT, /** Is <paramref name='CommandText'> a stored procedure or command text. */
@Prepared bit OUTPUT, /** ignored */
@Input int OUTPUT, /** The first X parameters are input parameters. */
@InputOutput int OUTPUT, /** The next Y parameters are input/output parameters. */
@Output int OUTPUT, /** The last Z parameters are output-only parameters. */ 
@ServerCursor Bit OUTPUT, /** ignored */
@CursorType smallint OUTPUT,  /** ignored */
@LockType smallint OUTPUT, /** ignored */
@Timeout int OUTPUT, /** The maximum number of seconds to wait for the command to complete. */
@MaxRetries int OUTPUT, /** If the command times out, retry it this many more times. */
@VerifyType int OUTPUT, /** ignored */
@VerifyTimeout int OUTPUT, /** ignored */
@IsClientCallable bit OUTPUT /** Can this procedure alias be called by clients. */
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
  @VerifyTimeout = Coalesce(VerifyTimeoutCount, 0),
  @IsClientCallable = Is_Client_Callable
    FROM Client_SP_Prototypes p
    JOIN Client_SP_CursorTypes ct on p.CursorType_Id = ct.CursorType_Id
    JOIN Client_SP_LockTypes lt on p.LockType_Id = lt.LockType_Id
    WHERE SP_Name = @SPName
Return(@@ROWCOUNT)
