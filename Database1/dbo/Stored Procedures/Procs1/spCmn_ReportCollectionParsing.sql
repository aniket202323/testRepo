-------------------------------------------------------------------------------
-- Desc:
-- This stored procedure parses a string collection.
-- User must specify the field delimitor, the record delimitor and the data types
-- of the fields. The sp will return a table with the parsed data.
--
-- Edit History:
-- RP 05-Jul-2002 MSI Development
-- RP 15-Sep-2003 MSI Mofided code to elimate the use of alter table 	 single column alter tables.
-- RP 04-Oct-2004 MSI Modifed to support 20 parameters
--
-- Example:
/*
SET nocount on
Exec spCmn_ReportCollectionParsing 
@PrmCollectionString = '1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17',
@PrmFieldDelimiter = NULL, 
@PrmRecordDelimiter = '|', 
@PrmDataType01 = 'Int',
@PrmDataType02 = 'VarChar(50)',
@PrmDataType03 = NULL,
@PrmDataType04 = NULL,
@PrmDataType05 = NULL,
@PrmDataType06 = NULL,
@PrmDataType07 = NULL,
@PrmDataType08 = NULL,
@PrmDataType09 = NULL,
@PrmDataType10 = NULL,
@PrmDataType11 = NULL,
@PrmDataType12 = NULL,
@PrmDataType13 = NULL,
@PrmDataType14 = NULL,
@PrmDataType15 = NULL,
@PrmDataType16 = NULL,
@PrmDataType17 = NULL,
@PrmDataType18 = NULL,
@PrmDataType19 = NULL,
@PrmDataType20 = NULL
SET nocount off
*/
--
CREATE  PROCEDURE  dbo.spCmn_ReportCollectionParsing
 	 @PrmCollectionString VarChar(4000) = NULL,
 	 @PrmFieldDelimiter  	 VarChar(1) = NULL, 
 	 @PrmRecordDelimiter  	 VarChar(1) = NULL, 
 	 @PrmDataType01  	  	 VarChar(20) = NULL,
 	 @PrmDataType02  	  	 VarChar(20) = NULL,
 	 @PrmDataType03  	  	 VarChar(20) = NULL,
 	 @PrmDataType04  	  	 VarChar(20) = NULL,
 	 @PrmDataType05  	  	 VarChar(20) = NULL,
 	 @PrmDataType06  	  	 VarChar(20) = NULL,
 	 @PrmDataType07  	  	 VarChar(20) = NULL,
 	 @PrmDataType08  	  	 VarChar(20) = NULL,
 	 @PrmDataType09  	  	 VarChar(20) = NULL,
 	 @PrmDataType10  	  	 VarChar(20) = NULL,
 	 @PrmDataType11  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType12  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType13  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType14  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType15  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType16  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType17  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType18  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType19  	  	 VarChar(20) 	 = NULL,
 	 @PrmDataType20  	  	 VarChar(20) 	 = NULL
AS
DECLARE 	 @i  	  	  	  	 Int,  	 -- Looping variables
 	 @j  	  	  	  	  	  	 Int, 
 	 @k  	  	  	  	  	  	 Int,
 	 @n 	  	  	  	  	  	  	 Int,
 	 @StringLength  	  	  	 Int,  	 -- String parsing variables
   	 @MaxStringLength  	  	 Int,  	 -- String parsing variables
 	 @PartialStringLength  	  	 Int,  	 -- String parsing variables
 	 @RecordDelimiterPosition  	 Int,  	 -- String parsing variables
 	 @FieldDelimiterPosition  	 Int, 	 -- String parsing variables
 	 --
 	 @PartialString 	  	  	 VarChar(200), 	 -- String parsing variables
 	 @SubPartialString 	  	 VarChar(50),
 	 @SQLCommand 	  	  	  	 VarChar(1000),
 	 @SQLCommand1 	  	  	 VarChar(1000),
 	 @SQLCommand2 	  	  	 VarChar(1000),
 	 @DataTypeString 	  	 VarChar(25)
-------------------------------------------------------------------------------
-- Create temporary tables
-------------------------------------------------------------------------------
CREATE TABLE  	 #CollectionItems (
 	  	 RcdId Int)
--
CREATE TABLE 	 #DataType 	 (
 	  	 DataTypeString 	 VarChar(25) )
