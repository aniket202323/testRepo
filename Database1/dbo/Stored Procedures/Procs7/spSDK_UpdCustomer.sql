CREATE PROCEDURE dbo.spSDK_UpdCustomer
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @CustomerCode 	  	  	 nvarchar(50),
 	 @CustomerName 	  	  	 nvarchar(100),
 	 @CustomerType 	  	  	 nvarchar(50),
 	 @ConsigneeCode 	  	  	 nvarchar(50),
 	 @ConsigneeName 	  	  	 nvarchar(100),
 	 @ContactName 	  	  	 nvarchar(100),
 	 @ContactPhone 	  	  	 nvarchar(50),
 	 @Address1 	  	  	  	 nvarchar(255),
 	 @Address2 	  	  	  	 nvarchar(255),
 	 @Address3 	  	  	  	 nvarchar(255),
 	 @Address4 	  	  	  	 nvarchar(255),
 	 @City 	  	  	  	  	  	 nvarchar(50),
 	 @County 	  	  	  	  	 nvarchar(50),
 	 @State 	  	  	  	  	 nvarchar(50),
 	 @Country 	  	  	  	  	 nvarchar(50),
 	 @ZIP 	  	  	  	  	  	 nvarchar(50),
 	 @CustomerGeneral1 	  	 nvarchar(50),
 	 @CustomerGeneral2 	  	 nvarchar(50),
 	 @CustomerGeneral3 	  	 nvarchar(50),
 	 @CustomerGeneral4 	  	 nvarchar(50),
 	 @CustomerGeneral5 	  	 nvarchar(50),
 	 @IsActive 	  	  	  	 BIT,
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @CustomerId 	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: CustomerId Not Specified on Update/Delete
-- 	  	  2: CustomerType Not Found
DECLARE 	 @CustTypeId 	  	  	  	 INT,
 	  	  	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT,
 	  	  	 @SpecOrder 	  	  	  	 INT
-- Check to Make Sure Prod_Id was passed on Update Or Delete
IF 	 (@CustomerId IS NULL OR @CustomerId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Product Family
SELECT 	 @CustTypeId = 1
SELECT 	 @CustTypeId = Customer_Type_Id
 	 FROM 	 Customer_Types
 	 WHERE 	 Customer_Type_Desc = @CustomerType
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEMCU_AddCustomer
 	  	  	  	  	  	  	 @CustomerCode, 
 	  	  	  	  	  	  	 @CustomerName, 
 	  	  	  	  	  	  	 @ConsigneeCode,  	 
 	  	  	  	  	  	  	 @ConsigneeName, 
 	  	  	  	  	  	  	 @Address1, 
 	  	  	  	  	  	  	 @Address2, 
 	  	  	  	  	  	  	 @ContactName, 
 	  	  	  	  	  	  	 @ContactPhone, 
 	  	  	  	  	  	  	 @IsActive, 
 	  	  	  	  	  	  	 @CustomerGeneral1, 
 	  	  	  	  	  	  	 @CustomerGeneral2, 
 	  	  	  	  	  	  	 @CustomerGeneral3, 
 	  	  	  	  	  	  	 @CustomerGeneral4, 
 	  	  	  	  	  	  	 @CustomerGeneral5, 
 	  	  	  	  	  	  	 @CustTypeId, 
 	  	  	  	  	  	  	 @Address3, 
 	  	  	  	  	  	  	 @Address4, 
 	  	  	  	  	  	  	 @City, 
 	  	  	  	  	  	  	 @County, 
 	  	  	  	  	  	  	 @State, 
 	  	  	  	  	  	  	 @Country, 
 	  	  	  	  	  	  	 @Zip, 
 	  	  	  	  	  	  	 @UserId, 
 	  	  	  	  	  	  	 @CustomerId OUTPUT 
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEMCU_EditCustomer
 	  	  	  	  	  	  	 @CustomerId, 
 	  	  	  	  	  	  	 @CustomerCode, 
 	  	  	  	  	  	  	 @CustomerName, 
 	  	  	  	  	  	  	 @ConsigneeCode, 
 	  	  	  	  	  	  	 @ConsigneeName, 
 	  	  	  	  	  	  	 @Address1, 
 	  	  	  	  	  	  	 @Address2, 
 	  	  	  	  	  	  	 @ContactName, 
 	  	  	  	  	  	  	 @ContactPhone, 
 	  	  	  	  	  	  	 @IsActive, 
 	  	  	  	  	  	  	 @CustomerGeneral1, 
 	  	  	  	  	  	  	 @CustomerGeneral2, 
 	  	  	  	  	  	  	 @CustomerGeneral3, 
 	  	  	  	  	  	  	 @CustomerGeneral4, 
 	  	  	  	  	  	  	 @CustomerGeneral5, 
 	  	  	  	  	  	  	 @CustTypeId, 
 	  	  	  	  	  	  	 @Address3, 
 	  	  	  	  	  	  	 @Address4, 
 	  	  	  	  	  	  	 @City, 
 	  	  	  	  	  	  	 @County, 
 	  	  	  	  	  	  	 @State, 
 	  	  	  	  	  	  	 @Country, 
 	  	  	  	  	  	  	 @Zip, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE @RC = spEMCU_DeleteCustomer 
 	  	  	  	  	  	  	 @CustomerId, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
