CREATE procedure [dbo].[spSDK_AU_Customer]
@AppUserId int,
@Id int OUTPUT,
@Address1 varchar(255) ,
@Address2 varchar(255) ,
@Address3 varchar(255) ,
@Address4 varchar(255) ,
@City varchar(200) ,
@CityStateZip varchar(100) ,
@ConsigneeCode varchar(200) ,
@ConsigneeName varchar(100) ,
@ContactName varchar(100) ,
@ContactPhone varchar(200) ,
@Country varchar(200) ,
@County varchar(200) ,
@CustomerCode varchar(50) ,
@CustomerGeneral1 varchar(100) ,
@CustomerGeneral2 varchar(100) ,
@CustomerGeneral3 varchar(100) ,
@CustomerGeneral4 varchar(100) ,
@CustomerGeneral5 varchar(100) ,
@CustomerName varchar(100) ,
@CustomerType varchar(200) ,
@CustomerTypeId int ,
@ExtendedInfo varchar(255) ,
@IsActive bit ,
@State varchar(200) ,
@Zip varchar(100) 
AS
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldCustomerCode 	 VarChar(50)
IF @Id Is NOT Null --Rename
BEGIN
 	 IF Not Exists(SELECT 1 FROM Customer a WHERE Customer_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Customer not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldCustomerCode = Customer_Code FROM Customer WHERE Customer_Id = @Id
 	 IF @OldCustomerCode <> @CustomerCode
 	 BEGIN
 	  	 UPDATE Customer SET Customer_Code = @CustomerCode 	  	 WHERE Customer_Id = @Id
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Customer a WHERE Customer_Code = @CustomerCode)
 	 BEGIN
 	  	 SELECT 'Customer already exists add not allowed'
 	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportCustomers 	 @CustomerName,@CustomerCode,@CustomerType,@Address1,@Address2,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @Address3,@Address4,@City,@State,@Zip,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @Country,@ContactName,@ContactPhone,@ExtendedInfo,@CustomerGeneral1,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CustomerGeneral2,@CustomerGeneral3,@CustomerGeneral4,@CustomerGeneral5,@IsActive,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = Customer_Id FROM Customer WHERE Customer_Code = @CustomerCode
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Customer failed'
 	  	 RETURN(-100)
 	 END
END
UPDATE Customer SET Consignee_Code = @ConsigneeCode,Consignee_Name = @ConsigneeName,County = @County,Extended_Info =@ExtendedInfo,City_State_Zip = @CityStateZip
 	 WHERE Customer_Id = @Id
Return(1)
