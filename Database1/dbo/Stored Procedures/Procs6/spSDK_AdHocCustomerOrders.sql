CREATE PROCEDURE dbo.spSDK_AdHocCustomerOrders
 	 @sFilter 	  	  	  	  	 nVarChar(4000)
AS
-- Begin SP
CREATE TABLE 	 #Filter 	 (
 	 Filter_Id 	  	  	  	 INT IDENTITY(1,1),
 	 Filter_Type 	  	  	  	 INT,
 	 Field_Code 	  	  	  	 INT,
 	 Operator 	  	  	  	  	 INT,
 	 Filter 	  	  	  	  	 nvarchar(100)
)
DECLARE 	 @iPos 	  	  	  	 INT,
 	  	  	 @iDiv 	  	  	  	 INT,
 	  	  	 @iPos2 	  	  	 INT,
 	  	  	 @iDiv2 	  	  	 INT,
 	  	  	 @sValue 	  	  	 nvarchar(50),
 	  	  	 @iFilterLen 	  	 INT,
 	  	  	 @FieldType 	  	 nvarchar(2),
 	  	  	 @FieldCode 	  	 nvarchar(2),
 	  	  	 @CompType 	  	 nvarchar(2),
 	  	  	 @Filter 	  	  	 nvarchar(100),
 	  	  	 @ItemStart 	  	 nvarchar(1000),
 	  	  	 @ItemEnd 	  	  	 nvarchar(1000),
 	  	  	 @WhereItem 	  	 nvarchar(1000),
 	  	  	 @SQL 	  	  	  	 nVarChar(4000),
 	  	  	 @WhereClause 	 nVarChar(4000),
 	  	  	 @GroupBy 	  	  	 nvarchar(1000),
 	  	  	 @BracketCount 	 INT
SET 	 @sFilter = COALESCE(@sFilter, '')
SET 	 @iFilterLen 	 = LEN(@sFilter)
SET 	 @iPos 	  	  	 = 1
SET 	 @iDiv 	  	  	 = 0
WHILE 	 @iPos < @iFilterLen
BEGIN
 	 SET 	 @iDiv = CHARINDEX('|', @sFilter, @iPos)
 	 IF 	 @iDiv = 0 SET @iDiv = @iFilterLen + 1
 	 IF @iDiv > @iPos
 	 BEGIN
 	  	 SET 	 @sValue = NULL
 	  	 SET 	 @sValue = SUBSTRING(@sFilter, @iPos, @iDiv - @iPos)
 	 
 	  	 -- Get the inner Value
 	  	 SET 	 @iPos2 = 1
 	  	 SET 	 @iDiv2 = 0
 	 
 	  	 SET 	 @iDiv2 = CHARINDEX('~', @sValue, @iPos2)
 	 
 	  	 SET 	 @FieldType 	 = NULL
 	  	 SET 	 @FieldType 	 = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SET 	 @FieldType 	 = CASE WHEN @FieldType = '' THEN NULL ELSE @FieldType END
 	 
 	  	 SET 	 @iPos2 	 = @iDiv2 + 1
 	  	 SET 	 @iDiv2 	 = CHARINDEX('~', @sValue, @iPos2)
 	 
 	  	 SET 	 @FieldCode 	 = NULL
 	  	 SET 	 @FieldCode 	 = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SET 	 @FieldCode 	 = CASE WHEN @FieldCode = '' THEN NULL ELSE @FieldCode END
 	 
 	  	 SET 	 @iPos2 	 = @iDiv2 + 1
 	  	 SET 	 @iDiv2 	 = CHARINDEX('~', @sValue, @iPos2)
 	 
 	  	 SET 	 @CompType 	 = NULL
 	  	 SET 	 @CompType 	 = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SET 	 @CompType 	 = CASE WHEN @CompType = '' THEN NULL ELSE @CompType END
 	 
 	  	 SET 	 @iPos2 	 = @iDiv2 + 1
 	 
 	  	 SET 	 @Filter 	  	 = NULL
 	  	 SET 	 @Filter 	  	 = SUBSTRING(@sValue, @iPos2, LEN(@sValue) + 1)
 	  	 SET 	 @Filter 	  	 = CASE WHEN @Filter = '' THEN NULL ELSE @Filter END
 	 
 	  	 IF ISNUMERIC(@FieldType) = 0 	 SET @FieldType = NULL
 	  	 IF 	 ISNUMERIC(@FieldCode) = 0 	 SET @FieldCode = NULL
 	  	 IF ISNUMERIC(@CompType) = 0 	 SET @CompType = NULL
 	  	 
 	  	 INSERT 	 INTO 	 #Filter (Filter_Type, Field_Code, Operator, Filter 	 )
 	  	  	 VALUES 	 ( 	 @FieldType, @FieldCode, @CompType, @Filter 	 )
 	 
 	 END
 	 SET 	 @iPos = @iDiv + 1
