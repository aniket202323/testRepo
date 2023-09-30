CREATE PROCEDURE dbo.spSDK_UpdOrderLineSpec
 	 -- Input Parameters
 	 @TransType 	  	  	  	  	 INT,
 	 @CustomerName 	  	  	  	 nvarchar(50), 
 	 @PlantOrderNumber 	  	  	 nvarchar(50),
 	 @LineItemNumber 	  	  	 INT,
 	 @SpecName 	  	  	  	  	 nvarchar(50),
 	 @SpecPrecision 	  	  	  	 INT,
 	 @DataType 	  	  	  	  	 nvarchar(50),
 	 @LowerLimit 	  	  	  	  	 nvarchar(50),
 	 @Target 	  	  	  	  	  	 nvarchar(50),
 	 @UpperLimit 	  	  	  	  	 nvarchar(50),
 	 @IsActive 	  	  	  	  	 BIT,
 	 @OrderId 	  	  	  	  	  	 INT,
 	 @OrderLineId 	  	  	  	 INT,
 	 @UserId 	  	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @OrderLineSpecId 	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: @OrderLineId Not Specified on Update/Delete
-- 	  	  2: Customer Not Found
-- 	  	  3: Order Not Found
-- 	  	  4: Order Line Not Found
-- 	  	  5: Data Type Not Found
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @CustomerId 	  	  	  	 INT,
 	  	  	 @DataTypeId 	  	  	  	 INT
-- Check to Make Sure @OrderLineId was passed on Update Or Delete
IF 	 (@OrderLineSpecId IS NULL OR @OrderLineSpecId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
IF @TransType IN (1,2)
BEGIN
 	 -- Check For Valid Customer
 	 SELECT 	 @CustomerId = NULL
 	 SELECT 	 @CustomerId = Customer_Id
 	  	 FROM 	 Customer
 	  	 WHERE 	 Customer_Name = @CustomerName
 	 
 	 IF @CustomerId IS NULL AND @CustomerName IS NOT NULL
 	 BEGIN
 	  	 RETURN(2)
 	 END
 	 
 	 IF @OrderId IS NOT NULL
 	 BEGIN
 	  	 IF (SELECT 	 COUNT(*) 
 	  	  	  	 FROM 	 Customer_Orders 
 	  	  	  	 WHERE 	 Order_Id = @OrderId) = 0
 	  	 BEGIN
 	  	  	 RETURN(3)
 	  	 END
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @OrderId = Order_Id
 	  	  	 FROM 	 Customer_Orders
 	  	  	 WHERE 	 Customer_Id = @CustomerId
 	  	  	 AND 	 Plant_Order_Number = @PlantOrderNumber
 	 END
 	 
 	 IF @OrderId IS NULL
 	 BEGIN
 	  	 RETURN(3)
 	 END
 	 
 	 IF @OrderLineId IS NOT NULL
 	 BEGIN
 	  	 IF (SELECT 	 COUNT(*) 
 	  	  	  	 FROM 	 Customer_Order_Line_Items 
 	  	  	  	 WHERE 	 Order_Id = @OrderId 
 	  	  	  	 AND 	 Order_Line_Id = @OrderLineId) = 0
 	  	 BEGIN
 	  	  	 RETURN(4)
 	  	 END
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @OrderId = Order_Id
 	  	  	 FROM 	 Customer_Orders
 	  	  	 WHERE 	 Customer_Id = @CustomerId
 	  	  	 AND 	 Plant_Order_Number = @PlantOrderNumber
 	 END
 	 
 	 IF @OrderLineId IS NULL
 	 BEGIN
 	  	 RETURN(4)
 	 END
 	 
 	 SELECT 	 @DataTypeId = NULL
 	 SELECT 	 @DataTypeId = Data_Type_Id
 	  	 FROM 	 Data_Type
 	  	 WHERE 	 Data_Type_Desc = @DataType
 	 IF @DataTypeId IS NULL
 	 BEGIN
 	  	 RETURN(5)
 	 END
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEMCO_AddLineSpec
 	  	  	  	  	  	  	 @OrderLineId,
 	  	  	  	  	  	  	 @SpecName,
 	  	  	  	  	  	  	 @DataTypeId,
 	  	  	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	  	  	 @UpperLimit,
 	  	  	  	  	  	  	 @Target,
 	  	  	  	  	  	  	 @LowerLimit,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @OrderLineSpecId 	 OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEMCO_EditLineSpec
 	  	  	  	  	  	  	 @OrderLineSpecId,
 	  	  	  	  	  	  	 @SpecName,
 	  	  	  	  	  	  	 @DataTypeId,
 	  	  	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	  	  	 @UpperLimit,
 	  	  	  	  	  	  	 @Target,
 	  	  	  	  	  	  	 @LowerLimit,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEMCO_DeleteLineSpec
 	  	  	  	  	  	  	 @OrderLineSpecId, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
