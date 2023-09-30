CREATE PROCEDURE dbo.spSDK_AdHocOrderLines
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'coi.Order_Line_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'cust.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'co.Plant_Order_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'coi.Is_Active'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'coi.Line_Item_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'coi.Ordered_Quantity'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'coi.Ordered_UOM'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'coi.Dimension_X'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'coi.Dimension_Y'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'coi.Dimension_Z'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'coi.Dimension_A'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'coi.Dimension_X_Tolerance'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'coi.Dimension_Y_Tolerance'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'coi.Dimension_Z_Tolerance'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'coi.Dimension_A_Tolerance'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 16 	 THEN 	 'COALESCE(ccons.Consignee_Name, ccons.Customer_Name)'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 17 	 THEN 	 'cship.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 18 	 THEN 	 'cend.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 19 	 THEN 	 'coi.Complete_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 20 	 THEN 	 'coi.COA_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 21 	 THEN 	 'p.Prod_Code'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 22 	 THEN 	 'c.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 23 	 THEN 	 'coi.Order_Line_General_1'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 24 	 THEN 	 'coi.Order_Line_General_2'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 25 	 THEN 	 'coi.Order_Line_General_3'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 26 	 THEN 	 'coi.Order_Line_General_4'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 27 	 THEN 	 'coi.Order_Line_General_5'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 28 	 THEN 	 'coi.Extended_Info'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 29 	 THEN 	 'co.Order_Id'
 	  	  	  	  	  	  	  	  	 END
 	  	 IF 	 @FieldCode IN (1, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 29)
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
'SELECT 	 OrderLineId  	  	  	  	 = coi.Order_Line_Id,
 	  	  	 CustomerName 	  	  	  	 = cust.Customer_Name,
 	  	  	 PlantOrderNumber 	  	  	 = co.Plant_Order_Number,
 	  	  	 IsActive 	  	  	  	  	  	 = coi.Is_Active,
 	  	  	 LineItemNumber 	  	  	  	 = coi.Line_Item_Number,
 	  	  	 OrderedQuantity 	  	  	 = coi.Ordered_Quantity,
 	  	  	 OrderedUnitOfMeasure 	  	 = coi.Ordered_UOM,
 	  	  	 DimensionX 	  	  	  	  	 = coi.Dimension_X,
 	  	  	 DimensionY 	  	  	  	  	 = coi.Dimension_Y,
 	  	  	 DimensionZ 	  	  	  	  	 = coi.Dimension_Z,
 	  	  	 DimensionA 	  	  	  	  	 = coi.Dimension_A,
 	  	  	 DimensionXTolerance 	  	 = coi.Dimension_X_Tolerance,
 	  	  	 DimensionYTolerance 	  	 = coi.Dimension_Y_Tolerance,
 	  	  	 DimensionZTolerance 	  	 = coi.Dimension_Z_Tolerance,
 	  	  	 DimensionATolerance 	  	 = coi.Dimension_A_Tolerance,
 	  	  	 ConsigneeName 	  	  	  	 = COALESCE(ccons.Consignee_Name, ccons.Customer_Name),
 	  	  	 ShipToCustomerName 	  	 = cship.Customer_Name,
 	  	  	 EndCustomerName 	  	  	 = cend.Customer_Name,
 	  	  	 CompleteDate 	  	  	  	 = coi.Complete_Date,
 	  	  	 COADate 	  	  	  	  	  	 = coi.COA_Date,
 	  	  	 ProductCode 	  	  	  	  	 = p.Prod_Code,
 	  	  	 CommentId 	  	  	  	  	 = coi.Comment_Id,
 	  	  	 OrderLineGeneral1 	  	  	 = coi.Order_Line_General_1,
 	  	  	 OrderLineGeneral2 	  	  	 = coi.Order_Line_General_2,
 	  	  	 OrderLineGeneral3 	  	  	 = coi.Order_Line_General_3,
 	  	  	 OrderLineGeneral4 	  	  	 = coi.Order_Line_General_4,
 	  	  	 OrderLineGeneral5 	  	  	 = coi.Order_Line_General_5,
 	  	  	 ExtendedInfo 	  	  	  	 = coi.Extended_Info,
 	  	  	 OrderId 	  	  	  	  	  	 = co.Order_Id
 	 FROM 	  	  	 Customer_Orders co
 	 INNER JOIN 	 Customer_Order_Line_Items coi 	 ON 	  	 coi.Order_Id = co.Order_Id
 	 INNER JOIN 	 Products p 	  	  	  	  	  	  	 ON 	  	 p.Prod_Id = coi.Prod_Id
 	 INNER JOIN 	 Customer cust 	  	  	  	  	  	 ON 	  	 cust.Customer_Id = co.Customer_Id
 	 LEFT 	 JOIN 	 Customer ccons 	  	  	  	  	  	 ON 	  	 ccons.Customer_Id = coi.Consignee_Id
 	 LEFT 	 JOIN 	 Customer cship 	  	  	  	  	  	 ON 	  	 cship.Customer_Id = coi.ShipTo_Id
 	 LEFT 	 JOIN 	 Customer cend 	  	  	  	  	  	 ON 	  	 cend.Customer_Id = coi.EndUser_Id
 	 LEFT 	 JOIN 	 Comments c 	  	  	  	  	  	  	 ON 	  	 c.Comment_Id = coi.Comment_Id'
EXECUTE (@SQL + @WhereClause)
DROP TABLE #Filter
