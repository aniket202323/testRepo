Create Procedure dbo.spDAML_FetchCustomerOrderLines
    @OrderLineId 	 INT = NULL,
    @CustomerName 	 VARCHAR(100) = NULL,
    @PlantOrder 	  	 VARCHAR(50) = NULL,
 	 @LineNumber 	  	 INT = NULL,
 	 @ProductCode 	 VARCHAR(25) = NULL,
    @UTCOffset 	  	 VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(5000),
 	 @OrderClause 	 VARCHAR(500),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Customer order lines have no special security
SET @SecurityClause = ' WHERE 1=1 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@OrderLineId<>0 AND @OrderLineId IS NOT NULL) THEN ' AND coi.Order_Line_Id = ' + CONVERT(VARCHAR(10), @OrderLineId) + ' '
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- The query will use LIKE if and only if a wildcard character is used
SET @OptionsClause = ''
IF (@CustomerName<>'' AND @CustomerName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @CustomerName)=0 AND CHARINDEX('_', @CustomerName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND cust.Customer_Name = ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND cust.Customer_Name LIKE ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
END
IF (@PlantOrder<>'' AND @PlantOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@PlantOrder)=0 AND CHARINDEX('_', @PlantOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND co.Plant_Order_Number = ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND co.Plant_Order_Number LIKE ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
END
IF (@LineNumber<>0 AND @LineNumber IS NOT NULL) BEGIN
     SET @OptionsClause = @OptionsClause + ' AND coi.Line_Item_Number = ' + CONVERT(VARCHAR(10),@LineNumber) + ' '
END 
IF (@ProductCode<>'' AND @ProductCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@ProductCode)=0 AND CHARINDEX('_', @ProductCode)=0 )
     SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code = ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND p.Prod_Code LIKE ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
END
-- Customer order lines have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 CustomerOrderLineId  	 = coi.Order_Line_Id,
 	  	  	 CustomerId 	  	  	  	 = IsNull(co.Customer_Id,0),
 	  	  	 CustomerName 	  	  	 = IsNull(cust.Customer_Name,''''),
 	  	  	 PlantOrderNumber 	  	 = IsNull(co.Plant_Order_Number,''''),
 	  	  	 IsActive 	  	  	  	 = coi.Is_Active,
 	  	  	 LineItemNumber 	  	  	 = IsNull(coi.Line_Item_Number,0),
 	  	  	 OrderedQuantity 	  	  	 = IsNull(coi.Ordered_Quantity,0),
 	  	  	 OrderedUnitOfMeasure 	 = IsNull(coi.Ordered_UOM,''''),
 	  	  	 DimensionX 	  	  	  	 = IsNull(coi.Dimension_X,0),
 	  	  	 DimensionY 	  	  	  	 = IsNull(coi.Dimension_Y,0),
 	  	  	 DimensionZ 	  	  	  	 = IsNull(coi.Dimension_Z,0),
 	  	  	 DimensionA 	  	  	  	 = IsNull(coi.Dimension_A,0),
 	  	  	 DimensionXTolerance 	  	 = IsNull(coi.Dimension_X_Tolerance,0),
 	  	  	 DimensionYTolerance 	  	 = IsNull(coi.Dimension_Y_Tolerance,0),
 	  	  	 DimensionZTolerance 	  	 = IsNull(coi.Dimension_Z_Tolerance,0),
 	  	  	 DimensionATolerance 	  	 = IsNull(coi.Dimension_A_Tolerance,0),
 	  	  	 ConsigneeId 	  	  	  	 = IsNull(coi.Consignee_Id,0),
 	  	  	 ConsigneeName 	  	  	 = IsNull(COALESCE(ccons.Consignee_Name, ccons.Customer_Name),''''),
 	  	  	 ShipToCustomerId 	  	 = IsNull(coi.ShipTo_Id,0),
 	  	  	 ShipToCustomerName 	  	 = IsNull(cship.Customer_Name,''''),
 	  	  	 EndCustomerId 	  	  	 = IsNull(coi.EndUser_Id,0),
 	  	  	 EndCustomerName 	  	  	 = IsNull(cend.Customer_Name,''''),
 	  	  	 CompleteDate 	  	  	 = CASE WHEN coi.Complete_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	  '   ELSE dbo.fnServer_CmnConvertFromDbTime(coi.Complete_Date,''UTC'')  '  + 
 	  	  	  	  	  	  	  	  	  	  ' END,
 	  	  	 COADate 	  	  	  	  	 = CASE WHEN coi.COA_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	  '   ELSE dbo.fnServer_CmnConvertFromDbTime(coi.COA_Date,''UTC'')  ' +  
 	  	  	  	  	  	  	  	  	  	  ' END,
 	  	  	 ProductId 	  	  	  	 = coi.Prod_Id,
 	  	  	 ProductCode 	  	  	  	 = IsNull(p.Prod_Code,''''),
 	  	  	 CommentId 	  	  	  	 = IsNull(coi.Comment_Id,0),
 	  	  	 OrderLineGeneral1 	  	 = IsNull(coi.Order_Line_General_1,''''),
 	  	  	 OrderLineGeneral2 	  	 = IsNull(coi.Order_Line_General_2,''''),
 	  	  	 OrderLineGeneral3 	  	 = IsNull(coi.Order_Line_General_3,''''),
 	  	  	 OrderLineGeneral4 	  	 = IsNull(coi.Order_Line_General_4,''''),
 	  	  	 OrderLineGeneral5 	  	 = IsNull(coi.Order_Line_General_5,''''),
 	  	  	 ExtendedInfo 	  	  	 = IsNull(coi.Extended_Info,''''),
 	  	  	 CustomerOrderId 	  	  	  	  	 = IsNull(co.Order_Id,0)
 	 FROM 	 Customer_Orders co
 	 INNER JOIN 	 Customer_Order_Line_Items coi 	 ON 	  	 coi.Order_Id = co.Order_Id
 	 INNER JOIN 	 Products p 	  	  	  	  	  	 ON 	  	 p.Prod_Id = coi.Prod_Id
 	 INNER JOIN 	 Customer cust 	  	  	  	  	 ON 	  	 cust.Customer_Id = co.Customer_Id
 	 LEFT 	 JOIN 	 Customer ccons 	  	  	  	 ON 	  	 ccons.Customer_Id = coi.Consignee_Id
 	 LEFT 	 JOIN 	 Customer cship 	  	  	  	 ON 	  	 cship.Customer_Id = coi.ShipTo_Id
 	 LEFT 	 JOIN 	 Customer cend 	  	  	  	 ON 	  	 cend.Customer_Id = coi.EndUser_Id '
--  order clause
SET @OrderClause = ' ORDER BY cust.Customer_Name, co.Plant_Order_Number, coi.Line_Item_Number '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
