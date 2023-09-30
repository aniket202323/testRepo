Create Procedure dbo.spDAML_FetchCustomerOrders
    @OrderId 	  	 INT = NULL,
    @CustomerName 	 VARCHAR(100) = NULL,
 	 @CustomerOrder 	 VARCHAR(50) = NULL,
    @PlantOrder 	  	 VARCHAR(50) = NULL,
 	 @CorporateOrder 	 VARCHAR(50) = NULL,
 	 @OrderStatus 	 VARCHAR(10) = NULL,
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
    @GroupByClause  VARCHAR(2000),
    @MinTime 	  	 VARCHAR(25),
    @MaxTime 	  	 VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Customer orders have no special security
SET @SecurityClause = ' WHERE 1=1 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@OrderId<>0 AND @OrderId IS NOT NULL) THEN ' AND co.Order_Id = ' + CONVERT(VARCHAR(10), @OrderId) + ' '
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- The query will use LIKE if and only if a wildcard character is specified
SET @OptionsClause = ''
IF (@CustomerName<>'' AND @CustomerName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @CustomerName)=0 AND CHARINDEX('_', @CustomerName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND c1.Customer_Name = ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND c1.Customer_Name LIKE ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
END
IF (@CustomerOrder<>'' AND @CustomerOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@CustomerOrder)=0 AND CHARINDEX('_', @CustomerOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND co.Customer_Order_Number = ''' + CONVERT(VARCHAR(50),@CustomerOrder) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND co.Customer_Order_Number LIKE ''' + CONVERT(VARCHAR(50),@CustomerOrder) + ''' '
END 
IF (@PlantOrder<>'' AND @PlantOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@PlantOrder)=0 AND CHARINDEX('_', @PlantOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND co.Plant_Order_Number = ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND co.Plant_Order_Number LIKE ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
END 
IF (@CorporateOrder<>'' AND @CorporateOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@CorporateOrder)=0 AND CHARINDEX('_', @CorporateOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND co.Corporate_Order_Number = ''' + CONVERT(VARCHAR(50),@CorporateOrder) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND co.Corporate_Order_Number LIKE ''' + CONVERT(VARCHAR(50),@CorporateOrder) + ''' '
END 
IF (@OrderStatus<>'' AND @OrderStatus IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@OrderStatus)=0 AND CHARINDEX('_', @OrderStatus)=0 )
     SET @OptionsClause = @OptionsClause + ' AND co.Order_Status = ''' + CONVERT(VARCHAR(10),@OrderStatus) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND co.Order_Status LIKE ''' + CONVERT(VARCHAR(10),@OrderStatus) + ''' '
END 
-- Customer orders have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 CustomerOrderId  	  	 = co.Order_Id,
 	  	  	 IsActive 	  	  	  	 = co.Is_Active,
 	  	  	 EnteredDate 	  	  	  	 = dbo.fnServer_CmnConvertFromDbTime(co.Entered_Date,''UTC'')  ' + ',
 	  	  	 ForecastMfgDate 	  	  	 = CASE WHEN co.Forecast_Mfg_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	  '   ELSE dbo.fnServer_CmnConvertFromDbTime(co.Forecast_Mfg_Date,''UTC'')  ' + 
 	  	  	  	  	  	  	  	  	  	  ' END,
 	  	  	 ForecastShipDate 	  	 = CASE WHEN co.Forecast_Ship_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	 '    ELSE dbo.fnServer_CmnConvertFromDbTime(co.Forecast_Ship_Date,''UTC'')  ' + 
 	  	  	  	  	  	  	  	  	  	 '  END,
 	  	  	 ActualMfgDate 	  	  	 = CASE WHEN co.Actual_Mfg_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	 '    ELSE dbo.fnServer_CmnConvertFromDbTime(co.Actual_Mfg_Date,''UTC'')  ' + 
 	  	  	  	  	  	  	  	  	  	 '  END,
 	  	  	 ActualShipDate 	  	  	 = CASE WHEN co.Actual_Ship_Date IS NULL THEN ' + @MaxTime +
 	  	  	  	  	  	  	  	  	  	 '    ELSE dbo.fnServer_CmnConvertFromDbTime(co.Actual_Ship_Date,''UTC'')  ' + 
 	  	  	  	  	  	  	  	  	  	 '  END, 	 
 	  	  	 ConsigneeId 	  	  	  	 = IsNull(co.Consignee_Id,0), 	 
 	  	  	 ConsigneeName 	  	  	 = IsNull(COALESCE(c2.Consignee_Name, c2.Customer_Name),''''),
 	  	  	 TotalLineItems 	  	  	 = COUNT(coi.Order_Line_Id),
 	  	  	 CommentId 	  	  	  	 = IsNull(co.Comment_Id,0),
 	  	  	 CustomerId 	  	  	  	 = co.Customer_Id,
 	  	  	 CustomerName 	  	  	 = IsNull(c1.Customer_Name,''''),
 	  	  	 OrderGeneral1 	  	  	 = IsNull(co.Order_General_1,''''),
 	  	  	 OrderGeneral2 	  	  	 = IsNull(co.Order_General_2,''''),
 	  	  	 OrderGeneral3 	  	  	 = IsNull(co.Order_General_3,''''),
 	  	  	 OrderGeneral4 	  	  	 = IsNull(co.Order_General_4,''''),
 	  	  	 OrderGeneral5 	  	  	 = IsNull(co.Order_General_5,''''),
 	  	  	 OrderInstructions 	  	 = IsNull(co.Order_Instructions,''''),
 	  	  	 OrderType 	  	  	  	 = IsNull(co.Order_Type,''''),
 	  	  	 OrderStatus 	  	  	  	 = IsNull(co.Order_Status,''''),
 	  	  	 CustomerOrderNumber 	  	 = IsNull(co.Customer_Order_Number,''''),
 	  	  	 PlantOrderNumber 	  	 = IsNull(co.Plant_Order_Number,''''),
 	  	  	 CorporateOrderNumber 	 = IsNull(co.Corporate_Order_Number,''''),
 	  	  	 ExtendedInfo 	  	  	 = IsNull(co.Extended_Info,'''')
 	 FROM 	  	 Customer_Orders co
 	 INNER JOIN 	 Customer c1 	  	 ON 	  	 c1.Customer_Id = co.Customer_Id
 	 LEFT JOIN 	 Customer c2 	  	 ON 	  	 c2.Customer_Id = co.Consignee_Id
 	 LEFT JOIN 	 Customer_Order_Line_Items coi 	 ON 	  	 coi.Order_Id = co.Order_Id '
SET 	 @GroupByClause = 
' 	 GROUP BY 	 co.Order_Id,co.Is_Active,co.Entered_Date,co.Forecast_Mfg_Date,
 	  	  	  	 co.Forecast_Ship_Date,co.Actual_Mfg_Date,co.Actual_Ship_Date,co.Consignee_Id,
 	  	  	  	 COALESCE(c2.Consignee_Name, c2.Customer_Name),co.Comment_Id,co.Customer_Id,
 	  	  	  	 c1.Customer_Name,co.Order_General_1,co.Order_General_2,co.Order_General_3,
 	  	  	  	 co.Order_General_4,co.Order_General_5,co.Order_Instructions,
 	  	  	  	 co.Schedule_Block_Number,co.Order_Type,co.Order_Status,co.Customer_Order_Number,
 	  	  	  	 co.Plant_Order_Number,co.Corporate_Order_Number,co.Extended_Info'
-- SELECT sc = @SelectClause, wc = @WhereClause, gc = @GroupByClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @GroupByClause)
