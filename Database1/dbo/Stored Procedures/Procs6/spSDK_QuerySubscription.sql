CREATE PROCEDURE dbo.spSDK_QuerySubscription 
 	 @Key 	  	  	  	 INT,
 	 @MsgType 	  	  	 INT,
 	 @ItemName1 	  	 nvarchar(100) 	 OUTPUT,
 	 @ItemName2 	  	 nvarchar(100) 	 OUTPUT,
 	 @ItemName3 	  	 nvarchar(100) 	 OUTPUT
AS
DECLARE 	 @Id1 	  	 INT,
 	  	  	 @Id2 	  	 INT
-- sdkRTVariableResult = 1
-- sdkRTProductionEvent = 2
-- sdkRTSpecification = 3
-- sdkRTGenealogy = 4
-- sdkRTProductionPlan = 5
-- sdkRTProductChange = 6
-- sdkRTProdPlanSetup = 7
-- sdkRTProdPlanSetupDetail = 8
-- sdkRTDowntime = 9
-- sdkRTWaste = 10
-- sdkRTPEInputEvent = 11
-- sdkRTSheets = 13
-- sdkRTSheetColumns = 14
-- sdkRTSheetOptions = 
-- sdkRTDefect = 15
-- sdkRTFault = 16
-- sdkRTReason = 17
-- sdkRTReasonTree = 18
-- sdkRTReasonTreeConfig = 19
-- sdkRTVariable = 20
-- sdkRTWasteMeasurment = 21
-- sdkRTWasteType = 22
-- sdkRTProductionLine = 23
-- sdkRTProductionUnit = 24
-- sdkRTProduct = 25
-- sdkRTSubscription = 26
-- sdkRTAlarm = 12
-- sdkRTUserDefinedEvent
-- sdkRTCategory
-- sdkRTCustomer
-- sdkRTOrder
-- sdkRTOrderLine
-- sdkRTOrderLineSpec
-- sdkRTShipment
IF @MsgType = 1 
BEGIN
 	 --Variable (VariableId)
 	 SELECT 	 @ItemName3 = Var_Desc, @Id2 = PU_Id From Variables Where Var_Id = @Key
 	 SELECT 	 @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Id2
 	 SELECT 	 @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE 
IF @MsgType = 2
BEGIN
 	 --Production Event (UnitId)
 	 SELECT 	 @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
 	 SELECT 	 @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE 
IF @MsgType = 4
BEGIN
    --Genealogy (UnitId)
    SELECT 	 @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
    SELECT 	 @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE 
IF @MsgType = 5
BEGIN
    --Production Plan (UnitId)
    SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
    SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE 
IF @MsgType = 6
BEGIN
 	 --Grade Change (UnitId)
 	 SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
 	 SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE 
IF @Msgtype = 9
BEGIN
 	 --Downtime Event (UnitId)
 	 SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
 	 SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE
IF @Msgtype = 10
BEGIN
 	 --Waste Event (UnitId)
 	 SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
 	 SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE
IF @Msgtype = 11
BEGIN
 	 --Input Event (PEIId)
 	 SELECT @ItemName3 = Input_Name, @Id2 = PU_Id From PrdExec_Inputs Where PEI_Id = @Key
 	 SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Id2
 	 SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE
IF @Msgtype = 15
BEGIN
 	 --Defect Event (UnitId)
 	 SELECT @ItemName2 = PU_Desc, @Id1 = PL_Id From Prod_Units Where PU_Id = @Key
 	 SELECT @ItemName1 = PL_Desc From Prod_Lines Where PL_Id = @Id1
END ELSE
BEGIN
    -- Unknown Message Type
    RETURN(2)
END
RETURN(0)