END
SET 	 @WhereClause 	 = ''
SET 	 @BracketCount 	 = 0
DECLARE WhileCursor CURSOR FOR
 	 SELECT 	 Filter_Type, Field_Code, Operator, Filter
 	  	 FROM 	 #Filter
 	  	 ORDER BY Filter_Id
OPEN 	 WhileCursor
FETCH WhileCursor INTO @FieldType, @FieldCode, @CompType, @Filter
WHILE @@FETCH_STATUS = 0
BEGIN
 	 SET 	 @WhereItem = ''
 	 IF 	 @FieldType = 1
 	 BEGIN
 	  	 SET 	 @ItemStart = 	 CASE 	 @FieldCode
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'co.Order_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'co.Is_Active'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'co.Entered_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'co.Forecast_Mfg_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'co.Forecast_Ship_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'co.Actual_Mfg_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'co.Actual_Ship_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'COALESCE(c2.Consignee_Name, c2.Customer_Name)'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'co.Comment_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'c1.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'co.Order_General_1'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'co.Order_General_2'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'co.Order_General_3'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'co.Order_General_4'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'co.Order_General_5'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 16 	 THEN 	 'co.Order_Instructions'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 17 	 THEN 	 'co.Order_Type'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 18 	 THEN 	 'co.Order_Status'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 19 	 THEN 	 'co.Customer_Order_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 20 	 THEN 	 'co.Plant_Order_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 21 	 THEN 	 'co.Corporate_Order_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 22 	 THEN 	 'co.Extended_Info'
 	  	  	  	  	  	  	  	  	 END
 	  	 IF 	 @FieldCode IN (1)
 	  	 BEGIN
 	  	  	 SET 	 @ItemEnd = 	 CASE 	 @CompType
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 ' = ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 ' <> ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 NULL
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 '> ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 '< ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 ' IS NULL '
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 ' IS NOT NULL '
 	  	  	  	  	  	  	  	  	  	  	 END
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SET 	 @ItemEnd = 	 CASE 	 @CompType 
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 ' = ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 ' <> ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 ' LIKE ''' + REPLACE(REPLACE(REPLACE(COALESCE(@Filter, '%'), '*', '%'), '?', '_'), '[', '[[]') + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 ' > ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 ' < ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 ' IS NULL '
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 ' IS NOT NULL '
 	  	  	  	  	  	  	  	  	  	  	 END
 	  	 END
 	  	 SET 	 @WhereItem = ''
 	  	 SET 	 @WhereItem = CONVERT(nvarchar(1000), @ItemStart) + ' ' + CONVERT(nvarchar(1000), @ItemEnd)
 	 END ELSE
 	 IF 	 @FieldType = 2
 	 BEGIN
 	  	 IF 	 @WhereClause = ''
 	  	 BEGIN
 	  	  	 SET 	 @WhereItem = ''
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SET 	 @WhereItem = 	 CASE 	 @FieldCode
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 ' AND '
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 ' OR '
 	  	  	  	  	  	  	  	  	  	  	 END
 	  	 END
 	 END ELSE
 	 IF 	 @FieldType = 3
 	 BEGIN
 	  	 IF @FieldCode = 1
 	  	 BEGIN
 	  	  	 SET 	 @WhereItem 	 = ' ( '
 	  	  	 SET 	 @BracketCount 	 = @BracketCount + 1
 	  	 END ELSE
 	  	 IF @FieldCode = 2
 	  	 BEGIN
 	  	  	 SET 	 @WhereItem 	 = ' ) '
 	  	  	 SET 	 @BracketCount 	 = @BracketCount - 1
 	  	 END 	  	 
 	 END
 	 IF 	  	 @WhereClause = '' AND @WhereItem <> ''
 	 BEGIN
 	  	 SET 	 @WhereClause = ' 	 WHERE 	 '
 	 END
 	 SET 	 @WhereClause = @WhereClause + COALESCE(@WhereItem, '')
 	 FETCH WhileCursor INTO @FieldType, @FieldCode, @CompType, @Filter
