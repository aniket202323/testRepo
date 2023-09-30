CREATE PROCEDURE dbo.spSDK_AdHocEventConfigs
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
CREATE TABLE #Events (
EventConfigurationId 	 INT,
DepartmentName 	  	 nvarchar(50),
LineName 	  	 nvarchar(50),
UnitName 	  	 nvarchar(50),
InputName 	  	 nvarchar(50),
EventType 	  	 nvarchar(50),
EventSubType 	  	 nvarchar(50),
ExtendedInfo 	  	 nvarchar(255),
Exclusions 	  	 nvarchar(50),
ModelNumber 	  	 INT,
ModelName 	  	 nvarchar(255),
ModelIsActive 	  	 tinyint,
CommentId 	  	 INT,
ESignatureLevel 	  	 INT,
ETId 	  	  	 INT
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'ec.EC_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'd.Dept_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'pl.PL_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'pu.PU_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'pei.Input_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'et.ET_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'es.Event_Subtype_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'ec.Extended_Info'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'ec.Exclusions'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'edm.Model_Num'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'edm.Model_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'ec.Is_Active'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'c.Comment_Text'
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
'Insert into #Events
SELECT 	 EventConfigurationId 	 = ec.EC_Id,
 	  	  	 DepartmentName 	  	  	 = d.Dept_Desc,
 	  	  	 LineName 	  	  	  	  	 = pl.PL_Desc,
 	  	  	 UnitName 	  	  	  	  	 = pu.PU_Desc, 
 	  	  	 InputName 	  	  	  	 = pei.Input_Name,
 	  	  	 EventType 	  	  	  	 = et.ET_Desc,
 	  	  	 EventSubType 	  	  	 = es.Event_Subtype_Desc,
 	  	  	 ExtendedInfo 	  	  	 = ec.Extended_Info,
 	  	  	 Exclusions 	  	  	  	 = ec.Exclusions,
 	  	  	 ModelNumber 	  	  	  	 = edm.Model_Num,
 	  	  	 ModelName 	  	  	  	 = edm.Model_Desc,
 	  	  	 ModelIsActive 	  	  	 = ec.Is_Active,
 	  	  	 CommentId 	  	  	  	 = ec.Comment_Id,
                        ESignatureLevel                 = NULL,
                        ETId                            = et.ET_Id
 	 FROM 	  	  	 Event_Configuration ec
 	 LEFT 	 JOIN 	 PrdExec_Inputs pei 	  	 ON 	 pei.PEI_Id = ec.PEI_Id
 	 INNER 	 JOIN 	 Prod_Units pu 	  	  	  	 ON 	 pu.PU_Id = ec.PU_Id
 	 INNER JOIN 	 Prod_Lines pl 	  	  	  	 ON 	 pl.PL_Id = pu.PL_Id
 	 INNER 	 JOIN 	 Departments d 	  	  	  	 ON 	 d.Dept_Id = pl.Dept_Id
 	 INNER 	 JOIN 	 Event_Types et 	  	  	  	 ON 	 et.ET_Id = ec.ET_Id
 	 LEFT 	 JOIN 	 Event_SubTypes es 	  	  	 ON es.Event_Subtype_Id = ec.Event_Subtype_Id
 	 LEFT 	 JOIN 	 ED_Models edm 	  	  	  	 ON 	 edm.ED_Model_Id = ec.ED_Model_Id
 	 LEFT 	 JOIN 	 Comments c 	  	  	  	  	 ON 	 c.Comment_Id = ec.Comment_Id'
EXECUTE (@SQL + @WhereClause + ' ORDER BY pl.PL_Desc, pu.PU_Order, pu.PU_Desc, ec.ET_Id')
--Update ESignature Level for User-Defined Events
Update #Events set ESignatureLevel = es.ESignature_Level
  From #Events
  Join Event_Configuration ec on ec.EC_Id = #Events.EventConfigurationId
  Join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
    Where #Events.ETId = 14
--Update ESignature Level for Downtime and Waste Events
Update #Events set ESignatureLevel = ec.ESignature_Level
  From #Events
  Join Event_Configuration ec on ec.EC_Id = #Events.EventConfigurationId
    Where #Events.ETId in (2,3)
Select EventConfigurationId, DepartmentName, LineName,
 	 UnitName, InputName, EventType, 	 EventSubType,
 	 ExtendedInfo, Exclusions, ModelNumber,ModelName,
 	 ModelIsActive, CommentId, ESignatureLevel
from #Events
DROP TABLE #Filter
DROP TABLE #Events
