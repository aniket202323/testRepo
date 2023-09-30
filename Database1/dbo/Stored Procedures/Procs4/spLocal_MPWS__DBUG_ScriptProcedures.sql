
 
 
 
/*
 
execute spLocal_MPWS__DBUG_ScriptProcedures 120139969, 'spLocal_MPWS_DASH_POPipeline', NULL
 
*/
 
CREATE PROCEDURE [dbo].[spLocal_MPWS__DBUG_ScriptProcedures] (
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
	@ObjType		VARCHAR(40) = '',
	@type			varchar(2);
 
--SET @code = OBJECT_DEFINITION(@ObjectID);
 
SELECT 
	@code = m.definition,
	@type = o.type
FROM sys.sql_modules m 
	JOIN sys.objects o ON m.object_id=o.object_id
WHERE name = @Name
 --select @name,@code

IF @type <> 'V'
BEGIN

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
		--select @code
	SET @code = 
		@newLine + @newLine 
		+'-----------------------------------[Register SP Version]-----------------------------------------' + @newLine
	+'SET NOCOUNT ON' + @newLine
	+'DECLARE @SP_Name     NVARCHAR(200),' + @newLine
	+'              @Inputs              INT,' + @newLine
	+'              @Version      NVARCHAR(20),' + @newLine
	+'              @AppId        INT' + @newLine
	+@newLine
	+'SELECT' + @newLine
	+'              @SP_Name      = '''+ @Name + ''',' + @newLine
	+'              @Inputs              = 16,' + @newLine
	+'              @Version      = ''1.0''' + @newLine
	+@newLine
	+'SELECT @AppId = MAX(App_Id) + 1 ' + @newLine
	+'              FROM AppVersions' + @newLine
	+@newLine
	+'-------------------------------------------------------------------------------------------------' + @newLine
	+'--     Update table AppVersions' + @newLine
	+'-------------------------------------------------------------------------------------------------' + @newLine
	+'IF (SELECT COUNT(*) ' + @newLine
	+'              FROM AppVersions ' + @newLine
	+'              WHERE app_name like @SP_Name) > 0' + @newLine
	+'BEGIN' + @newLine
	+'       UPDATE AppVersions ' + @newLine
	+'              SET app_version = @Version' + @newLine
	+'              WHERE app_name like @SP_Name' + @newLine
	+'       SELECT TOP 1 @AppId = App_Id' + @newLine
	+'              FROM AppVersions ' + @newLine
	+'              WHERE app_name like @SP_Name' + @newLine
	+'END' + @newLine
	+'ELSE' + @newLine
	+'BEGIN' + @newLine
	+'       INSERT INTO AppVersions (' + @newLine
	+'              App_Id,' + @newLine
	+'              App_name,' + @newLine
	+'              App_version)' + @newLine
	+'       VALUES (' + @newLine
	+'              @AppId, ' + @newLine
	+'              @SP_Name,' + @newLine
	+'              @Version)' + @newLine
	+'END' + @newLine
	+@newLine
		+ '-- if NOT exists, create dummy SP that will be overwritten with ALTER below.' + @newLine
		+ '-- prevents dropping of permissions and similar properties with if exists, DROP/CREATE.' + @newLine
		+ 'IF OBJECT_ID(''' + @Name + ''') IS NULL ' + @newLine
		+ 'BEGIN' + @newLine
		+ '	EXEC(''CREATE ' + @ObjType + ' ' + @name + ' AS SET NOCOUNT ON;'')'  + @newLine
		+ '	GRANT EXECUTE ON ' + @Name + ' TO ThingWorx' + @newLine
		+ '	GRANT EXECUTE ON ' + @Name + ' TO MPWSHMI' + @newLine
		+ '	GRANT EXECUTE ON ' + @Name + ' TO ComXClient' + @newLine
		+ 'END;' + @newLine
		+ 'GO' + @newLine + @newLine
		+ 'SET ANSI_NULLS ON' + @newLine + 'GO' + @newLine + @newLine 
		+ 'SET QUOTED_IDENTIFIER ON' + @newLine + 'GO'+ @newLine + @newLine 
		+ @code + @newLine + 'GO' + @newLine 

END

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
 
 --select @code
 

