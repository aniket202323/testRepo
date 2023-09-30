CREATE PROCEDURE dbo.spSDK_UpdOrder
 	 -- Input Parameters
 	 @TransType 	  	  	  	  	 INT,
 	 @OrderType 	  	  	  	  	 nvarchar(50),
 	 @OrderStatus 	  	  	  	 nvarchar(50),
 	 @CustomerName 	  	  	  	 nvarchar(50),
 	 @ConsigneeName 	  	  	  	 nvarchar(50),
 	 @PlantOrderNumber 	  	  	 nvarchar(50), 
 	 @CustomerOrderNumber 	  	 nvarchar(50),
 	 @CorporateOrderNumber 	 nvarchar(50),
 	 @ForecastMfgDate 	  	  	 DATETIME,
 	 @ForecastShipDate 	  	  	 DATETIME,
 	 @ActualMfgDate 	  	  	  	 DATETIME,
 	 @ActualShipDate 	  	  	 DATETIME,
 	 @EnteredDate 	  	  	  	 DATETIME,
 	 @OrderInstructions 	  	 nvarchar(255),
 	 @OrderGeneral1 	  	  	  	 nvarchar(50), 
 	 @OrderGeneral2 	  	  	  	 nvarchar(50),
 	 @OrderGeneral3 	  	  	  	 nvarchar(50),
 	 @OrderGeneral4 	  	  	  	 nvarchar(50), 
 	 @OrderGeneral5 	  	  	  	 nvarchar(50),
 	 @IsActive 	  	  	  	  	 BIT,
 	 @UserId 	  	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @OrderId 	  	  	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: @OrderId Not Specified on Update/Delete
-- 	  	  2: Customer Not Found
-- 	  	  3: Consignee Not Found
SET  	 @OrderType = Ltrim(Rtrim(@OrderType))
SET  	 @OrderStatus = Ltrim(Rtrim(@OrderStatus))
SET  	 @CustomerName = Ltrim(Rtrim(@CustomerName))
SET  	 @ConsigneeName = Ltrim(Rtrim(@ConsigneeName))
SET  	 @PlantOrderNumber = Ltrim(Rtrim(@PlantOrderNumber))
SET  	 @CustomerOrderNumber = Ltrim(Rtrim(@CustomerOrderNumber))
SET  	 @CorporateOrderNumber = Ltrim(Rtrim(@CorporateOrderNumber))
SET  	 @OrderInstructions = Ltrim(Rtrim(@OrderInstructions))
SET  	 @OrderGeneral1 = Ltrim(Rtrim(@OrderGeneral1))
SET  	 @OrderGeneral2 = Ltrim(Rtrim(@OrderGeneral2))
SET  	 @OrderGeneral3 = Ltrim(Rtrim(@OrderGeneral3))
SET  	 @OrderGeneral4 = Ltrim(Rtrim(@OrderGeneral4))
SET  	 @OrderGeneral5 = Ltrim(Rtrim(@OrderGeneral5))
IF @OrderType = '' 	  	  	  	  	  	 SET  	 @OrderType = Null
IF @OrderStatus = '' 	  	  	  	  	 SET  	 @OrderStatus = Null
IF @CustomerName = '' 	  	  	  	  	 SET  	 @CustomerName = Null
IF @ConsigneeName = '' 	  	  	  	 SET  	 @ConsigneeName = Null
IF @PlantOrderNumber = '' 	  	  	 SET  	 @PlantOrderNumber = Null
IF @CustomerOrderNumber = '' 	 SET  	 @CustomerOrderNumber = Null
IF @CorporateOrderNumber = '' SET  	 @CorporateOrderNumber = Null
IF @OrderInstructions = '' 	  	 SET  	 @OrderInstructions = Null
IF @OrderGeneral1 = '' 	  	  	  	 SET  	 @OrderGeneral1 = Null
IF @OrderGeneral2 = '' 	  	  	  	 SET  	 @OrderGeneral2 = Null
IF @OrderGeneral3 = '' 	  	  	  	 SET  	 @OrderGeneral3 = Null
IF @OrderGeneral4 = '' 	  	  	  	 SET  	 @OrderGeneral4 = Null
IF @OrderGeneral5 = '' 	  	  	  	 SET  	 @OrderGeneral5 = Null
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT,
 	  	  	 @CustomerId 	  	  	  	 INT,
 	  	  	 @ConsigneeId 	  	  	 INT,
 	  	  	 @ScheduleBlockNumber 	 nvarchar(50)
