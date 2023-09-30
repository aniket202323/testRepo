CREATE PROCEDURE dbo.[spEM_FindProductDesc_Bak_177]
  @Prod_Desc      nvarchar(50)
   AS
Declare @Found Int
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Found product Desc.
  --
  Select @Found = Null
  SELECT @Found = Prod_Id FROM Products WHERE Prod_Desc = @Prod_Desc
  If @Found is null
    RETURN(0)
  Else
    Return(1)
