CREATE PROCEDURE dbo.spEM_GetTransactionInfo
  @ServerDesc nvarchar(25),
  @Trans_Id int,
  @Effective_Date DateTime_ComX OUTPUT,
  @Trans_Create_Date DateTime_ComX OUTPUT,
  @TransExists bit OUTPUT,
  @T  int OUTPUT
  AS
  --
  --
  --
  --
  -- Get transaction approval data.
  --
  SELECT @T = Trans_Id,@Effective_Date = Effective_Date,@Trans_Create_Date = Trans_Create_Date
    FROM Transactions
    WHERE Corp_Trans_Id = @Trans_Id and Corp_Trans_Desc = @ServerDesc
IF @T is null Select @TransExists  = 0 else Select @TransExists  = 1
