CREATE PROCEDURE dbo.spServer_CmnGetConsigneeId
@Consignee_Code nVarChar(100),
@Consignee_Name nVarChar(100),
@AddIfMissing int,
@Consignee_Id int OUTPUT,
@UpdateName int = 1
 AS
Select @Consignee_Id = NULL
Select @Consignee_Id = Customer_Id From Customer Where (Customer_Code = @Consignee_Code) And (Customer_Type = 2)
If (@Consignee_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Customer(Customer_Type,Customer_Code,Customer_Name,Is_Active) Values (2,@Consignee_Code,@Consignee_Name,1)
        Select @Consignee_Id = Scope_identity()
      End
    Else
      Select @Consignee_Id = 0
  End
Else
  If (@UpdateName = 1)
    Update Customer Set Customer_Name = @Consignee_Name Where Customer_Id = @Consignee_Id
