CREATE PROCEDURE dbo.spSDK_AdHocVariableAlarms
 	 @sFilter 	  	  	  	  	 VARCHAR(7000)
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
 	  	  	 @SQL 	  	  	  	 VARCHAR(7000),
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
 	  	  	  	  	  	  	  	  	  	 WHEN 	 1 	 THEN 	 'a.Alarm_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 2 	 THEN 	 'a.Alarm_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 3 	 THEN 	 'type.Alarm_Type_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 4 	 THEN 	 'atemp.AT_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 5 	 THEN 	 'asr.Alarm_SPC_Rule_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 6 	 THEN 	 'atemp.AP_Id'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 7 	 THEN 	 'd.Dept_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 8 	 THEN 	 'pl.PL_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 9 	 THEN 	 'pu.PU_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 10 	 THEN 	 'v.Var_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 11 	 THEN 	 'a.Start_Time'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 12 	 THEN 	 'a.End_Time'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 13 	 THEN 	 'a.Start_Result'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 14 	 THEN 	 'a.End_Result'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 15 	 THEN 	 'a.Min_Result'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 16 	 THEN 	 'a.Max_Result'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 17 	 THEN 	 'cr1.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 18 	 THEN 	 'cr2.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 19 	 THEN 	 'cr3.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 20 	 THEN 	 'cr4.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 21 	 THEN 	 'ar1.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 22 	 THEN 	 'ar2.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 23 	 THEN 	 'ar3.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 24 	 THEN 	 'ar4.Event_Reason_Name'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 25 	 THEN 	 'a.Research_Open_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 26 	 THEN 	 'a.Research_Close_Date'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 27 	 THEN 	 'rs.Research_Status_Desc'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 28 	 THEN 	 'ru.UserName'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 29 	 THEN 	 'a.Ack'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 30 	 THEN 	 'au.UserName'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 31 	 THEN 	 'a.Ack_On'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 32 	 THEN 	 'cc.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 33 	 THEN 	 'ac.Comment_Text'
 	  	  	  	  	  	  	  	  	  	 WHEN 	 34 	 THEN 	 'rc.Comment_Text'
 	  	  	  	  	  	  	  	  	 END
 	  	 IF 	 @FieldCode IN (1,6)
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
 	  	 IF 	 @FieldCode IN (11,12,25,26,31)
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
 	  	 END
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
'SELECT 	 VariableAlarmId 	  	 = a.Alarm_Id,
 	  	  	 AlarmName 	  	  	  	 = a.Alarm_Desc,
 	  	  	 AlarmType 	  	  	  	 = type.Alarm_Type_Desc,
 	  	  	 TemplateName 	  	  	 = atemp.AT_Desc,
 	  	  	 SPCRuleName 	  	  	  	 = asr.Alarm_SPC_Rule_Desc,
 	  	  	 Priority 	  	  	  	  	 = atemp.AP_Id,
 	  	  	 DepartmentName 	  	  	 = d.Dept_Desc,
 	  	  	 LineName 	  	  	  	  	 = pl.PL_Desc,
 	  	  	 UnitName 	  	  	  	  	 = pu.PU_Desc, 
 	  	  	 VariableName 	  	  	 = v.Var_Desc,
 	  	  	 StartTime 	  	  	  	 = a.Start_Time, 
 	  	  	 EndTime  	  	  	  	  	 = a.End_Time, 
 	  	  	 StartValue 	  	  	  	 = a.Start_Result,
 	  	  	 EndValue 	  	  	  	  	 = a.End_Result,
 	  	  	 MinValue 	  	  	  	  	 = a.Min_Result,
 	  	  	 MaxValue 	  	  	  	  	 = a.Max_Result,
 	  	  	 Cause1 	  	  	  	  	 = cr1.Event_Reason_Name, 
  	  	  	 Cause2 	  	  	  	  	 = cr2.Event_Reason_Name,
  	  	  	 Cause3 	  	  	  	  	 = cr3.Event_Reason_Name, 
  	  	  	 Cause4 	  	  	  	  	 = cr4.Event_Reason_Name,
  	  	  	 Action1 	  	  	  	  	 = ar1.Event_Reason_Name, 
  	  	  	 Action2 	  	  	  	  	 = ar2.Event_Reason_Name,
  	  	  	 Action3 	  	  	  	   	 = ar3.Event_Reason_Name, 
  	  	  	 Action4  	  	  	  	  	 = ar4.Event_Reason_Name,
  	  	  	 ResearchOpenDate 	  	 = a.Research_Open_Date,
  	  	  	 ResearchCloseDate 	  	 = a.Research_Close_Date,
  	  	  	 ResearchStatus 	  	  	 = rs.Research_Status_Desc,
  	  	  	 ResearchUserName 	  	 = ru.UserName,
 	  	  	 Acknowledged 	  	  	 = a.Ack,
 	  	  	 AcknowledgedBy 	  	  	 = au.UserName,
 	  	  	 AcknowledgedOn 	  	  	 = a.Ack_On,
  	  	  	 CauseCommentId 	  	  	 = a.Cause_Comment_Id,
  	  	  	 ActionCommentId 	  	 = a.Action_Comment_Id,
  	  	  	 ResearchCommentId 	  	 = a.Research_Comment_Id,
                        SignatureId                     = a.Signature_Id
 	 FROM 	  	  	 Alarms a
 	 INNER 	 JOIN 	 Alarm_Types type 	  	  	  	  	  	  	 ON 	  	 type.Alarm_Type_Id = a.Alarm_Type_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 type.Alarm_Type_Id IN (1, 2, 4)
 	 INNER JOIN 	 Alarm_Template_Var_Data atvd 	  	  	 ON 	  	 atvd.ATD_Id = a.ATD_Id
 	 INNER 	 JOIN 	 Alarm_Templates atemp 	  	  	  	  	 ON 	  	 atemp.AT_Id = atvd.AT_Id
 	 INNER 	 JOIN 	 Alarm_Priorities ap 	  	  	  	  	  	 ON 	  	 ap.AP_Id = atemp.AP_Id
 	 INNER JOIN 	 Variables v 	  	  	  	  	  	  	  	  	 ON 	  	 v.Var_Id = a.Key_Id
 	 INNER JOIN 	 Prod_Units pu 	  	  	  	  	  	  	  	 ON 	  	 v.PU_Id = pu.PU_Id
 	 INNER JOIN 	 Prod_Lines pl 	  	  	  	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	 INNER 	 JOIN 	 Departments d 	  	  	  	  	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	 LEFT 	 JOIN 	 Alarm_Template_SPC_Rule_Data atsrd 	 ON 	  	 atsrd.ATSRD_Id = a.ATSRD_Id
 	 LEFT 	 JOIN 	 Alarm_SPC_Rules asr 	  	  	  	  	  	 ON 	  	 asr.Alarm_SPC_Rule_Id = atsrd.Alarm_SPC_Rule_Id
 	 LEFT 	 JOIN 	 Event_Reasons cr1 	  	  	  	  	  	  	 ON 	  	 cr1.Event_Reason_Id = a.Cause1
 	 LEFT 	 JOIN 	 Event_Reasons cr2 	  	  	  	  	  	  	 ON 	  	 cr2.Event_Reason_Id = a.Cause2
 	 LEFT 	 JOIN 	 Event_Reasons cr3 	  	  	  	  	  	  	 ON 	  	 cr3.Event_Reason_Id = a.Cause3
 	 LEFT 	 JOIN 	 Event_Reasons cr4 	  	  	  	  	  	  	 ON 	  	 cr4.Event_Reason_Id = a.Cause4
 	 LEFT 	 JOIN 	 Event_Reasons ar1 	  	  	  	  	  	  	 ON 	  	 ar1.Event_Reason_Id = a.Action1
 	 LEFT 	 JOIN 	 Event_Reasons ar2 	  	  	  	  	  	  	 ON 	  	 ar2.Event_Reason_Id = a.Action2
 	 LEFT 	 JOIN 	 Event_Reasons ar3 	  	  	  	  	  	  	 ON 	  	 ar3.Event_Reason_Id = a.Action3
 	 LEFT 	 JOIN 	 Event_Reasons ar4 	  	  	  	  	  	  	 ON 	  	 ar4.Event_Reason_Id = a.Action4
 	 LEFT 	 JOIN 	 Research_Status rs 	  	  	  	  	  	 ON 	  	 rs.Research_Status_Id = a.Research_Status_Id
 	 LEFT 	 JOIN 	 Users au 	  	  	  	  	  	  	  	  	  	 ON 	  	 au.User_Id = a.Ack_By
 	 LEFT 	 JOIN 	 Users ru 	  	  	  	  	  	  	  	  	  	 ON 	  	 ru.User_Id = a.Research_User_Id
 	 LEFT 	 JOIN 	 Comments cc 	  	  	  	  	  	  	  	  	 ON 	  	 cc.Comment_Id = a.Cause_Comment_Id
 	 LEFT 	 JOIN 	 Comments ac 	  	  	  	  	  	  	  	  	 ON 	  	 ac.Comment_Id = a.Action_Comment_Id
 	 LEFT 	 JOIN 	 Comments rc 	  	  	  	  	  	  	  	  	 ON 	  	 rc.Comment_Id = a.Research_Comment_Id'
EXECUTE (@SQL + @WhereClause + ' ORDER BY a.Start_Time, a.Alarm_Id')
DROP TABLE #Filter
