CREATE PROCEDURE dbo.spEM_FindProductCode
  @Prod_Code      nvarchar(25)
   AS
Declare @Found Int
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Found product Desc.
  --
  Select @Found = Null
  SELECT @Found = Prod_Id FROM Products WHERE Prod_Code = @Prod_Code
  If @Found is null
    RETURN(0)
  Else
    Return(1)
