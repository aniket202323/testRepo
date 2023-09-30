CREATE PROCEDURE dbo.spSDK_AdHocOrderLineSpecs
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
 	  	  	 @WhereClause 	 nVarChar(4000),
 	  	  	 @ItemStart 	  	 nvarchar(1000),
 	  	  	 @ItemEnd 	  	  	 nvarchar(1000),
 	  	  	 @WhereItem 	  	 nvarchar(1000),
 	  	  	 @SQL 	  	  	  	 nVarChar(4000),
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'ols.Order_Spec_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'c.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'o.Plant_Order_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'oli.Line_Item_Number'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'ols.Spec_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'dt.Data_Type_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'ols.Spec_Precision'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'ols.Is_Active'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'ols.L_Limit'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'ols.Target'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'ols.U_Limit'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'o.Order_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'oli.Order_Line_Id'
 	  	  	  	  	  	  	  	  	 END
 	  	 IF 	 @FieldCode IN (1,4,7,8)
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
 	  	 SET 	 @WhereClause = ' WHERE '
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
'SELECT 	 OrderLineSpecId 	 = ols.Order_Spec_Id,
 	  	  	 CustomerName 	  	 = c.Customer_Name,
 	  	  	 PlantOrderNumber 	 = o.Plant_Order_Number,
 	  	  	 LineItemNumber 	  	 = oli.Line_Item_Number,
 	  	  	 SpecName 	  	  	  	 = ols.Spec_Desc,
 	  	  	 DataType 	  	  	  	 = dt.Data_Type_Desc,
 	  	  	 SpecPrecision 	  	 = COALESCE(ols.Spec_Precision, 0),
 	  	  	 LowerLimit 	  	  	 = CASE
 	  	  	  	  	  	  	  	  	    	  	 WHEN 	 ISNUMERIC(ols.L_Limit) = 1 	 THEN 	 LTRIM(STR(ols.L_Limit, 50, COALESCE(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	    	  	 ELSE 	 ols.L_Limit
 	  	  	  	  	  	  	  	  	   END,
 	  	  	 Target 	  	  	  	 = CASE
 	  	  	  	  	  	  	  	  	    	  	 WHEN 	 ISNUMERIC(ols.Target) = 1 	 THEN 	 LTRIM(STR(ols.Target, 50, COALESCE(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	    	  	 ELSE 	 ols.Target
 	  	  	  	  	  	  	  	  	   END,
 	  	  	 UpperLimit 	  	  	 = CASE
 	  	  	  	  	  	  	  	  	    	  	 WHEN 	 ISNUMERIC(ols.U_Limit) = 1 	 THEN 	 LTRIM(STR(ols.U_Limit, 50, COALESCE(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	    	  	 ELSE 	 ols.U_Limit
 	  	  	  	  	  	  	  	  	   END,
 	  	  	 IsActive 	  	  	  	 = ols.Is_Active,
 	  	  	 OrderId 	  	  	  	 = o.Order_Id,
 	  	  	 OrderLineId 	  	  	 = oli.Order_Line_Id
 	 FROM 	  	  	 Customer_Order_Line_Specs ols
 	 INNER 	 JOIN 	 Data_Type dt 	  	  	  	  	  	  	 ON ols.Data_Type_Id = dt.Data_Type_Id
 	 INNER 	 JOIN 	 Customer_Order_Line_Items oli 	  	 ON 	 oli.Order_Line_Id = ols.Order_Line_Id
 	 INNER 	 JOIN 	 Customer_Orders o 	  	  	  	  	  	 ON 	 o.Order_Id = oli.Order_Id
 	 INNER 	 JOIN 	 Customer c 	  	  	  	  	  	  	  	 ON 	 c.Customer_Id = o.Customer_Id'
EXECUTE (@SQL + @WhereClause + ' ORDER BY c.Customer_Name, o.Plant_Order_Number, oli.Line_Item_Number, ols.Spec_Desc')
DROP TABLE #Filter
