CREATE PROCEDURE dbo.spServer_CmnPutTestValue
@VarId int,
@ResultOn datetime,
@Result nVarChar(30),
@UserId int,
@ArrayId int,
@EventId int,
@TestId bigint OUTPUT,
@EntryOn datetime OUTPUT
AS
Declare
  @RetCode int,
  @PUId int
Execute @RetCode = spServer_DBMgrUpdTest2
  @VarId,
  @UserId,
  0,
  @Result,
  @ResultOn,
  0,
  NULL,
  NULL,
  @EventId,
  @PUId OUTPUT,
  @TestId OUTPUT,
  @EntryOn OUTPUT
If ((@RetCode <> 0) And (@RetCode <> 3))
  Begin
    Select @TestId = NULL
    Select @EntryOn = NULL
    Return
  End
If (@ArrayId <> 0)
  Update Tests Set Array_Id = @ArrayId Where Test_Id = @TestId
