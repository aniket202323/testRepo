/*
Stored Procedure: 	 spSDK_AdHocProductionEvents
Author: 	  	  	 Matthew Wells (GE)
Date Created: 	  	 2005-03-13
SP Type: 	  	  	 SDK
Editor Tab Spacing: 	 5
Description:
============
This stored procedure is called from ProductionEvents.RunQuery
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
2005-03-13 	 MKW 	 Added comments
 	  	  	  	 Removed temp table
 	  	  	  	 Removed cursor
 	  	  	  	 Replace SET statements with SELECT
2005-11-23  JJG Added call to spSDK_AdHocProductionEvents_SubEventId
*/
CREATE PROCEDURE dbo.spSDK_AdHocProductionEvents
  	  @sFilter  	    	    	    	    	  nVarChar(4000)
AS 
-- Begin SP
/*************************************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	  	 *
*************************************************************************************/
--CREATE #Filter ( 	  	 -- MKW 2005-3-13
--  	  Filter_Id  	    	    	    	  INT IDENTITY(1,1),
--  	  Filter_Type  	    	    	    	  INT,
--  	  Field_Code  	    	    	    	  INT,
--  	  Operator  	    	    	    	    	  INT,
-- 	  Filter  	    	    	    	    	  nvarchar(100)
--)
DECLARE 	 
    @EventId  INT, 
    @iPos 	  	  	 INT,
 	  	 @iDiv 	  	  	 INT,
 	  	 @iPos2 	  	  	 INT,
 	  	 @iDiv2 	  	  	 INT,
 	  	 @sValue 	  	  	 nvarchar(50),
 	  	 @iFilterLen 	  	 INT,
 	  	 @FieldType 	  	 nvarchar(2),
 	  	 @FieldCode 	  	 nvarchar(2),
 	  	 @CompType 	  	  	 nvarchar(2),
 	  	 @Filter 	  	  	 nvarchar(100),
 	  	 @WhereClause 	  	 nVarChar(4000),
 	  	 @ItemStart 	  	 nvarchar(1000),
 	  	 @ItemEnd 	  	  	 nvarchar(1000),
 	  	 @WhereItem 	  	 nvarchar(1000),
 	  	 @SQL 	  	  	  	 nVarChar(4000),
 	  	 @BracketCount 	  	 INT
-- This is a frequent call at many sites so to make it faster and allow SQL Server to build
-- an execution plan, we will just call a sub sp directly then exit.
If SUBSTRING(@sFilter,1,7) = '|1~1~1~'
  BEGIN
    Select @EventId = CONVERT(INT, REPLACE(@sFilter,'|1~1~1~',''))
    execute dbo.spSDK_AdHocProductionEvents_SubEventId @EventId
    RETURN
  END
/*************************************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	  	 *
*************************************************************************************/
SELECT 	 @sFilter 	  	 = COALESCE(@sFilter, ''),
 	  	 @iFilterLen 	 = LEN(@sFilter),
 	  	 @iPos 	  	 = 1,
 	  	 @iDiv 	  	 = 0,
 	  	 @WhereClause 	 = '',
 	  	 @BracketCount 	 = 0
