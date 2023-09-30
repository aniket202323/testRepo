





CREATE PROCEDURE [dbo].[spLocal_PCMT_ParseString]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_ParseString
Author:					Marc Charest (STI)
Date Created:			2009-03-10
SP Type:					
Editor Tab Spacing:	3

Description:
=========
This SP parses a string into records and fields

Called by:  			PCMT stored procedures

Revision Date			Who						What
========	==========	=================== 	=============================================


TESTING:
EXEC spLocal_PCMT_ParseString '1[field]2[field]3[record]4[field]5[field]6', '[field]', '[record]'
*****************************************************************************************************************
*/
@InputString		VARCHAR(8000),
@FieldDelimiter	VARCHAR(25),
@RecordDelimiter	VARCHAR(25),
--For future use --
@DataType01 		VARCHAR(20) = NULL,
@DataType02 		VARCHAR(20) = NULL,
@DataType03 		VARCHAR(20) = NULL,
@DataType04 		VARCHAR(20) = NULL,
@DataType05 		VARCHAR(20) = NULL,
@DataType06 		VARCHAR(20) = NULL,
@DataType07 		VARCHAR(20) = NULL,
@DataType08 		VARCHAR(20) = NULL,
@DataType09 		VARCHAR(20) = NULL,
@DataType10 		VARCHAR(20) = NULL,
@DataType11 		VARCHAR(20) = NULL,
@DataType12 		VARCHAR(20) = NULL,
@DataType13 		VARCHAR(20) = NULL,
@DataType14 		VARCHAR(20) = NULL,
@DataType15 		VARCHAR(20) = NULL,
@DataType16 		VARCHAR(20) = NULL,
@DataType17 		VARCHAR(20) = NULL,
@DataType18 		VARCHAR(20) = NULL,
@DataType19 		VARCHAR(20) = NULL,
@DataType20 		VARCHAR(20) = NULL
--For future use --

AS

DECLARE
@Record				VARCHAR(8000),
@RecordNumber		INTEGER,
@Field				VARCHAR(8000),
@FieldNumber		INTEGER,
@SQLCommand			VARCHAR(8000),
@Zero					VARCHAR(1),
@MaxFieldNumber	INTEGER

DECLARE @Records TABLE(
	Record_Id		INTEGER IDENTITY,
	Record			VARCHAR(8000)
)


CREATE TABLE #FinalRecords(
	RcdId				INTEGER IDENTITY,
	Field01			VARCHAR(8000),
	Field02			VARCHAR(8000),
	Field03			VARCHAR(8000),
	Field04			VARCHAR(8000),
	Field05			VARCHAR(8000),
	Field06			VARCHAR(8000),
	Field07			VARCHAR(8000),
	Field08			VARCHAR(8000),
	Field09			VARCHAR(8000),
	Field10			VARCHAR(8000),
	Field11			VARCHAR(8000),
	Field12			VARCHAR(8000),
	Field13			VARCHAR(8000),
	Field14			VARCHAR(8000),
	Field15			VARCHAR(8000),
	Field16			VARCHAR(8000),
	Field17			VARCHAR(8000),
	Field18			VARCHAR(8000),
	Field19			VARCHAR(8000),
	Field20			VARCHAR(8000)
)


--Parsing records
WHILE CHARINDEX(@RecordDelimiter, @InputString) <> 0 BEGIN
	SELECT @Record = LEFT(@InputString, CHARINDEX(@RecordDelimiter, @InputString) - 1)
	INSERT @Records (Record)
	SELECT @Record
	INSERT #FinalRecords (Field01) VALUES (NULL)
	SET @InputString = SUBSTRING(@InputString, CHARINDEX(@RecordDelimiter, @InputString) + LEN(@RecordDelimiter), 8000)
END
INSERT @Records (Record)
SELECT @InputString
INSERT #FinalRecords (Field01) VALUES (NULL)

--Browsing records
SET @MaxFieldNumber = 0
SET @RecordNumber = 1
WHILE @RecordNumber <= (SELECT COUNT(1) FROM @Records) BEGIN
	SET @Record = (SELECT Record FROM @Records WHERE Record_Id = @RecordNumber)

	--Parsing fields for each record
	SET @FieldNumber = 1
	WHILE CHARINDEX(@FieldDelimiter, @Record) <> 0 BEGIN
		SET @Zero = CASE WHEN @FieldNumber < 10 THEN '0' ELSE '' END
		SELECT @Field = LEFT(@Record, CHARINDEX(@FieldDelimiter, @Record) - 1)
		SET @SQLCommand = 'UPDATE #FinalRecords SET Field' + @Zero + CAST(@FieldNumber AS VARCHAR(2)) + ' = ' + '''' + CASE WHEN @Field = '' THEN NULL ELSE @Field END + '''' + ' WHERE RcdId = ' + CAST(@RecordNumber AS VARCHAR(30))
		EXECUTE (@SQLCommand)
		SET @Record = SUBSTRING(@Record, CHARINDEX(@FieldDelimiter, @Record) + LEN(@FieldDelimiter), 8000)
		SET @FieldNumber = @FieldNumber + 1
	END
	SET @Zero = CASE WHEN @FieldNumber < 10 THEN '0' ELSE '' END
	SET @SQLCommand = 'UPDATE #FinalRecords SET Field' + @Zero + CAST(@FieldNumber AS VARCHAR(2)) + ' = ' + '''' + CASE WHEN @Record = '' THEN NULL ELSE @Record END + '''' + ' WHERE RcdId = ' + CAST(@RecordNumber AS VARCHAR(30))
	EXECUTE (@SQLCommand)

	SET @RecordNumber = @RecordNumber + 1 

	--Keeping trace of the maximum number of fields
	IF @FieldNumber > @MaxFieldNumber BEGIN
		SET @MaxFieldNumber = @FieldNumber
	END

END


--Removing any existing entries if no string supply
IF LEN(@InputString) = 0 OR @InputString IS NULL BEGIN
	DELETE FROM #FinalRecords
END


--Showing result
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 2 BEGIN
	SELECT RcdId, Field01, Field02 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 3 BEGIN
	SELECT RcdId, Field01, Field02, Field03 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 4 BEGIN
	SELECT RcdId, Field01, Field02, Field03, Field04 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 5 BEGIN
	SELECT RcdId, Field01, Field02, Field03, Field04, Field05 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 6 BEGIN
	SELECT RcdId, Field01, Field02, Field03, Field04, Field05, Field06 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END
IF @MaxFieldNumber = 1 BEGIN
	SELECT RcdId, Field01 FROM #FinalRecords
	DROP TABLE #FinalRecords
	RETURN
END





