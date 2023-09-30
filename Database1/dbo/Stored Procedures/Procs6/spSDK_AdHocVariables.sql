CREATE PROCEDURE dbo.spSDK_AdHocVariables
 	 @sFilter 	  	  	  	  	 nVarChar(4000),
 	 @UserId 	  	  	  	  	 INT
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
 	  	  	 @OrderBy 	  	  	 nvarchar(100),
 	  	  	 @BracketCount 	 INT
SET 	 @sFilter 	  	 = COALESCE(@sFilter, '')
SET 	 @iFilterLen 	 = LEN(@sFilter)
SET 	 @iPos 	  	  	 = 1
SET 	 @iDiv 	  	  	 = 0
SET 	 @UserId 	  	 = COALESCE(@UserId, 0)
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
SET 	 @BracketCount 	 = 0
SET 	 @WhereClause = ''
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'v.Var_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'd.Dept_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'pl.PL_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'pu.PU_Desc' 
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'pug.PUG_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'v.Var_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'v.Eng_Units'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'v.Test_Name' 
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'ds.DS_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'calc.Calculation_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'et.ET_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'est.Event_SubType_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'dt.Data_Type_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'c.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'v.Extended_Info'
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
 	 IF LEN(@WhereClause) = 0 AND @WhereItem IS NOT NULL AND LEN(@WhereItem) <> 0
 	 BEGIN
 	  	 SET 	 @WhereClause 	 = 	 ' WHERE (' + @WhereItem
 	 END ELSE
 	 IF @WhereItem IS NOT NULL AND LEN(@WhereItem) <> 0
 	 BEGIN
 	  	 SET 	 @WhereClause = @WhereClause + COALESCE(@WhereItem, '')
 	 END
 	 FETCH WhileCursor INTO @FieldType, @FieldCode, @CompType, @Filter
END
PRINT 	 @WhereClause
SET 	 @iPos = 0
WHILE @iPos < @BracketCount
BEGIN
 	 SET 	 @WhereClause = @WhereClause + ' ) '
 	 SET 	 @iPos = @iPos + 1
END
CLOSE 	 WhileCursor
DEALLOCATE 	 WhileCursor
SET 	 @SQL = 
'SELECT 	 VariableId 	  	  	 = v.Var_Id,
 	  	  	 DepartmentName 	  	 = d.Dept_Desc,
 	  	  	 LineName  	  	  	 = pl.PL_Desc, 
 	  	  	 UnitName  	  	  	 = pu.PU_Desc, 
 	  	  	 UnitGroupName  	  	 = pug.PUG_Desc,
 	  	  	 VariableName  	  	 = v.Var_Desc, 
 	  	  	 EngineeringUnits 	 = v.Eng_Units, 
 	  	  	 TestName 	  	  	  	 = v.Test_Name,
 	  	  	 DataSource 	  	  	 = ds.DS_Desc,
 	  	  	 Calculation 	  	  	 = calc.Calculation_Name,     
 	  	  	 EventType 	  	  	 = et.ET_Desc,
 	  	  	 EventSubType 	  	 = est.Event_SubType_Desc,
 	  	  	 DataType 	  	  	  	 = dt.Data_Type_Desc,
 	  	  	 CommentId = v.Comment_Id,
 	  	  	 ExtendedInfo = v.Extended_Info,
 	  	  	 InputTag = v.Input_Tag,
 	  	  	 OutputTag = v.Output_Tag,
 	  	  	 LELTag = v.LEL_Tag,
 	  	  	 LRLTag = v.LRL_Tag,
 	  	  	 LULTag = v.LUL_Tag,
 	  	  	 LWLTag = v.LWL_Tag,
 	  	  	 UELTag = v.UEL_Tag,
 	  	  	 URLTag = v.URL_Tag,
 	  	  	 UULTag = v.UUL_Tag,
 	  	  	 UWLTag = v.UWL_Tag,
 	  	  	 TargetTag = v.Target_Tag,
 	  	  	 WriteGroupDSId = v.Write_Group_DS_Id
 	 FROM 	  	  	 Departments d
 	 INNER 	 JOIN 	 Prod_Lines pl 	  	  	 ON  	 pl.Dept_Id = d.Dept_Id
 	 INNER 	 JOIN 	 Prod_Units pu 	  	  	 ON  	 pu.PL_Id = pl.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.pu_id > 0
 	 INNER 	 JOIN 	 PU_Groups pug 	  	  	 ON 	  	 pu.PU_Id = pug.PU_Id
 	 INNER 	 JOIN 	 Variables v  	  	  	 ON 	  	 v.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.PUG_Id = pug.PUG_Id
 	 INNER 	 JOIN 	 Data_Source ds 	  	  	 ON 	  	 ds.DS_Id = v.DS_Id
 	 INNER 	 JOIN 	 Event_Types 	 et 	  	  	 ON 	  	 et.ET_Id = v.Event_Type
 	 INNER 	 JOIN 	 Data_Type dt 	  	  	 ON 	  	 dt.Data_Type_Id = v.Data_Type_Id
 	 LEFT 	 JOIN 	 Event_SubTypes est 	  	 ON 	  	 est.Event_Subtype_Id = v.Event_SubType_Id
 	 LEFT 	 JOIN 	 Calculations calc 	  	 ON 	  	 calc.Calculation_Id = v.Calculation_Id   
 	 LEFT 	 JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = ' + CONVERT(VARCHAR, @UserId) + ' ' + ' 
 	 LEFT 	 JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id    
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = ' + CONVERT(VARCHAR, @UserId) + ' ' + ' 
 	 LEFT 	 JOIN 	 User_Security vars 	  	 ON 	  	 pu.Group_Id = vars.Group_Id    
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = ' + CONVERT(VARCHAR, @UserId)
IF LEN(@WhereClause) = 0 OR @WhereClause IS NULL
BEGIN
 	 SET 	 @WhereClause = ' 
 	 WHERE (COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2)'
END ELSE
BEGIN
 	 SET 	 @WhereClause = @WhereClause + ' 
 	 AND (COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2) )'
END
SET 	 @OrderBy = '
 	 ORDER BY pl.PL_Desc, pu.PU_Order, pug.PUG_Order, v.PUG_Order'
--PRINT 	 (@SQL + ' ' + @WhereClause + ' ' + @OrderBy)
EXECUTE (@SQL + ' ' + @WhereClause + ' ' + @OrderBy)
DROP TABLE #Filter
