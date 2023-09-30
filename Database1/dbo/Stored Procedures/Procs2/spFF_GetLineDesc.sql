Create Procedure dbo.spFF_GetLineDesc
@PL_Id int,
@LineDesc nvarchar(50) OUTPUT
AS
Select @LineDesc = PL_Desc 
  From Prod_Lines 
  Where PL_Id = @PL_Id
If @LineDesc Is Null
  Select @LineDesc = ""
Return(100)
