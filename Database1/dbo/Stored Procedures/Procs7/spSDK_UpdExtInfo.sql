CREATE PROCEDURE dbo.spSDK_UpdExtInfo
 	 -- Input Parameters
 	 @ClassName 	  	  	  	 nvarchar(50),
 	 @Id 	  	  	  	  	  	 INT,
 	 @ExtInfo 	  	  	  	  	 nvarchar(255)
AS
-- Return Codes
-- 	  	  0: Success
-- 	  	  1: Record Not Found
IF UPPER(@ClassName) = 'PRODUCTIONLINE'
BEGIN
 	 IF (SELECT COUNT(PL_Id) FROM Prod_Lines WHERE PL_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Prod_Lines
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 PL_Id = @Id
END ELSE 
IF UPPER(@ClassName) = 'PRODUCTIONUNIT'
BEGIN
 	 IF (SELECT COUNT(PU_Id) FROM Prod_Units WHERE PU_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Prod_Units
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 PU_Id = @Id
END ELSE 
IF UPPER(@ClassName) = 'VARIABLE'
BEGIN
 	 IF (SELECT COUNT(Var_Id) FROM Variables WHERE Var_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Variables
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Var_Id = @Id
END ELSE 
IF UPPER(@ClassName) = 'PRODUCTIONEVENT'
BEGIN
 	 IF (SELECT COUNT(Event_Id) FROM Events WHERE Event_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Events
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Event_Id = @Id
END
IF UPPER(@ClassName) = 'SPECIFICATIONVARIABLE'
BEGIN
 	 IF (SELECT COUNT(Spec_Id) FROM Specifications WHERE Spec_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Specifications
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Spec_Id = @Id
END
IF UPPER(@ClassName) = 'GENEALOGYLINK'
BEGIN
 	 IF (SELECT COUNT(Component_Id) FROM Event_Components WHERE Component_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Event_Components
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Component_Id = @Id
END
IF UPPER(@ClassName) = 'PRODUCTIONPLAN'
BEGIN
 	 IF (SELECT COUNT(PP_Id) FROM Production_Plan WHERE PP_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Production_Plan
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 PP_Id = @Id
END
IF UPPER(@ClassName) = 'PRODUCTIONSETUP'
BEGIN
 	 IF (SELECT COUNT(PP_Setup_Id) FROM Production_Setup WHERE PP_Setup_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Production_Setup
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 PP_Setup_Id = @Id
END
IF UPPER(@ClassName) = 'CHARACTERISTIC'
BEGIN
 	 IF (SELECT COUNT(Char_Id) FROM Characteristics WHERE Char_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Characteristics
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Char_Id = @Id
END
IF UPPER(@ClassName) = 'CUSTOMER'
BEGIN
 	 IF (SELECT COUNT(Customer_Id) FROM Customer WHERE Customer_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Customer
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Customer_Id = @Id
END
IF UPPER(@ClassName) = 'ORDER'
BEGIN
 	 IF (SELECT COUNT(Order_Id) FROM Customer_Orders WHERE Order_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Customer_Orders
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Order_Id = @Id
END
IF UPPER(@ClassName) = 'ORDERLINE'
BEGIN
 	 IF (SELECT COUNT(Order_Line_Id) FROM Customer_Order_Line_Items WHERE Order_Line_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Customer_Order_Line_Items
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Order_Line_Id = @Id
END
If UPPER(@ClassName) = 'EVENTCONFIGURATION'
BEGIN
 	 IF (SELECT COUNT(EC_Id) FROM Event_Configuration WHERE EC_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Event_Configuration
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 EC_Id = @Id
END
If UPPER(@ClassName) = 'EVENTSUBTYPE'
BEGIN
 	 IF (SELECT COUNT(Event_Subtype_Id) FROM Event_Subtypes WHERE Event_Subtype_Id = @Id) <> 1 RETURN(1)
 	 UPDATE 	 Event_Subtypes
 	  	 SET 	 Extended_Info = @ExtInfo
 	  	 WHERE 	 Event_Subtype_Id = @Id
END
RETURN(0)
