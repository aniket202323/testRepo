CREATE PROCEDURE dbo.spSDK_UpdOrderLine
 	 -- Input Parameters
 	 @TransType 	  	  	  	  	 INT,
 	 @CustomerName 	  	  	  	 nvarchar(50), 
 	 @PlantOrderNumber 	  	  	 nvarchar(50),
 	 @LineItemNumber 	  	  	 INT,
 	 @OrderedQuantity 	  	  	 FLOAT,
 	 @OrderedUOM 	  	  	  	  	 nvarchar(50),
 	 @ProductCode 	  	  	  	 nvarchar(50),
 	 @ConsigneeName 	  	  	  	 nvarchar(50),
 	 @EndCustomerName 	  	  	 nvarchar(50),
 	 @ShipToCustomerName 	  	 nvarchar(50),
 	 @CompleteDate 	  	  	  	 DATETIME,
 	 @COADate 	  	  	  	  	  	 DATETIME,
 	 @DimensionX 	  	  	  	  	 FLOAT,
 	 @DimensionY 	  	  	  	  	 FLOAT,
 	 @DimensionZ 	  	  	  	  	 FLOAT,
 	 @DimensionA 	  	  	  	  	 FLOAT,
 	 @DimensionXTolerance 	  	 FLOAT,
 	 @DimensionYTolerance 	  	 FLOAT, 
 	 @DimensionZTolerance 	  	 FLOAT,
 	 @DimensionATolerance 	  	 FLOAT,
 	 @OrderLineGeneral1 	  	 nvarchar(255),
 	 @OrderLineGeneral2 	  	 nvarchar(255),
 	 @OrderLineGeneral3 	  	 nvarchar(255),
 	 @OrderLineGeneral4 	  	 nvarchar(255),
 	 @OrderLineGeneral5 	  	 nvarchar(255),
 	 @IsActive 	  	  	  	  	 BIT,
 	 @UserId 	  	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @OrderLineId 	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: @OrderLineId Not Specified on Update/Delete
-- 	  	  2: Customer Not Found
-- 	  	  3: Consignee Not Found
-- 	  	  4: End Customer Not Found
-- 	  	  5: Ship To Customer Not Found
-- 	  	  6: Product Code Not Found
-- 	  	  7: PlantOrderNumber Not Found
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT,
 	  	  	 @CustomerId 	  	  	  	 INT,
 	  	  	 @ConsigneeId 	  	  	 INT,
 	  	  	 @EndUserId 	  	  	  	 INT,
 	  	  	 @ShipToId 	  	  	  	 INT,
 	  	  	 @ProdId 	  	  	  	  	 INT,
 	  	  	 @OrderId 	  	  	  	  	 INT
