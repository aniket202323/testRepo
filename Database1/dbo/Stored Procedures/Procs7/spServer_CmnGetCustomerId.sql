CREATE PROCEDURE dbo.spServer_CmnGetCustomerId
@Customer_Code nVarChar(100),
@Customer_Name nVarChar(100),
@AddIfMissing int,
@Customer_Id int OUTPUT,
@UpdateName int = 1
 AS
Select @Customer_Id = NULL
Select @Customer_Id = Customer_Id From Customer Where (Customer_Code = @Customer_Code) And (Customer_Type = 1)
If (@Customer_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Customer(Customer_Type,Customer_Code,Customer_Name,Is_Active) Values (1,@Customer_Code,@Customer_Name,1)
        Select @Customer_Id = Scope_identity()
      End
    Else
      Select @Customer_Id = 0
  End
Else
  If (@UpdateName = 1)
    Update Customer Set Customer_Name = @Customer_Name Where Customer_Id = @Customer_Id
