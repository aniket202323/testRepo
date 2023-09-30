 
 
 
/*
 
spLocal_MPWS__DBUG_ScriptProcedures 350689093, 'spLocal_INT_GHS_ProcessComplyPlusData', NULL
 
*/
 
CREATE PROCEDURE [dbo].[spLocal_MPWS__DBUG_ScriptProcedures_Save] (
	@ObjectID	INT,
	@Name		NVARCHAR(128),
	@SchemaId	INT
)
 
AS 
 
SET NOCOUNT ON;
 
DECLARE 
	@code			VARCHAR(MAX),
	@newLine		CHAR(2) = CHAR(13) + CHAR(10),
	@cr				CHAR(1) = CHAR(10),
	@endofline		INT,
	@createindex	INT,
	@ObjType		VARCHAR(40) = '';
 
--SET @code = OBJECT_DEFINITION(@ObjectID);
 
SELECT @code = m.definition
FROM sys.sql_modules m 
	JOIN sys.objects o ON m.object_id=o.object_id
WHERE name = @Name
 
-- look for CREATE PROCEDURE with multiple spaces between them
IF CHARINDEX('PROCEDURE', @code) - CHARINDEX('CREATE', @code) BETWEEN 6 AND 12 AND CHARINDEX('PROCEDURE', @code) > 1
BEGIN
	SET @createindex = CHARINDEX('CREATE', @code);
	SET @code = STUFF(@code, @createindex, 6, 'ALTER ');
	SET @ObjType = 'PROCEDURE';
END;
 
-- look for CREATE PROCEDURE with multiple spaces between them
IF CHARINDEX('FUNCTION', @code) - CHARINDEX('CREATE', @code) BETWEEN 6 AND 12 AND CHARINDEX('FUNCTION', @code) > 1
BEGIN
	SET @createindex = CHARINDEX('CREATE', @code);
	SET @code = STUFF(@code, @createindex, 6, 'ALTER ');
	SET @ObjType = 'FUNCTION';
END;
	
SET @code = 
    @newLine + @newLine
    + '-- if NOT exists, create dummy SP that will be overwritten with ALTER below.' + @newLine
    + '-- prevents dropping of permissions and similar properties with if exists, DROP/CREATE.' + @newLine
    + 'IF OBJECT_ID(''' + @Name + ''') IS NULL ' + @newLine
    + '	EXEC(''CREATE ' + @ObjType + ' ' + @name + ' AS SET NOCOUNT ON;'')'  + @newLine
    + 'GO' + @newLine + @newLine
    + 'SET ANSI_NULLS ON' + @newLine + 'GO' + @newLine + @newLine 
    + 'SET QUOTED_IDENTIFIER ON' + @newLine + 'GO'+ @newLine + @newLine 
    + @code + @newLine + 'GO' + @newLine 
 
WHILE @code <> ''
BEGIN
 
	SET @endofline = CHARINDEX(@newLine, @code)
	IF @endofline < 8000
	BEGIN
		PRINT LEFT(@code, @endofline - 1);
		SET @code = SUBSTRING(@code, @endofline + 2, LEN(@code));
	END
	ELSE
	BEGIN
		PRINT LEFT(@code, 8000)
		SET @code = SUBSTRING(@code, 8001, LEN(@code))
	END
	
END
 
 
 
