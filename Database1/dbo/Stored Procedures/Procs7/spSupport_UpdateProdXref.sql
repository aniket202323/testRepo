CREATE PROCEDURE dbo.spSupport_UpdateProdXref
@Prod_Code Varchar(50),
@Prod_Code_XRef Varchar(50)
AS
Set NoCount On
Declare
  @Prod_Id int,
  @ErrorMsg Varchar(100)
Select @Prod_Id = Prod_Id From Products Where Prod_Code = @Prod_Code
If @Prod_Id Is Null
  Begin
    Select @ErrorMsg = 'Error: Prod Code Not Found [' + @Prod_Code + ']'
    Print @ErrorMsg
    Set NoCount Off
    Return
  End
Update Prod_XRef Set Prod_Code_XRef = @Prod_Code_XRef Where Prod_Id = @Prod_Id
Set NoCount Off
