CREATE PROCEDURE dbo.spEM_UniqueTransaction
  @Trans_Desc      nvarchar(50),
  @Is_Unique       int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Transaction name exists
  --
IF (Select count(*) from Transactions WHERE Trans_Desc = @Trans_Desc) = 0 
  SELECT @Is_Unique = 0
ELSE 
  SELECT @Is_Unique = 1
