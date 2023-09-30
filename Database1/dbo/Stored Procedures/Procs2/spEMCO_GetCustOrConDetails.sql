Create Procedure dbo.spEMCO_GetCustOrConDetails
@CustID int,
@UserId int
as
Declare @Insert_Id integer
Select * from Customer
where Customer_Id = @CustID