-------------------------------------------------------------------------------
-- Add fields to #CollectionItems
-------------------------------------------------------------------------------
SELECT 	 @SQLCommand = ''
IF 	 Len(@PrmDataType01) > 0
BEGIN
 	 SELECT 	 @SQLCommand = 'Field01 ' + @PrmDataType01
END
--
IF 	 Len(@PrmDataType02) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field02 ' + @PrmDataType02
END
--
IF 	 Len(@PrmDataType03) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field03 ' + @PrmDataType03
END
--
IF 	 Len(@PrmDataType04) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field04 ' + @PrmDataType04
END
--
IF 	 Len(@PrmDataType05) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field05 ' + @PrmDataType05
END
--
IF 	 Len(@PrmDataType06) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field06 ' + @PrmDataType06
END
--
IF 	 Len(@PrmDataType07) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field07 ' + @PrmDataType07
END
--
IF 	 Len(@PrmDataType08) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field08 ' + @PrmDataType08
END
--
IF 	 Len(@PrmDataType09) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field09 ' + @PrmDataType09
END
--
IF 	 Len(@PrmDataType10) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field10 ' + @PrmDataType10
END
--
IF 	 Len(@PrmDataType11) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field11 ' + @PrmDataType11
END
--
IF 	 Len(@PrmDataType12) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field12 ' + @PrmDataType12
END
--
IF 	 Len(@PrmDataType13) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field13 ' + @PrmDataType13
END
--
IF 	 Len(@PrmDataType14) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field14 ' + @PrmDataType14
END
--
IF 	 Len(@PrmDataType15) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field15 ' + @PrmDataType15
END
--
IF 	 Len(@PrmDataType16) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field16 ' + @PrmDataType16
END
--
IF 	 Len(@PrmDataType17) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field17 ' + @PrmDataType17
END
--
IF 	 Len(@PrmDataType18) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field18 ' + @PrmDataType18
END
--
IF 	 Len(@PrmDataType19) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field19 ' + @PrmDataType19
END
--
IF 	 Len(@PrmDataType20) > 0
BEGIN
 	 SELECT 	 @SQLCommand = @SQLCommand + ', Field20 ' + @PrmDataType20
