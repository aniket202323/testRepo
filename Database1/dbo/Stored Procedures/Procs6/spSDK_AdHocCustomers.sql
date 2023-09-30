CREATE PROCEDURE dbo.spSDK_AdHocCustomers
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'c.Customer_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'ct.Customer_Type_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'c.Customer_Code'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'c.Customer_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'c.Consignee_Code'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'c.Consignee_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'c.Is_Active'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'c.Contact_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'c.Contact_Phone' 
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'c.Address_1'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'c.Address_2'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'c.Address_3'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'c.Address_4'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'c.City' 
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'c.County'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 16 	 THEN 	 'c.State'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 17 	 THEN 	 'c.Country'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 18 	 THEN 	 'c.ZIP' 
 	  	  	  	  	  	  	  	  	  	 WHEN 	 19 	 THEN 	 'c.Customer_General_1'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 20 	 THEN 	 'c.Customer_General_2'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 21 	 THEN 	 'c.Customer_General_3'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 22 	 THEN 	 'c.Customer_General_4'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 23 	 THEN 	 'c.Customer_General_5'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 24 	 THEN 	 'c.Extended_Info'
 	  	  	  	  	  	  	  	  	 END
 	  	 IF 	 @FieldCode <> 1
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
 	  	 END ELSE
 	  	 IF 	 @FieldCode = 1
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
'SELECT 	 CustomerId 	  	  	 = c.Customer_Id,
 	  	  	 CustomerCode 	  	 = c.Customer_Code,
 	  	  	 CustomerName 	  	 = c.Customer_Name,
 	  	  	 ConsigneeCode 	  	 = c.Consignee_Code,
 	  	  	 ConsigneeName 	  	 = c.Consignee_Name,
 	  	  	 CustomerType 	  	 = ct.Customer_Type_Desc,
 	  	  	 IsActive  	  	  	 = c.Is_Active,
 	  	  	 ContactName 	  	  	 = c.Contact_Name,
 	  	  	 ContactPhone 	  	 = c.Contact_Phone,
 	  	  	 Address1 	  	  	  	 = c.Address_1,
 	  	  	 Address2 	  	  	  	 = c.Address_2,
 	  	  	 Address3 	  	  	  	 = c.Address_3,
 	  	  	 Address4 	  	  	  	 = c.Address_4,
 	  	  	 City 	  	  	  	  	 = c.City,
 	  	  	 County 	  	  	  	 = c.County,
 	  	  	 State 	  	  	  	  	 = c.State,
 	  	  	 Country 	  	  	  	 = c.Country,
 	  	  	 ZIP 	  	  	  	  	 = c.ZIP,
 	  	  	 CustomerGeneral1 	 = c.Customer_General_1,
 	  	  	 CustomerGeneral2 	 = c.Customer_General_2,
 	  	  	 CustomerGeneral3 	 = c.Customer_General_3,
 	  	  	 CustomerGeneral4 	 = c.Customer_General_4,
 	  	  	 CustomerGeneral5 	 = c.Customer_General_5,
 	  	  	 ExtendedInfo 	  	 = c.Extended_Info
 	 FROM 	  	  	 Customer c
 	 INNER JOIN 	 Customer_Types ct 	 ON 	 ct.Customer_Type_Id = c.Customer_Type'
EXECUTE (@SQL + @WhereClause)
DROP TABLE #Filter