END
SET 	 @iPos = 0
WHILE @iPos < @BracketCount
BEGIN
 	 SET 	 @WhereClause = @WhereClause + ' ) '
 	 SET 	 @iPos = @iPos + 1
END
CLOSE 	 WhileCursor
DEALLOCATE 	 WhileCursor
SET 	 @SQL = 
'SELECT 	 OrderId  	  	  	  	  	  	 = co.Order_Id,
 	  	  	 IsActive 	  	  	  	  	  	 = co.Is_Active,
 	  	  	 EnteredDate 	  	  	  	  	 = co.Entered_Date,
 	  	  	 ForecastMfgDate 	  	  	 = co.Forecast_Mfg_Date,
 	  	  	 ForecastShipDate 	  	  	 = co.Forecast_Ship_Date,
 	  	  	 ActualMfgDate 	  	  	  	 = co.Actual_Mfg_Date,
 	  	  	 ActualShipDate 	  	  	  	 = co.Actual_Ship_Date,
 	  	  	 ConsigneeName 	  	  	  	 = COALESCE(c2.Consignee_Name, c2.Customer_Name),
 	  	  	 TotalLineItems 	  	  	  	 = COUNT(coi.Order_Line_Id),
 	  	  	 CommentId 	  	  	  	  	 = co.Comment_Id,
 	  	  	 CustomerName 	  	  	  	 = c1.Customer_Name,
 	  	  	 OrderGeneral1 	  	  	  	 = co.Order_General_1,
 	  	  	 OrderGeneral2 	  	  	  	 = co.Order_General_2,
 	  	  	 OrderGeneral3 	  	  	  	 = co.Order_General_3,
 	  	  	 OrderGeneral4 	  	  	  	 = co.Order_General_4,
 	  	  	 OrderGeneral5 	  	  	  	 = co.Order_General_5,
 	  	  	 OrderInstructions 	  	  	 = co.Order_Instructions,
 	  	  	 OrderType 	  	  	  	  	 = co.Order_Type,
 	  	  	 OrderStatus 	  	  	  	  	 = co.Order_Status,
 	  	  	 CustomerOrderNumber 	  	 = co.Customer_Order_Number,
 	  	  	 PlantOrderNumber 	  	  	 = co.Plant_Order_Number,
 	  	  	 CorporateOrderNumber 	  	 = co.Corporate_Order_Number,
 	  	  	 ExtendedInfo 	  	  	  	 = co.Extended_Info
 	 FROM 	  	  	 Customer_Orders co
 	 INNER JOIN 	 Customer c1 	  	  	  	  	  	  	 ON 	  	 c1.Customer_Id = co.Customer_Id
 	 LEFT 	 JOIN 	 Customer c2 	  	  	  	  	  	  	 ON 	  	 c2.Customer_Id = co.Consignee_Id
 	 LEFT 	 JOIN 	 Customer_Order_Line_Items coi 	 ON 	  	 coi.Order_Id = co.Order_Id'
SET 	 @GroupBy = 
' 	 GROUP BY 	 co.Order_Id,co.Is_Active,co.Entered_Date,co.Forecast_Mfg_Date,
 	  	  	  	 co.Forecast_Ship_Date,co.Actual_Mfg_Date,co.Actual_Ship_Date,
 	  	  	  	 COALESCE(c2.Consignee_Name, c2.Customer_Name),co.Comment_Id,
 	  	  	  	 c1.Customer_Name,co.Order_General_1,co.Order_General_2,co.Order_General_3,
 	  	  	  	 co.Order_General_4,co.Order_General_5,co.Order_Instructions,
 	  	  	  	 co.Schedule_Block_Number,co.Order_Type,co.Order_Status,co.Customer_Order_Number,
 	  	  	  	 co.Plant_Order_Number,co.Corporate_Order_Number,co.Extended_Info'
EXECUTE (@SQL + @WhereClause + @GroupBy)
DROP TABLE #Filter