-- Check to Make Sure @OrderId was passed on Update Or Delete
IF 	 (@OrderId IS NULL OR @OrderId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Customer
SELECT 	 @CustomerId = NULL
SELECT 	 @CustomerId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 Customer_Name = @CustomerName
IF @CustomerId IS NULL AND @CustomerName IS NOT NULL AND @TransType IN (1,2)
BEGIN
 	 RETURN(2)
END
-- Check For Valid Consignee
SELECT 	 @ConsigneeId = NULL
SELECT 	 @ConsigneeId = Customer_Id
 	 FROM 	 Customer
 	 WHERE 	 COALESCE(Consignee_Name, Customer_Name) = @ConsigneeName
IF @ConsigneeId IS NULL AND @ConsigneeName IS NOT NULL AND @TransType IN (1,2)
BEGIN
 	 RETURN(3)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEMCO_AddOrder
 	  	  	  	  	  	  	 @CustomerId, 
 	  	  	  	  	  	  	 @CustomerOrderNumber, 
 	  	  	  	  	  	  	 @PlantOrderNumber, 
 	  	  	  	  	  	  	 @CorporateOrderNumber, 
 	  	  	  	  	  	  	 NULL, 
 	  	  	  	  	  	  	 @OrderType,
 	  	  	  	  	  	  	 @OrderStatus, 
 	  	  	  	  	  	  	 @EnteredDate, 
 	  	  	  	  	  	  	 @UserId, 
 	  	  	  	  	  	  	 @ForecastMfgDate, 
 	  	  	  	  	  	  	 @ForecastShipDate, 
 	  	  	  	  	  	  	 @ActualMfgDate, 
 	  	  	  	  	  	  	 @ActualShipDate, 
 	  	  	  	  	  	  	 0,
 	  	  	  	  	  	  	 @OrderInstructions, 
 	  	  	  	  	  	  	 @OrderGeneral1, 
 	  	  	  	  	  	  	 @OrderGeneral2, 
 	  	  	  	  	  	  	 @OrderGeneral3, 
 	  	  	  	  	  	  	 @OrderGeneral4, 
 	  	  	  	  	  	  	 @OrderGeneral5, 
 	  	  	  	  	  	  	 @ConsigneeId, 
 	  	  	  	  	  	  	 @UserId, 
 	  	  	  	  	  	  	 @OrderId 	 OUTPUT 
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 SELECT 	 @ScheduleBlockNumber = NULL
 	 SELECT 	 @ScheduleBlockNumber = Schedule_Block_Number
 	  	 FROM 	 Customer_Orders
 	  	 WHERE 	 Order_Id = @OrderId
 	 EXECUTE 	 @RC = spEMCO_EditOrder
 	  	  	  	  	  	  	 @OrderId, 
 	  	  	  	  	  	  	 @CustomerOrderNumber, 
 	  	  	  	  	  	  	 @PlantOrderNumber, 
 	  	  	  	  	  	  	 @CorporateOrderNumber, 
 	  	  	  	  	  	  	 @ScheduleBlockNumber, 
 	  	  	  	  	  	  	 @OrderType, 
 	  	  	  	  	  	  	 @OrderStatus, 
 	  	  	  	  	  	  	 @ForecastMfgDate, 
 	  	  	  	  	  	  	 @ForecastShipDate, 
 	  	  	  	  	  	  	 @ActualMfgDate, 
 	  	  	  	  	  	  	 @ActualShipDate,
 	  	  	  	  	  	  	 0, 
 	  	  	  	  	  	  	 @OrderInstructions, 
 	  	  	  	  	  	  	 @OrderGeneral1, 
 	  	  	  	  	  	  	 @OrderGeneral2, 
 	  	  	  	  	  	  	 @OrderGeneral3, 
 	  	  	  	  	  	  	 @OrderGeneral4, 
 	  	  	  	  	  	  	 @OrderGeneral5, 
 	  	  	  	  	  	  	 @ConsigneeId, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEMCO_DeleteOrder
 	  	  	  	  	  	  	 @OrderId, 
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