SET  	 @CustomerName = Ltrim(Rtrim(@CustomerName))
SET  	 @ConsigneeName = Ltrim(Rtrim(@ConsigneeName))
SET  	 @PlantOrderNumber = Ltrim(Rtrim(@PlantOrderNumber))
SET  	 @OrderedUOM = Ltrim(Rtrim(@OrderedUOM))
SET  	 @ProductCode = Ltrim(Rtrim(@ProductCode))
SET  	 @EndCustomerName = Ltrim(Rtrim(@EndCustomerName))
SET  	 @ShipToCustomerName = Ltrim(Rtrim(@ShipToCustomerName))
SET  	 @OrderLineGeneral1 = Ltrim(Rtrim(@OrderLineGeneral1))
SET  	 @OrderLineGeneral2 = Ltrim(Rtrim(@OrderLineGeneral2))
SET  	 @OrderLineGeneral3 = Ltrim(Rtrim(@OrderLineGeneral3))
SET  	 @OrderLineGeneral4 = Ltrim(Rtrim(@OrderLineGeneral4))
SET  	 @OrderLineGeneral5 = Ltrim(Rtrim(@OrderLineGeneral5))
IF @CustomerName = '' 	  	  	  	  	 SET  	 @CustomerName = Null
IF @ConsigneeName = '' 	  	  	  	 SET  	 @ConsigneeName = Null
IF @PlantOrderNumber = '' 	  	  	 SET  	 @PlantOrderNumber = Null
IF @OrderedUOM = '' 	  	  	  	  	  	 SET  	 @OrderedUOM = Null
IF @ProductCode = '' 	  	  	  	  	 SET  	 @ProductCode = Null
IF @EndCustomerName = '' 	  	  	 SET  	 @EndCustomerName = Null
IF @ShipToCustomerName = '' 	  	 SET  	 @ShipToCustomerName = Null
IF @OrderLineGeneral1 = '' 	  	  	  	 SET  	 @OrderLineGeneral1 = Null
IF @OrderLineGeneral2 = '' 	  	  	  	 SET  	 @OrderLineGeneral2 = Null
IF @OrderLineGeneral3 = '' 	  	  	  	 SET  	 @OrderLineGeneral3 = Null
IF @OrderLineGeneral4 = '' 	  	  	  	 SET  	 @OrderLineGeneral4 = Null
IF @OrderLineGeneral5 = '' 	  	  	  	 SET  	 @OrderLineGeneral5 = Null
-- Check to Make Sure @OrderLineId was passed on Update Or Delete
IF 	 (@OrderLineId IS NULL OR @OrderLineId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Customer
SELECT 	 @CustomerId = NULL
SELECT 	 @CustomerId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 Customer_Name = @CustomerName
IF @CustomerId IS NULL AND @CustomerName IS NOT NULL AND @TransType <> 3
BEGIN
 	 RETURN(2)
END
-- Check For Valid Consignee
SELECT 	 @ConsigneeId = NULL
SELECT 	 @ConsigneeId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 COALESCE(Consignee_Name, Customer_Name) = @ConsigneeName
IF @ConsigneeId IS NULL AND @ConsigneeName IS NOT NULL AND @TransType <> 3
BEGIN
 	 RETURN(3)
END
-- Check For Valid End Customer
SELECT 	 @EndUserId = NULL
SELECT 	 @EndUserId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 Customer_Name = @EndCustomerName
IF @EndUserId IS NULL AND @EndCustomerName IS NOT NULL AND @TransType <> 3
BEGIN
 	 RETURN(4)
END
-- Check For Valid End Customer
SELECT 	 @ShipToId = NULL
SELECT 	 @ShipToId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 Customer_Name = @ShipToCustomerName
IF @ShipToId IS NULL AND @ShipToCustomerName IS NOT NULL AND @TransType <> 3
BEGIN
 	 RETURN(5)
END
SELECT 	 @ProdId = NULL
SELECT 	 @ProdId = Prod_Id
 	 FROM 	 Products
 	 WHERE 	 Prod_Code = @ProductCode
IF @ProdId IS NULL AND @TransType <> 3
BEGIN
 	 RETURN(6)
END
SELECT 	 @OrderId = NULL
SELECT 	 @OrderId = Order_Id
 	 FROM 	 Customer_Orders
 	 WHERE 	 Customer_Id = @CustomerId
 	 AND 	 Plant_Order_Number = @PlantOrderNumber
IF @OrderId IS NULL AND @TransType <> 3
BEGIN
 	 RETURN(7)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEMCO_AddLineItem
 	  	  	  	  	  	  	 @OrderId, 
 	  	  	  	  	  	  	 @LineItemNumber, 
 	  	  	  	  	  	  	 @ProdId, 
 	  	  	  	  	  	  	 @OrderedQuantity, 
 	  	  	  	  	  	  	 @OrderedUOM, 
 	  	  	  	  	  	  	 @DimensionX, 
 	  	  	  	  	  	  	 @DimensionY, 
 	  	  	  	  	  	  	 @DimensionZ, 
 	  	  	  	  	  	  	 @DimensionA, 
 	  	  	  	  	  	  	 @CompleteDate, 
 	  	  	  	  	  	  	 @OrderLineGeneral1, 
 	  	  	  	  	  	  	 @OrderLineGeneral2, 
 	  	  	  	  	  	  	 @OrderLineGeneral3, 
 	  	  	  	  	  	  	 @OrderLineGeneral4, 
 	  	  	  	  	  	  	 @OrderLineGeneral5, 
 	  	  	  	  	  	  	 @ConsigneeId, 
 	  	  	  	  	  	  	 @UserId, 
 	  	  	  	  	  	  	 @OrderLineId OUTPUT 
 	 Update Customer_Order_Line_Items set COA_Date = @COADate 
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEMCO_EditLineItem
 	  	  	  	  	  	  	 @OrderLineId, 
 	  	  	  	  	  	  	 @LineItemNumber, 
 	  	  	  	  	  	  	 @ProdId, 
 	  	  	  	  	  	  	 @OrderedQuantity, 
 	  	  	  	  	  	  	 @OrderedUOM, 
 	  	  	  	  	  	  	 @DimensionX, 
 	  	  	  	  	  	  	 @DimensionY, 
 	  	  	  	  	  	  	 @DimensionZ, 
 	  	  	  	  	  	  	 @DimensionA, 
 	  	  	  	  	  	  	 @CompleteDate, 
 	  	  	  	  	  	  	 @OrderLineGeneral1, 
 	  	  	  	  	  	  	 @OrderLineGeneral2, 
 	  	  	  	  	  	  	 @OrderLineGeneral3, 
 	  	  	  	  	  	  	 @OrderLineGeneral4, 
 	  	  	  	  	  	  	 @OrderLineGeneral5, 
 	  	  	  	  	  	  	 @ConsigneeId, 
 	  	  	  	  	  	  	 @UserId
 	  	 Update Customer_Order_Line_Items set COA_Date = @COADate 
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEMCO_DeleteLineItem
 	  	  	  	  	  	  	 @OrderLineId, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