END
--
SELECT 	 @SQLCommand = 'ALTER TABLE #CollectionItems ADD ' + @SQLCommand -- RP 15-Sep-2003
EXEC 	  	 (@SQLCommand)
-------------------------------------------------------------------------------
-- String parsing routine
-------------------------------------------------------------------------------
SELECT 	 @i = 1
SELECT 	 @j = 1
SELECT 	 @PartialString = ''
SELECT 	 @RecordDelimiterPosition = 0
SELECT 	 @FieldDelimiterPosition = 0
--
IF  	 (Len(@PrmCollectionString) > 0 AND @PrmCollectionString <> '!NULL')
BEGIN
 	 --
 	 IF  	 Len(@PrmRecordDelimiter) > 0  	 -- IF External
 	 BEGIN
 	  	 SELECT 	 @MaxStringLength = Len(@PrmCollectionString)
 	  	 SELECT 	 @i = 1
 	  	 --
 	  	 WHILE 	 @i <= @MaxStringLength -- While loop 1
 	  	 BEGIN
 	  	  	 SELECT  	 @RecordDelimiterPosition = CharIndex(@PrmRecordDelimiter, @PrmCollectionString) -- find the first record delimiter in the string
 	  	  	 IF  	 @RecordDelimiterPosition > 0 -- IF Record Parser
     	  	  	 BEGIN 
       	  	  	  	 SELECT 	 @PartialString = LTrim(RTrim(Substring(@PrmCollectionString, 1, @RecordDelimiterPosition - 1)))
 	  	  	  	 SELECT  	 @k = 1
 	  	  	  	 IF 	 Len(@PrmFieldDelimiter) > 0 -- IF Field Parser 1
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT  	 @n = 1
 	  	  	  	  	 SELECT 	 @PartialStringLength = Len(@PartialString)
 	  	  	  	  	 SELECT 	 @SubPartialString = ''
 	  	  	  	  	 WHILE 	 @k <= @PartialStringLength 	 -- While loop 2
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @FieldDelimiterPosition = CharIndex(@PrmFieldDelimiter, @PartialString)
 	  	  	  	  	  	 SELECT 	 @DataTypeString = Case  	 @n
 	  	  	  	  	  	  	  	  	  	 WHEN 1  	 THEN @PrmDataType01
 	  	  	  	  	  	  	  	  	  	 WHEN 2  	 THEN @PrmDataType02
 	  	  	  	  	  	  	  	  	  	 WHEN 3  	 THEN @PrmDataType03
 	  	  	  	  	  	  	  	  	  	 WHEN 4  	 THEN @PrmDataType04
 	  	  	  	  	  	  	  	  	  	 WHEN 5  	 THEN @PrmDataType05
 	  	  	  	  	  	  	  	  	  	 WHEN 6  	 THEN @PrmDataType06
 	  	  	  	  	  	  	  	  	  	 WHEN 7  	 THEN @PrmDataType07
 	  	  	  	  	  	  	  	  	  	 WHEN 8  	 THEN @PrmDataType08
 	  	  	  	  	  	  	  	  	  	 WHEN 9  	 THEN @PrmDataType09
 	  	  	  	  	  	  	  	  	  	 WHEN 10 	 THEN @PrmDataType10
 	  	  	  	  	  	  	  	  	  	 WHEN 11 	 THEN @PrmDataType11
 	  	  	  	  	  	  	  	  	  	 WHEN 12 	 THEN @PrmDataType12
 	  	  	  	  	  	  	  	  	  	 WHEN 13 	 THEN @PrmDataType13
 	  	  	  	  	  	  	  	  	  	 WHEN 14 	 THEN @PrmDataType14
 	  	  	  	  	  	  	  	  	  	 WHEN 15 	 THEN @PrmDataType15
 	  	  	  	  	  	  	  	  	  	 WHEN 16 	 THEN @PrmDataType16
 	  	  	  	  	  	  	  	  	  	 WHEN 17 	 THEN @PrmDataType17
 	  	  	  	  	  	  	  	  	  	 WHEN 18 	 THEN @PrmDataType18
 	  	  	  	  	  	  	  	  	  	 WHEN 19 	 THEN @PrmDataType19
 	  	  	  	  	  	  	  	  	  	 WHEN 20 	 THEN @PrmDataType20
 	  	  	  	  	  	  	  	  	  	 ELSE  	 'VarChar(50)'
 	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	 -- Check for Null datatype and default to VarChar
 	  	  	  	  	  	 IF 	 Len(@DataTypeString) = 0 	 
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT @DataTypeString = 'VarChar(50)'
 	  	  	  	  	  	 END
 	  	  	  	  	  	 --
 	  	  	  	  	  	 IF 	 @FieldDelimiterPosition > 0
 	  	  	  	  	  	 BEGIN 
 	  	  	  	  	  	  	 SELECT 	 @SubPartialString = LTrim(RTrim(Substring(@PartialString, 1, @FieldDelimiterPosition - 1)))
 	  	  	  	  	  	  	 IF 	 @SubPartialString <> '!NULL' AND @SubPartialString <> 'Blank'
 	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	 IF 	 (SELECT Count(RcdId) FROM #CollectionItems WHERE RcdId = @j) > 0
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 'UPDATE #CollectionItems '
 	  	  	  	  	  	  	  	  	 IF 	 @n < 10
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 	 @SQLCommand1 + 'SET Field0' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 	 @SQLCommand1 + 'SET Field' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 + 'Convert(' + @DataTypeString + ',''' + @SubPartialString + ''')'
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'WHERE RcdId = ' + Convert(VarChar(10), @j)
 	  	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 IF 	 @n < 10
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field0' + Convert(VarChar(10), @n) + ')'
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field' + Convert(VarChar(10), @n) + ')'
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ', ' 
 	  	  	  	  	  	  	  	  	  	  	 +      'Convert(' + @DataTypeString + ',''' + @SubPartialString + '''))'
 	  	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	 END
 	  	  	  	  	  	 ELSE
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT 	 @SubPartialString = LTrim(RTrim(@PartialString))
 	  	  	  	  	  	  	 IF 	 @SubPartialString <> '!NULL' AND @SubPartialString <> 'Blank'
 	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 'UPDATE #CollectionItems '
 	  	  	  	  	  	  	  	 IF 	 @n < 10
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 @SQLCommand1 + 'SET Field0' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 @SQLCommand1 + 'SET Field' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 @SQLCommand1 + 'Convert(' + @DataTypeString + ',''' + @SubPartialString + ''')'
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'WHERE RcdId = ' + Convert(VarChar(10), @j)
 	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	 END
 	  	  	  	  	  	 SELECT @PartialString = Substring(@PartialString, (@FieldDelimiterPosition + 1), Len(@PartialString))
 	  	  	  	  	  	 SELECT 	 @k = @k + Len(@SubPartialString) + 1
 	  	  	  	  	  	 SELECT 	 @n = @n + 1
 	  	  	  	  	 END -- While loop 2 	  	  	 
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 IF 	 @PartialString = '!NULL' OR @PartialString = 'Blank'
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId)'
 	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ')'
 	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	 END
 	  	  	  	  	 ELSE
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field01)'
 	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ', ' 
 	  	  	  	  	  	  	  	 +      'Convert(' + @PrmDataType01 + ',''' + @PartialString + '''))'
 	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	 END
 	  	  	  	 END -- IF Field Parser 1
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @PartialString = LTrim(RTrim(@PrmCollectionString))
 	  	  	  	 IF 	 Len(@PrmFieldDelimiter) > 0 -- Field Parser 2
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 	 @PartialStringLength = Len(@PartialString)
 	  	  	  	  	 SELECT 	 @SubPartialString = ''
 	  	  	  	  	 SELECT 	 @k = 1, @n = 1
 	  	  	  	  	 WHILE 	 @k <= @PartialStringLength -- While loop 3
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @FieldDelimiterPosition = CharIndex(@PrmFieldDelimiter, @PartialString)
 	  	  	  	  	  	 SELECT 	 @DataTypeString = Case  	 @n
 	  	  	  	  	  	  	  	  	  	 WHEN 1  	 THEN @PrmDataType01
 	  	  	  	  	  	  	  	  	  	 WHEN 2  	 THEN @PrmDataType02
 	  	  	  	  	  	  	  	  	  	 WHEN 3  	 THEN @PrmDataType03
 	  	  	  	  	  	  	  	  	  	 WHEN 4  	 THEN @PrmDataType04
 	  	  	  	  	  	  	  	  	  	 WHEN 5  	 THEN @PrmDataType05
 	  	  	  	  	  	  	  	  	  	 WHEN 6  	 THEN @PrmDataType06
 	  	  	  	  	  	  	  	  	  	 WHEN 7  	 THEN @PrmDataType07
 	  	  	  	  	  	  	  	  	  	 WHEN 8  	 THEN @PrmDataType08
 	  	  	  	  	  	  	  	  	  	 WHEN 9  	 THEN @PrmDataType09
 	  	  	  	  	  	  	  	  	  	 WHEN 10 	 THEN @PrmDataType10
 	  	  	  	  	  	  	  	  	  	 WHEN 11 	 THEN @PrmDataType11
 	  	  	  	  	  	  	  	  	  	 WHEN 12 	 THEN @PrmDataType12
 	  	  	  	  	  	  	  	  	  	 WHEN 13 	 THEN @PrmDataType13
 	  	  	  	  	  	  	  	  	  	 WHEN 14 	 THEN @PrmDataType14
 	  	  	  	  	  	  	  	  	  	 WHEN 15 	 THEN @PrmDataType15
 	  	  	  	  	  	  	  	  	  	 WHEN 16 	 THEN @PrmDataType16
 	  	  	  	  	  	  	  	  	  	 WHEN 17 	 THEN @PrmDataType17
 	  	  	  	  	  	  	  	  	  	 WHEN 18 	 THEN @PrmDataType18
 	  	  	  	  	  	  	  	  	  	 WHEN 19 	 THEN @PrmDataType19
 	  	  	  	  	  	  	  	  	  	 WHEN 20 	 THEN @PrmDataType20
 	  	  	  	  	  	  	  	  	  	 ELSE  	 'VarChar(50)'
 	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	 -- Check for Null datatype and default to VarChar
 	  	  	  	  	  	 IF 	 Len(@DataTypeString) = 0 	 
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT @DataTypeString = 'VarChar(50)'
 	  	  	  	  	  	 END
 	  	  	  	  	  	 --
 	  	  	  	  	  	 IF 	 @FieldDelimiterPosition > 0
 	  	  	  	  	  	 BEGIN 
 	  	  	  	  	  	  	 SELECT 	 @SubPartialString = LTrim(RTrim(Substring(@PartialString, 1, @FieldDelimiterPosition - 1))) 	 
 	  	  	  	  	  	  	 IF 	 @SubPartialString <> '!NULL' AND @SubPartialString <> 'Blank'
 	  	  	  	  	  	  	 BEGIN 	  	  	  	 
 	  	  	  	  	  	  	  	 IF 	 (SELECT Count(RcdId) FROM #CollectionItems WHERE RcdId = @j) > 0
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 'UPDATE #CollectionItems '
 	  	  	  	  	  	  	  	  	 IF 	 @n < 10
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 + 'SET Field0' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 + 'SET Field' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 + 'Convert(' + @DataTypeString + ',''' + @SubPartialString + ''')'
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'WHERE RcdId = ' + Convert(VarChar(10), @j)
 	  	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	  	 EXEC 	 (@SQLCommand)
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 IF 	 @n < 10 
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field0' + Convert(VarChar(10), @n) + ')'
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field' + Convert(VarChar(10), @n) + ')'
 	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ', ' 
 	  	  	  	  	  	  	  	  	  	  	 +      'Convert(' + @DataTypeString + ',''' + @SubPartialString + '''))'
 	  	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	  	 EXEC  	 (@SQLCommand)
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	 END
 	  	  	  	  	  	 ELSE
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT 	 @SubPartialString = LTrim(RTrim(@PartialString))
 	  	  	  	  	  	  	 IF 	 @SubPartialString <> '!NULL' AND @SubPartialString <> 'Blank'
 	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 =  	 'UPDATE #CollectionItems '
 	  	  	  	  	  	  	  	 IF 	 @n < 10 
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 +  	 'SET Field0' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 ELSE
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 +  	 'SET Field' + Convert(VarChar(10), @n) + ' = '
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand1 = @SQLCommand1 +  	 'Convert(' + @DataTypeString + ',''' + @SubPartialString + ''')'
 	  	  	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'WHERE RcdId = ' + Convert(VarChar(10), @j)
 	  	  	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	 END
 	  	  	  	  	  	 SELECT @PartialString = Substring(@PartialString, (@FieldDelimiterPosition + 1), Len(@PartialString))
 	  	  	  	  	  	 SELECT 	 @n = @n + 1
 	  	  	  	  	  	 IF 	 @FieldDelimiterPosition > 0
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT 	 @k = @k + @FieldDelimiterPosition
 	  	  	  	  	  	 END
 	  	  	  	  	  	 ELSE
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT 	 @k = @k + Len(@PartialString)
 	  	  	  	  	  	 END
 	  	  	  	  	 END -- While loop 3 	  	  	 
 	  	  	  	 END -- IF loop
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 IF 	 @PartialString = '!NULL' OR @PartialString = 'Blank'
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId)'
 	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ')'
 	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	 END
 	  	  	  	  	 ELSE
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @SQLCommand1 = 'INSERT INTO #CollectionItems (RcdId, Field01)'
 	  	  	  	  	  	 SELECT 	 @SQLCommand2 = 'VALUES (' + Convert(VarChar(10), @j) + ', ' 
 	  	  	  	  	  	  	  	 +      'Convert(' + @PrmDataType01 + ',''' + @PartialString + '''))'
 	  	  	  	  	  	 SELECT  	 @SQLCommand = @SQLCommand1 + ' ' + @SQLCommand2
 	  	  	  	  	  	 EXEC (@SQLCommand)
 	  	  	  	  	 END
 	  	  	  	 END -- IF Field Parser 2
 	  	  	 END -- IF Record parser
 	  	  	 SELECT  	 @PrmCollectionString = Substring(@PrmCollectionString, (@RecordDelimiterPosition + 1), Len(@PrmCollectionString))
   	  	  	 SELECT 	 @j = @j + 1
 	  	  	 --
 	  	  	 IF 	 @RecordDelimiterPosition > 0
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @i = @i + @RecordDelimiterPosition
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @i = @i + Len(@PrmCollectionString)
 	  	  	 END
 	  	 END -- While loop 1
 	 END -- IF External
END
--
-------------------------------------------------------------------------------
-- Return result SELECT
-------------------------------------------------------------------------------
SELECT * FROM #CollectionItems
-------------------------------------------------------------------------------
-- Drop tables
-------------------------------------------------------------------------------
DROP TABLE #CollectionItems
RETURN
GRANT  EXECUTE  ON [dbo].[spCmn_ReportCollectionParsing]  TO [comxclient]