/*************************************************************************************
* 	  	  	  	  	  	  	 Parse Argument 	  	  	  	  	  	  	  	 *
*************************************************************************************/
WHILE  	  @iPos < @iFilterLen
 	 BEGIN
 	 SELECT  	  @iDiv = CHARINDEX('|', @sFilter, @iPos)
 	 IF @iDiv = 0
 	  	 BEGIN
 	  	 SELECT @iDiv = @iFilterLen + 1
 	  	 END
 	 
 	 IF @iDiv > @iPos
 	  	 BEGIN
 	  	 SELECT  	  @sValue = NULL
 	  	 SELECT  	  @sValue = SUBSTRING(@sFilter, @iPos, @iDiv - @iPos)
 	  	 
 	  	 -- Get the inner Value
 	  	 SELECT  	  @iPos2 = 1
 	  	 SELECT  	  @iDiv2 = 0
 	  	 
 	  	 SELECT  	  @iDiv2 = CHARINDEX('~', @sValue, @iPos2)
 	  	 
 	  	 SELECT  	  @FieldType  	  = NULL
 	  	 SELECT  	  @FieldType  	  = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SELECT  	  @FieldType  	  = CASE WHEN @FieldType = '' THEN NULL ELSE @FieldType END
 	  	 
 	  	 SELECT  	  @iPos2  	  = @iDiv2 + 1
 	  	 SELECT  	  @iDiv2  	  = CHARINDEX('~', @sValue, @iPos2)
 	  	 
 	  	 SELECT  	  @FieldCode  	  = NULL
 	  	 SELECT  	  @FieldCode  	  = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SELECT  	  @FieldCode  	  = CASE WHEN @FieldCode = '' THEN NULL ELSE @FieldCode END
 	  	 
 	  	 SELECT  	  @iPos2  	  = @iDiv2 + 1
 	  	 SELECT  	  @iDiv2  	  = CHARINDEX('~', @sValue, @iPos2)
 	  	 
 	  	 SELECT  	  @CompType  	  = NULL
 	  	 SELECT  	  @CompType  	  = SUBSTRING(@sValue, @iPos2, @iDiv2 - @iPos2)
 	  	 SELECT  	  @CompType  	  = CASE WHEN @CompType = '' THEN NULL ELSE @CompType END
 	  	 
 	  	 SELECT  	  @iPos2  	  = @iDiv2 + 1
 	  	 
 	  	 SELECT  	  @Filter  	    	  = NULL
 	  	 SELECT  	  @Filter  	    	  = SUBSTRING(@sValue, @iPos2, LEN(@sValue) + 1)
 	  	 SELECT  	  @Filter  	    	  = CASE WHEN @Filter = '' THEN NULL ELSE @Filter END
 	  	 
 	  	 IF ISNUMERIC(@FieldType) = 0
 	  	  	 BEGIN
 	  	  	 SELECT @FieldType = NULL
 	  	  	 END
 	  	 IF ISNUMERIC(@FieldCode) = 0
 	  	  	 BEGIN
 	  	  	 SELECT @FieldCode = NULL
 	  	  	 END
 	  	 IF ISNUMERIC(@CompType) = 0
 	  	  	 BEGIN
 	  	  	 SELECT @CompType = NULL
 	  	  	 END
  	    	  
 	  	 /***************************************************************************
 	  	 * 	  	  	  	  	  	 Build WHERE Clause 	  	  	  	  	  	 *
 	  	 ***************************************************************************/
