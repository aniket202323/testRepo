CREATE procedure [dbo].[spSDK_AU_CustomerOrderLineSpec_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CustomerCode varchar(50) ,
@CustomerId int ,
@CustomerOrderLineId int ,
@DataType nvarchar(50) ,
@DataTypeId int ,
@IsActive bit ,
@LowerLimit varchar(100) ,
@SpecName varchar(100) ,
@SpecPrecision int ,
@Target varchar(100) ,
@UpperLimit varchar(100) 
AS
/*
 	 Not changeable
 	 @CustomerCode
*/
If (@IsActive Is NULL)
 	 Select @IsActive = 0
 	 
IF @Id IS Null
BEGIN
 	 IF Exists(SELECT 1 FROM Customer_Order_Line_Specs a  	  	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE Order_Line_Id = @CustomerOrderLineId and Spec_Desc = @SpecName)
 	 BEGIN
 	  	 SELECT 'Order Line Item Spec already exists add not allowed'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEMCO_AddLineSpec 	 @CustomerOrderLineId,@SpecName,@DataTypeId,@SpecPrecision,@UpperLimit,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @Target,@LowerLimit,@AppUserId,@Id OUTPUT
 	 IF @Id IS Null
 	 BEGIN
 	  	 Select 'Unable to create Order Line spec'
 	  	 Return(-100)
 	 END
END
ELSE
BEGIN
 	 IF Not Exists(SELECT 1 FROM Customer_Order_Line_Specs WHERE Order_Spec_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Order Line Item Spec not found for update'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEMCO_EditLineSpec @Id,@SpecName,@DataTypeId,@SpecPrecision,@UpperLimit,@Target,@LowerLimit,@AppUserId
END
UPDATE Customer_Order_Line_Specs Set Is_Active = @IsActive,Order_Line_Id = @CustomerOrderLineId WHERE Order_Spec_Id = @Id 	  	  	  	  	 
Return(1)
