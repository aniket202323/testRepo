CREATE PROCEDURE dbo.spSDK_AdHocUDEvents
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'ud.UDE_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'd.Dept_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'pl.PL_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'pu.PU_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'ud.UDE_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'es.Event_Subtype_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'ud.Start_Time'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'ud.End_Time'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'ud.Ack'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'au.UserName'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'ud.Ack_On'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'cr1.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'cr2.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'cr3.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'cr4.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 16 	 THEN 	 'ar1.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 17 	 THEN 	 'ar2.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 18 	 THEN 	 'ar3.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 19 	 THEN 	 'ar4.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 20 	 THEN 	 'ud.Research_Open_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 21 	 THEN 	 'ud.Research_Close_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 22 	 THEN 	 'rs.Research_Status_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 23 	 THEN 	 'ru.UserName'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 24 	 THEN 	 'c.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 25 	 THEN 	 'cc.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 26 	 THEN 	 'ac.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 27 	 THEN 	 'rc.Comment_Text'
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
 	  	 IF @FieldCode IN (7,8,11,20,21)
 	  	 BEGIN
 	  	  	 SET 	 @ItemEnd = 	 CASE 	 @CompType 
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 ' = ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 ' <> ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 NULL
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 ' > ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 ' < ''' + CONVERT(nvarchar(100), @Filter) + ''''
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
'SELECT 	 UserDefinedEventId 	 = ud.UDE_Id,
 	  	  	 DepartmentName 	  	  	 = d.Dept_Desc,
 	  	  	 LineName 	  	  	  	  	 = pl.PL_Desc,
 	  	  	 UnitName 	  	  	  	  	 = pu.PU_Desc, 
 	  	  	 EventName 	  	  	  	 = ud.UDE_Desc, 
 	  	  	 EventSubType 	  	  	 = es.Event_Subtype_Desc,
 	  	  	 StartTime 	  	  	  	 = ud.Start_Time, 
 	  	  	 EndTime  	  	  	  	  	 = ud.End_Time, 
 	  	  	 Cause1 	  	  	  	  	 = cr1.Event_Reason_Name, 
  	  	  	 Cause2 	  	  	  	  	 = cr2.Event_Reason_Name,
  	  	  	 Cause3 	  	  	  	  	 = cr3.Event_Reason_Name, 
  	  	  	 Cause4 	  	  	  	  	 = cr4.Event_Reason_Name,
  	  	  	 Action1 	  	  	  	  	 = ar1.Event_Reason_Name, 
  	  	  	 Action2 	  	  	  	  	 = ar2.Event_Reason_Name,
  	  	  	 Action3 	  	  	  	   	 = ar3.Event_Reason_Name, 
  	  	  	 Action4  	  	  	  	  	 = ar4.Event_Reason_Name,
  	  	  	 ResearchOpenDate 	  	 = ud.Research_Open_Date,
  	  	  	 ResearchCloseDate 	  	 = ud.Research_Close_Date,
  	  	  	 ResearchStatus 	  	  	 = rs.Research_Status_Desc,
  	  	  	 ResearchUser 	  	  	 = ru.UserName,
 	  	  	 Acknowledged 	  	  	 = ud.Ack,
 	  	  	 AcknowledgedBy 	  	  	 = au.UserName,
 	  	  	 AcknowledgedOn 	  	  	 = ud.Ack_On,
 	  	  	 CommentId 	  	  	  	 = ud.Comment_Id,
  	  	  	 CauseCommentId 	  	  	 = ud.Cause_Comment_Id,
  	  	  	 ActionCommentId 	  	 = ud.Action_Comment_Id,
  	  	  	 ResearchCommentId 	  	 = ud.Research_Comment_Id,
                        SignatureId                     = ud.Signature_Id
 	 FROM 	  	  	 User_Defined_Events ud 
 	 INNER JOIN 	 Prod_Units pu 	  	  	  	  	 ON 	  	 pu.PU_Id = ud.PU_Id 
 	 INNER JOIN 	 Prod_Lines pl 	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	 INNER 	 JOIN 	 Departments d 	  	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	 INNER JOIN  	 Event_Configuration ec 	  	 ON 	  	 ec.PU_Id = ud.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ec.ET_Id = 14
 	 INNER JOIN 	 Event_SubTypes es 	  	  	  	 ON 	  	 ec.Event_SubType_Id = es.Event_SubType_Id 	 
     AND es.event_subtype_id = ud.Event_Subtype_Id
 	 LEFT 	 JOIN 	 Event_Reasons cr1 	  	  	  	 ON 	  	 cr1.Event_Reason_Id = ud.Cause1
 	 LEFT 	 JOIN 	 Event_Reasons cr2 	  	  	  	 ON 	  	 cr2.Event_Reason_Id = ud.Cause2
 	 LEFT 	 JOIN 	 Event_Reasons cr3 	  	  	  	 ON 	  	 cr3.Event_Reason_Id = ud.Cause3
 	 LEFT 	 JOIN 	 Event_Reasons cr4 	  	  	  	 ON 	  	 cr4.Event_Reason_Id = ud.Cause4
 	 LEFT 	 JOIN 	 Event_Reasons ar1 	  	  	  	 ON 	  	 ar1.Event_Reason_Id = ud.Action1
 	 LEFT 	 JOIN 	 Event_Reasons ar2 	  	  	  	 ON 	  	 ar2.Event_Reason_Id = ud.Action2
 	 LEFT 	 JOIN 	 Event_Reasons ar3 	  	  	  	 ON 	  	 ar3.Event_Reason_Id = ud.Action3
 	 LEFT 	 JOIN 	 Event_Reasons ar4 	  	  	  	 ON 	  	 ar4.Event_Reason_Id = ud.Action4
 	 LEFT 	 JOIN 	 Research_Status rs 	  	  	 ON 	  	 rs.Research_Status_Id = ud.Research_Status_Id
 	 LEFT 	 JOIN 	 Users au 	  	  	  	  	  	  	 ON 	  	 au.User_Id = ud.Ack_By
 	 LEFT 	 JOIN 	 Users ru 	  	  	  	  	  	  	 ON 	  	 ru.User_Id = ud.Research_User_Id
 	 LEFT 	 JOIN 	 Comments c 	  	  	  	  	  	 ON 	  	 c.Comment_Id = ud.Comment_Id
 	 LEFT 	 JOIN 	 Comments cc 	  	  	  	  	  	 ON 	  	 cc.Comment_Id = ud.Cause_Comment_Id
 	 LEFT 	 JOIN 	 Comments ac 	  	  	  	  	  	 ON 	  	 ac.Comment_Id = ud.Action_Comment_Id
 	 LEFT 	 JOIN 	 Comments rc 	  	  	  	  	  	 ON 	  	 rc.Comment_Id = ud.Research_Comment_Id'
EXECUTE (@SQL + @WhereClause + ' ORDER BY ud.Start_Time, ud.UDE_Id')
DROP TABLE #Filter