-- MKW 2005-03-13
--  	    	  INSERT  	  INTO  	  #Filter (Filter_Type, Field_Code, Operator, Filter  	  ) 	 
--  	    	    	  VALUES  	  (  	  @FieldType, @FieldCode, @CompType, @Filter  	  )
 	  	 -- MKW - Moved the following from within the cursor to here
 	  	 SELECT  	  @WhereItem = ''
 	  	 IF @FieldType = 1
 	  	  	 BEGIN
 	  	  	 SELECT @ItemStart = CASE @FieldCode 
   	    	    	    	    	    	    	    	  WHEN  	  1  	  THEN  	  'e.Event_Id'
   	    	    	    	    	    	    	    	  WHEN  	  2  	  THEN  	  'pl.PL_Desc'
   	    	    	    	    	    	    	    	  WHEN  	  3  	  THEN  	  'pu.PU_Desc' 
   	    	    	    	    	    	    	    	  WHEN  	  4  	  THEN  	  'e.Event_Num'
   	    	    	    	    	    	    	    	  WHEN  	  5  	  THEN  	  'es.Event_Subtype_Desc'
   	    	    	    	    	    	    	    	  WHEN  	  6  	  THEN  	  'ps.ProdStatus_Desc'
   	    	    	    	    	    	    	    	  WHEN  	  7  	  THEN  	  'p1.Prod_Code'
   	    	    	    	    	    	    	    	  WHEN  	  8  	  THEN  	  'p2.Prod_Code' 
   	    	    	    	    	    	    	    	  WHEN  	  9  	  THEN  	  'pp.Process_Order'
   	    	    	    	    	    	    	    	  WHEN  	  10  	  THEN  	  'e.Start_Time'
   	    	    	    	    	    	    	    	  WHEN  	  11  	  THEN  	  'e.TimeStamp'
   	    	    	    	    	    	    	    	  WHEN  	  12  	  THEN  	  'ed.Initial_Dimension_X'
   	    	    	    	    	    	    	    	  WHEN  	  13  	  THEN  	  'ed.Initial_Dimension_Y' 
   	    	    	    	    	    	    	    	  WHEN  	  14  	  THEN  	  'ed.Initial_Dimension_Z'
   	    	    	    	    	    	    	    	  WHEN  	  15  	  THEN  	  'ed.Initial_Dimension_A'
   	    	    	    	    	    	    	    	  WHEN  	  16  	  THEN  	  'ed.Final_Dimension_X'
   	    	    	    	    	    	    	    	  WHEN  	  17  	  THEN  	  'ed.Final_Dimension_Y' 
   	    	    	    	    	    	    	    	  WHEN  	  18  	  THEN  	  'ed.Final_Dimension_Z'
   	    	    	    	    	    	    	    	  WHEN  	  19  	  THEN  	  'ed.Final_Dimension_A'
   	    	    	    	    	    	    	    	  WHEN  	  20  	  THEN  	  'e.Extended_Info'
   	    	    	    	    	    	    	    	  WHEN  	  21  	  THEN  	  'c.Comment_Text'
 	    	    	    	    	    	    	    	  END
 	  	  	 IF  	  @FieldCode <> 1
 	  	  	  	 BEGIN
 	  	  	    	 SELECT @ItemEnd = CASE @CompType 
 	  	  	  	  	  	  	  	 WHEN  	  1  	  THEN  	  ' = ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	 WHEN  	  2  	  THEN  	  ' <> ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	 WHEN  	  3  	  THEN  	  ' LIKE ''' + REPLACE(REPLACE(REPLACE(COALESCE(@Filter, '%'), '*', '%'), '?', '_'), '[', '[[]') + ''''
 	  	  	  	  	  	  	  	 WHEN  	  4  	  THEN  	  ' > ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	 WHEN  	  5  	  THEN  	  ' < ''' + CONVERT(nvarchar(100), @Filter) + ''''
 	  	  	  	  	  	  	  	 WHEN  	  6  	  THEN  	  ' IS NULL '
 	  	  	  	  	  	  	  	 WHEN  	  7  	  THEN  	  ' IS NOT NULL '
 	  	  	  	  	  	  	  	 END
 	  	  	  	 END
 	  	  	 ELSE IF  	  @FieldCode = 1
 	  	  	  	 BEGIN
 	  	  	  	 SELECT @ItemEnd = CASE  	  @CompType
 	  	  	  	  	  	  	  	 WHEN  	  1  	  THEN  	  ' = ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	 WHEN  	  2  	  THEN  	  ' <> ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	 WHEN  	  3  	  THEN  	  NULL
 	  	  	  	  	  	  	  	 WHEN  	  4  	  THEN  	  '> ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	 WHEN  	  5  	  THEN  	  '< ' + CONVERT(nvarchar(100), @Filter)
 	  	  	  	  	  	  	  	 WHEN  	  6  	  THEN  	  ' IS NULL '
 	  	  	  	  	  	  	  	 WHEN  	  7  	  THEN  	  ' IS NOT NULL '
 	  	  	  	  	  	  	  	 END
 	  	  	  	 END
 	  	 
 	  	  	 SELECT  	  @WhereItem = ''
 	  	  	 SELECT  	  @WhereItem = CONVERT(nvarchar(1000), @ItemStart) + ' ' + CONVERT(nvarchar(1000), @ItemEnd)
 	  	  	 END
 	  	 ELSE IF @FieldType = 2
 	  	  	 BEGIN
 	  	  	 IF  	  @WhereClause = ''
 	  	  	  	 BEGIN
 	  	  	    	 SELECT  	  @WhereItem = ''
 	  	  	  	 END 
 	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	 SELECT @WhereItem = CASE  	  @FieldCode
 	  	  	  	  	  	  	  	  	 WHEN  	  1  	  THEN  	  ' AND '
 	  	  	  	  	  	  	  	  	 WHEN  	  2  	  THEN  	  ' OR '
 	  	  	  	  	  	  	  	  	 END
 	  	  	   	 END
 	  	  	 END 
 	  	 ELSE IF @FieldType = 3
 	  	  	 BEGIN
 	  	  	 IF @FieldCode = 1
 	  	  	  	 BEGIN
 	  	  	  	 SELECT  	  @WhereItem  	  = ' ( '
 	  	  	  	 SELECT  	  @BracketCount  	  = @BracketCount + 1
 	  	  	  	 END
 	  	  	 ELSE IF @FieldCode = 2
 	  	  	  	 BEGIN
 	  	  	  	 SELECT  	  @WhereItem  	  = ' ) '
 	  	  	  	 SELECT  	  @BracketCount  	  = @BracketCount - 1
 	  	  	  	 END  	    	  
 	  	  	 END
 	  	 IF @WhereClause = '' AND @WhereItem <> ''
 	  	  	 BEGIN
 	  	  	 SELECT  	  @WhereClause = ' WHERE '
 	  	  	 END
 	  	 
 	  	 SELECT  	  @WhereClause = @WhereClause + COALESCE(@WhereItem, '')
  	   	 END
 	 SELECT  	  @iPos = @iDiv + 1
 	 END
--DECLARE WhileCursor CURSOR FOR
--  	  SELECT  	  Filter_Type, Field_Code, Operator, Filter
--  	    	  FROM  	  #Filter
--  	    	  ORDER BY Filter_Id
--OPEN  	  WhileCursor
--FETCH WhileCursor INTO @FieldType, @FieldCode, @CompType, @Filter
--WHILE @@FETCH_STATUS = 0
-- MKW - Moved the code from here to within the loop that parses the argument string
--  	  FETCH WhileCursor INTO @FieldType, @FieldCode, @CompType, @Filter
--END
SELECT  	  @iPos = 0
WHILE @iPos < @BracketCount
 	 BEGIN
  	 SELECT  	  @WhereClause = @WhereClause + ' ) '
 	 SELECT  	  @iPos = @iPos + 1
 	 END
--CLOSE  	  WhileCursor
--DEALLOCATE  	  WhileCursor
SELECT  	  @SQL = 
'SELECT 	 ProductionEventId 	 = e.Event_Id,
 	  	 LineName 	  	  	 = pl.PL_Desc,
 	  	 UnitName 	  	  	 = pu.PU_Desc, 
 	  	 EventName 	  	  	 = e.Event_Num, 
 	  	 EventType 	  	  	 = es.Event_Subtype_Desc,
 	  	 EventStatus 	  	  	 = ps.ProdStatus_Desc, 
 	  	 TestingStatus 	  	 = ''Unknown'',
 	  	 OriginalProduct 	  	 = p1.Prod_Code, 
 	  	 AppliedProduct 	  	 = p2.Prod_Code, 
 	  	 ProcessOrder 	  	 = pp.Process_Order,
 	  	 StartTime 	  	  	 = IsNull(e.Start_Time, e.TimeStamp), 
 	  	 EndTime 	  	  	  	 = e.TimeStamp, 
 	  	 InitialDimensionX 	 = ed.Initial_Dimension_X, 
 	  	 InitialDimensionY 	 = ed.Initial_Dimension_Y, 
 	  	 InitialDimensionZ 	 = ed.Initial_Dimension_Z,
 	  	 InitialDimensionA 	 = ed.Initial_Dimension_A,
 	  	 FinalDimensionX 	 = ed.Final_Dimension_X, 
 	  	 FinalDimensionY 	 = ed.Final_Dimension_Y, 
 	  	 FinalDimensionZ 	 = ed.Final_Dimension_Z,
 	  	 FinalDimensionA 	 = ed.Final_Dimension_A,
 	  	 CommentId 	  	  	 = e.Comment_Id,
 	  	 ExtendedInfo 	  	 = e.Extended_Info,
                SignatureId             = e.Signature_Id
FROM Events e 
 	 INNER JOIN Production_Status ps 	  	 ON 	 ps.ProdStatus_Id = e.Event_Status 
 	 INNER JOIN Production_Starts s 	  	 ON 	 s.PU_Id = e.PU_Id
 	  	  	  	  	  	  	  	  	  	 AND s.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	 AND (s.End_Time > e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	 OR s.End_Time Is Null) 
 	 INNER JOIN Products p1 	  	  	  	 ON 	 p1.Prod_Id = s.Prod_Id 
 	 LEFT JOIN Products p2 	  	  	  	 ON 	 p2.Prod_Id = e.Applied_Product 
 	 INNER JOIN Prod_Units pu 	  	  	  	 ON 	 pu.pu_id = e.pu_id 
 	 INNER JOIN Prod_Lines pl  	  	  	 ON 	 pl.pl_id = pu.pl_id
 	 INNER JOIN Event_Configuration ec 	  	 ON 	 ec.PU_Id = pu.PU_Id
 	  	    	    	    	    	    	    	  	    	 AND ec.ET_Id = 1
 	 INNER JOIN Event_SubTypes es 	  	  	 ON 	 ec.Event_SubType_Id = es.Event_SubType_Id  	  
 	 LEFT JOIN Production_Plan_Starts pps 	 ON 	 pps.PU_Id = e.PU_Id 
 	  	  	  	  	  	  	  	  	  	 AND pps.Start_Time <= e.TimeStamp
 	  	  	  	  	  	  	  	  	  	 AND (pps.End_Time > e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	 OR pps.End_Time Is Null)
 	 LEFT JOIN Production_Plan pp  	    	    	 ON 	 pps.PP_Id = pp.PP_Id 
 	 LEFT JOIN Event_Details ed 	  	  	 ON 	 ed.Event_Id = e.Event_Id
 	 LEFT JOIN Comments c 	  	  	  	 ON 	 e.Comment_Id = c.Comment_Id'
EXECUTE (@SQL + @WhereClause)
--DROP TABLE #Filter
