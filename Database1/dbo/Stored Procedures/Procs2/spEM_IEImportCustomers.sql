CREATE PROCEDURE dbo.spEM_IEImportCustomers
@CustName  	  	  	 nVarChar(100),
@CustCode  	  	  	 nvarchar(50),
@CustomerType 	  	 nVarChar(100),
@Address1 	  	  	 nvarchar(255),
@Address2 	  	  	 nvarchar(255),
@Address3 	  	  	 nvarchar(255),
@Address4 	  	  	 nvarchar(255),
@City 	  	  	  	 nvarchar(50),
@State 	  	  	  	 nvarchar(50),
@ZipCode 	  	  	 nvarchar(25),
@Country 	  	  	 nvarchar(50),
@ContactName 	  	 nVarChar(100),
@ContactPhone 	  	 nvarchar(50),
@ExtInfo 	  	  	 nvarchar(255),
@General1 	  	  	 nvarchar(25),
@General2 	  	  	 nvarchar(25),
@General3 	  	  	 nvarchar(25),
@General4 	  	  	 nvarchar(25),
@General5 	  	  	 nvarchar(25),
@Active 	  	  	  	 nVarChar(10),
@In_User_Id  	  	 int
As
Select @CustName 	  	 = Ltrim(Rtrim(@CustName))
Select @CustCode 	  	 = Ltrim(Rtrim(@CustCode))
Select @CustomerType 	 = Ltrim(Rtrim(@CustomerType))
Select @Address1 	  	 = Ltrim(Rtrim(@Address1))
Select @Address2 	  	 = Ltrim(Rtrim(@Address2))
Select @Address3 	  	 = Ltrim(Rtrim(@Address3))
Select @Address4 	  	 = Ltrim(Rtrim(@Address4))
Select @City 	  	  	 = Ltrim(Rtrim(@City))
Select @State 	  	  	 = Ltrim(Rtrim(@State))
Select @ZipCode 	  	  	 = Ltrim(Rtrim(@ZipCode))
Select @Country 	  	  	 = Ltrim(Rtrim(@Country))
Select @ContactName 	  	 = Ltrim(Rtrim(@ContactName))
Select @ContactPhone  	 = Ltrim(Rtrim(@ContactPhone))
Select @General1 	  	 = Ltrim(Rtrim(@General1))
Select @General2 	  	 = Ltrim(Rtrim(@General2))
Select @General3 	  	 = Ltrim(Rtrim(@General3))
Select @General4 	  	 = Ltrim(Rtrim(@General4))
Select @General5 	  	 = Ltrim(Rtrim(@General5))
Select @ExtInfo 	  	  	 = Ltrim(Rtrim(@ExtInfo))
Select @Active 	  	  	 = Ltrim(Rtrim(@Active))
Declare @IsActive 	  	 bit,
 	  	 @CustomerId  	 int,
 	  	 @CustomerTypeId 	 Int
If @CustCode = '' or @CustCode is null 
  Begin
 	 Select  'Customer Code Not Found'
 	 Return(-100)
  End
If @CustomerType = '' or @CustomerType is null 
  Begin
 	 Select  'Customer Type Not Found'
 	 Return(-100)
  End
If @Active = 'Yes' or @Active = 'TRUE' Or @Active = '1'
 	 Select  @IsActive = 1
Else
 	 Select  @IsActive = 0
If @CustName = '' Select @CustName = Null
If @Address1 = '' Select @Address1 = Null
If @Address2 = '' Select @Address2 = Null
If @Address3 = '' Select @Address3 = Null
If @Address4 = '' Select @Address4 = Null
If @City = '' Select @City = Null
If @State = '' Select @State = Null
If @ZipCode = '' Select @ZipCode = Null
If @Country = '' Select @Country = Null
If @ContactName = '' Select @ContactName = Null
If @ContactPhone = '' Select @ContactPhone = Null
If @General1 = '' Select @General1 = Null
If @General2 = '' Select @General2 = Null
If @General3 = '' Select @General3 = Null
If @General4 = '' Select @General4 = Null
If @General5 = '' Select @General5 = Null
If @ExtInfo = '' Select @ExtInfo = Null
/* Initialization */
Select @CustomerId = Null
Select @CustomerTypeId = Null
/* Get Customer Id */
Select @CustomerId = Customer_Id
From Customer
Where Customer_Code = @CustCode
/* Check Type */
Select @CustomerTypeId = Customer_Type_Id From Customer_Types Where Customer_Type_Desc = @CustomerType
If @CustomerTypeId is null 
  Begin
 	 Select  'Customer Type Not Correct'
 	 Return(-100)
  End
/* If doesn't exist then create */
If @CustomerId Is Null
 	 Execute spEMCU_AddCustomer @CustCode,@CustName,Null,null,@Address1,@Address2,@ContactName,@ContactPhone,@IsActive,@General1,
 	  	 @General2,@General3,@General4,@General5,@CustomerTypeId,@Address3,@Address4,@City,null,@State,@Country,@ZipCode,@In_User_Id,@CustomerId  OUTPUT
Else
 	 Execute spEMCU_EditCustomer @CustomerId,@CustCode,@CustName,Null,null,@Address1,@Address2,@ContactName,@ContactPhone,@IsActive,
 	  	 @General1,@General2,@General3,@General4,@General5,@CustomerTypeId,@Address3,@Address4,@City,null,@State,@Country,@ZipCode,@In_User_Id
If @CustomerId is null
  Begin
 	 Select 'Failed - could not create customer'
 	 Return (-100)
  End
Return(0)
